import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'sphere_math.dart';

class SphereShot {
  final String filePath;
  final List<double> quatRelative;

  final double? focal35mm;

  const SphereShot({
    required this.filePath,
    required this.quatRelative,
    this.focal35mm,
  });
}

class StitchResult {
  final Uint8List jpegBytes;

  final double coverage;

  const StitchResult({required this.jpegBytes, required this.coverage});
}

double? readFocal35mm(Uint8List jpeg) {
  try {
    final exif = img.decodeJpgExif(jpeg);
    final f = exif?.exifIfd['FocalLengthIn35mmFilm']?.toInt();
    if (f == null || f < 8 || f > 200) return null;
    return f.toDouble();
  } catch (_) {
    return null;
  }
}

Future<StitchResult> stitchSphereOffline({
  required List<SphereShot> shots,
  int canvasWidth = 2560,
}) {
  final jobs = shots
      .map((s) => _Job(s.filePath, s.quatRelative, s.focal35mm))
      .toList();
  return Isolate.run(() => _stitch(jobs, canvasWidth));
}

class _Job {
  final String path;
  final List<double> quat;
  final double? focal35;
  const _Job(this.path, this.quat, this.focal35);
}

const int _workingLongEdge = 1280;

StitchResult _stitch(List<_Job> jobs, int canvasWidth) {
  final canvasHeight = canvasWidth ~/ 2;
  final pixels = canvasWidth * canvasHeight;
  final acc = Float32List(pixels * 4);

  final cosP = Float64List(canvasHeight), sinP = Float64List(canvasHeight);
  for (var v = 0; v < canvasHeight; v++) {
    final pitch = math.pi / 2 - ((v + 0.5) / canvasHeight) * math.pi;
    cosP[v] = math.cos(pitch);
    sinP[v] = math.sin(pitch);
  }
  final cosY = Float64List(canvasWidth), sinY = Float64List(canvasWidth);
  for (var u = 0; u < canvasWidth; u++) {
    final yaw = ((u + 0.5) / canvasWidth) * 2 * math.pi - math.pi;
    cosY[u] = math.cos(yaw);
    sinY[u] = math.sin(yaw);
  }

  for (final job in jobs) {
    final raw = File(job.path).readAsBytesSync();
    var decoded = img.decodeImage(raw);
    if (decoded == null) continue;
    decoded = img.bakeOrientation(decoded);
    final scale = _workingLongEdge / math.max(decoded.width, decoded.height);
    final frame = (scale < 1
            ? img.copyResize(decoded,
                width: (decoded.width * scale).round(),
                height: (decoded.height * scale).round(),
                interpolation: img.Interpolation.average)
            : decoded)
        .convert(format: img.Format.uint8, numChannels: 3);
    final fw = frame.width;
    final fh = frame.height;
    final rgb = frame.getBytes(order: img.ChannelOrder.rgb);

    final long = math.max(fw, fh).toDouble();
    final tanLong = job.focal35 != null
        ? CameraFov.from35mm(job.focal35!, 1).tanHalfHeight
        : CameraFov.typical.tanHalfHeight;
    final tanX = tanLong * fw / long;
    final tanY = tanLong * fh / long;

    final q = Quat.fromList(job.quat.cast<double>());
    final m = _matrixOf(q.conjugated);

    final span = _frameSpan(q, tanX, tanY, canvasWidth, canvasHeight);

    for (var v = span.top; v <= span.bottom; v++) {
      final cp = cosP[v], sp = sinP[v];
      final row = v * canvasWidth;
      for (var k = 0; k < span.width; k++) {
        final u = (span.left + k) % canvasWidth;
        final dx = cp * sinY[u], dy = sp, dz = -cp * cosY[u];
        final cz = m[6] * dx + m[7] * dy + m[8] * dz;
        if (cz >= -1e-6) continue;
        final depth = -cz;
        final rx = (m[0] * dx + m[1] * dy + m[2] * dz) / depth / tanX;
        if (rx < -1 || rx > 1) continue;
        final ry = (m[3] * dx + m[4] * dy + m[5] * dz) / depth / tanY;
        if (ry < -1 || ry > 1) continue;

        final f = (1 - rx.abs()) * (1 - ry.abs());
        final w = f * f + 1e-6;

        final sx = (rx * 0.5 + 0.5) * (fw - 1);
        final sy = (0.5 - ry * 0.5) * (fh - 1);
        final x0 = sx.floor(), y0 = sy.floor();
        final x1 = x0 + 1 < fw ? x0 + 1 : x0;
        final y1 = y0 + 1 < fh ? y0 + 1 : y0;
        final ax = sx - x0, ay = sy - y0;
        final i00 = (y0 * fw + x0) * 3, i10 = (y0 * fw + x1) * 3;
        final i01 = (y1 * fw + x0) * 3, i11 = (y1 * fw + x1) * 3;
        final w00 = (1 - ax) * (1 - ay), w10 = ax * (1 - ay);
        final w01 = (1 - ax) * ay, w11 = ax * ay;

        final o = (row + u) * 4;
        for (var c = 0; c < 3; c++) {
          acc[o + c] += w *
              (rgb[i00 + c] * w00 +
                  rgb[i10 + c] * w10 +
                  rgb[i01 + c] * w01 +
                  rgb[i11 + c] * w11);
        }
        acc[o + 3] += w;
      }
    }
  }

  final out = Uint8List(pixels * 3);
  final covered = Uint8List(pixels);
  var coveredCount = 0;
  for (var i = 0; i < pixels; i++) {
    final w = acc[i * 4 + 3];
    if (w <= 0) continue;
    covered[i] = 1;
    coveredCount++;
    for (var c = 0; c < 3; c++) {
      out[i * 3 + c] = (acc[i * 4 + c] / w).round().clamp(0, 255);
    }
  }

  fillHoles(out, covered, canvasWidth, canvasHeight);

  final image = img.Image.fromBytes(
    width: canvasWidth,
    height: canvasHeight,
    bytes: out.buffer,
    numChannels: 3,
    order: img.ChannelOrder.rgb,
  );
  final jpg = Uint8List.fromList(img.encodeJpg(image, quality: 90));
  final tagged = injectGpanoXmp(jpg, canvasWidth, canvasHeight);
  return StitchResult(jpegBytes: tagged, coverage: coveredCount / pixels);
}

List<double> _matrixOf(Quat q) {
  final x = q.x, y = q.y, z = q.z, w = q.w;
  return [
    1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w),
    2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w),
    2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y),
  ];
}

class _Span {
  final int left, width, top, bottom;
  const _Span(this.left, this.width, this.top, this.bottom);
}

_Span _frameSpan(Quat q, double tanX, double tanY, int canvasW, int canvasH) {
  ({double yaw, double pitch}) toAngles(List<double> d) {
    final len = math.sqrt(d[0] * d[0] + d[1] * d[1] + d[2] * d[2]);
    return (
      yaw: math.atan2(d[0], -d[2]),
      pitch: math.asin((d[1] / len).clamp(-1.0, 1.0)),
    );
  }

  final centre = toAngles(q.rotate(const [0, 0, -1]));
  var minYaw = 0.0, maxYaw = 0.0;
  var minPitch = centre.pitch, maxPitch = centre.pitch;
  const steps = 16;
  for (var i = 0; i <= steps; i++) {
    final t = -1 + 2 * i / steps;
    for (final c in [
      [t, -1.0],
      [t, 1.0],
      [-1.0, t],
      [1.0, t],
    ]) {
      final a = toAngles(q.rotate([c[0] * tanX, c[1] * tanY, -1.0]));
      var dy = a.yaw - centre.yaw;
      if (dy > math.pi) dy -= 2 * math.pi;
      if (dy < -math.pi) dy += 2 * math.pi;
      minYaw = math.min(minYaw, dy);
      maxYaw = math.max(maxYaw, dy);
      minPitch = math.min(minPitch, a.pitch);
      maxPitch = math.max(maxPitch, a.pitch);
    }
  }

  bool containsPole(double sign) {
    final c = q.conjugated.rotate([0, sign, 0]);
    if (c[2] >= 0) return false;
    return (c[0] / -c[2]).abs() <= tanX && (c[1] / -c[2]).abs() <= tanY;
  }

  final north = containsPole(1), south = containsPole(-1);
  if (north) maxPitch = math.pi / 2;
  if (south) minPitch = -math.pi / 2;

  final top = ((math.pi / 2 - maxPitch) / math.pi * canvasH).floor() - 1;
  final bottom = ((math.pi / 2 - minPitch) / math.pi * canvasH).ceil() + 1;
  int left, width;
  if (north || south || maxYaw - minYaw > 1.9 * math.pi) {
    left = 0;
    width = canvasW;
  } else {
    final uc = (centre.yaw + math.pi) / (2 * math.pi) * canvasW;
    final l = (uc + minYaw / (2 * math.pi) * canvasW).floor() - 1;
    final r = (uc + maxYaw / (2 * math.pi) * canvasW).ceil() + 1;
    left = l % canvasW;
    width = math.min(r - l + 1, canvasW);
  }
  return _Span(left, width, top.clamp(0, canvasH - 1),
      bottom.clamp(0, canvasH - 1));
}

void fillHoles(Uint8List rgb, Uint8List covered, int w, int h) {
  final colHas = List<bool>.filled(w, false);
  for (var u = 0; u < w; u++) {
    var prev = -1;
    for (var v = 0; v < h; v++) {
      if (covered[v * w + u] != 1) continue;
      colHas[u] = true;
      if (v > prev + 1) {
        for (var g = prev + 1; g < v; g++) {
          final t = prev == -1 ? 1.0 : (g - prev) / (v - prev);
          final a = prev == -1 ? v : prev;
          for (var c = 0; c < 3; c++) {
            rgb[(g * w + u) * 3 + c] = (rgb[(a * w + u) * 3 + c] * (1 - t) +
                    rgb[(v * w + u) * 3 + c] * t)
                .round();
          }
        }
      }
      prev = v;
    }
    if (prev >= 0) {
      for (var g = prev + 1; g < h; g++) {
        for (var c = 0; c < 3; c++) {
          rgb[(g * w + u) * 3 + c] = rgb[(prev * w + u) * 3 + c];
        }
      }
    }
  }
  if (!colHas.contains(true)) return;
  for (var u = 0; u < w; u++) {
    if (colHas[u]) continue;
    var src = -1;
    for (var d = 1; d < w && src == -1; d++) {
      if (colHas[(u - d) % w]) {
        src = (u - d) % w;
      } else if (colHas[(u + d) % w]) {
        src = (u + d) % w;
      }
    }
    for (var v = 0; v < h; v++) {
      for (var c = 0; c < 3; c++) {
        rgb[(v * w + u) * 3 + c] = rgb[(v * w + src) * 3 + c];
      }
    }
  }
}

Uint8List injectGpanoXmp(Uint8List jpeg, int width, int height) {
  if (jpeg.length < 4 || jpeg[0] != 0xFF || jpeg[1] != 0xD8) return jpeg;
  final xmp = '<x:xmpmeta xmlns:x="adobe:ns:meta">'
      '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
      '<rdf:Description rdf:about="" xmlns:GPano="http://ns.google.com/photos/1.0/panorama/">'
      '<GPano:UsePanoramaViewer>True</GPano:UsePanoramaViewer>'
      '<GPano:ProjectionType>equirectangular</GPano:ProjectionType>'
      '<GPano:CroppedAreaImageWidthPixels>$width</GPano:CroppedAreaImageWidthPixels>'
      '<GPano:CroppedAreaImageHeightPixels>$height</GPano:CroppedAreaImageHeightPixels>'
      '<GPano:FullPanoWidthPixels>$width</GPano:FullPanoWidthPixels>'
      '<GPano:FullPanoHeightPixels>$height</GPano:FullPanoHeightPixels>'
      '<GPano:CroppedAreaLeftPixels>0</GPano:CroppedAreaLeftPixels>'
      '<GPano:CroppedAreaTopPixels>0</GPano:CroppedAreaTopPixels>'
      '</rdf:Description></rdf:RDF></x:xmpmeta>';
  final header = utf8.encode('http://ns.adobe.com/xap/1.0/\x00');
  final packet = utf8.encode(xmp);
  final segLen = header.length + packet.length + 2;
  final out = Uint8List(2 + 2 + 2 + header.length + packet.length + jpeg.length - 2);
  var o = 0;
  out[o++] = 0xFF;
  out[o++] = 0xD8;
  out[o++] = 0xFF;
  out[o++] = 0xE1;
  out[o++] = (segLen >> 8) & 0xFF;
  out[o++] = segLen & 0xFF;
  out.setRange(o, o + header.length, header);
  o += header.length;
  out.setRange(o, o + packet.length, packet);
  o += packet.length;
  out.setRange(o, o + jpeg.length - 2, jpeg.sublist(2));
  return out;
}
