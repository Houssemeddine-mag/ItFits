import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'sphere_math.dart';

/// One captured frame with the device pose at shutter time.
///
/// JPEGs live on disk (28 full-res frames must not pile up in RAM);
/// the isolate reads them by path.
class SphereShot {
  final String filePath;
  final List<double> quatRelative;

  const SphereShot({required this.filePath, required this.quatRelative});
}

class StitchResult {
  /// Equirectangular JPEG with GPano XMP metadata.
  final Uint8List jpegBytes;

  /// Fraction of canvas pixels covered by at least one frame.
  final double coverage;

  const StitchResult({required this.jpegBytes, required this.coverage});
}

/// Offline spherical stitcher (§4–§5 and §7 of the guide, adapted).
///
/// Rotation-only model: every frame is warped onto the equirectangular
/// canvas with the IMU pose homography `H = K·R·K⁻¹` (§3) and blended with
/// edge feathering. The heavy loop runs in an isolate; full-res frames are
/// downscaled to working resolution first (§1.2, memory discipline).
Future<StitchResult> stitchSphereOffline({
  required List<SphereShot> shots,
  double hfovDeg = 70,
  int canvasWidth = 2048,
}) {
  return Isolate.run(() => _stitch(shots
      .map((s) => {
            'path': s.filePath,
            'quat': s.quatRelative,
          })
      .toList(), hfovDeg, canvasWidth));
}

StitchResult _stitch(
    List<Map<String, Object>> shots, double hfovDeg, int canvasWidth) {
  final canvasHeight = canvasWidth ~/ 2;
  final pixels = canvasWidth * canvasHeight;
  final accR = Float32List(pixels);
  final accG = Float32List(pixels);
  final accB = Float32List(pixels);
  final accW = Float32List(pixels);

  const d2r = math.pi / 180.0;
  final tanH = math.tan(hfovDeg * d2r / 2);

  for (final shot in shots) {
    final raw = File(shot['path']! as String).readAsBytesSync();
    final decoded = img.decodeImage(raw);
    if (decoded == null) continue;
    // Working resolution: bound time & RAM (§1.2).
    final scale = 1024 / math.max(decoded.width, decoded.height);
    final frame = scale < 1
        ? img.copyResize(decoded,
            width: (decoded.width * scale).round(),
            height: (decoded.height * scale).round(),
            interpolation: img.Interpolation.linear)
        : decoded;
    final fw = frame.width;
    final fh = frame.height;
    final tanV = tanH * fh / fw;

    final q = Quat.fromList((shot['quat']! as List).cast<double>());
    final qInv = q.conjugated;

    final bounds = _photoBounds(q, tanH, tanV, canvasWidth, canvasHeight);

    for (var v = bounds.top; v <= bounds.bottom; v++) {
      final pitch = math.pi / 2 - (v / canvasHeight) * math.pi;
      final cosP = math.cos(pitch);
      final sinP = math.sin(pitch);
      for (var u = bounds.left; u <= bounds.right; u++) {
        final uu = u % canvasWidth;
        final yaw = (uu / canvasWidth) * 2 * math.pi - math.pi;
        final dir = [
          cosP * math.sin(yaw),
          sinP,
          -cosP * math.cos(yaw),
        ];
        // Feather weight by normalized image radius (1 = soft edge).
        final cam = qInv.rotate(dir);
        final depth = -cam[2];
        if (depth <= 1e-6) continue;
        final xn = cam[0] / depth;
        final yn = cam[1] / depth;
        final rx = xn / tanH;
        final ry = yn / tanV;
        if (rx < -1 || rx > 1 || ry < -1 || ry > 1) continue;
        final rn = math.sqrt(rx * rx + ry * ry);
        final w = math.pow((1.12 - rn).clamp(0.0, 1.0), 1.5).toDouble();
        if (w <= 0) continue;

        final sx = (rx * 0.5 + 0.5) * (fw - 1);
        final sy = (ry * 0.5 + 0.5) * (fh - 1);
        final px = _bilinear(frame, sx, sy);

        final idx = v * canvasWidth + uu;
        accR[idx] += px[0] * w;
        accG[idx] += px[1] * w;
        accB[idx] += px[2] * w;
        accW[idx] += w;
      }
    }
  }

  final out = img.Image(width: canvasWidth, height: canvasHeight);
  var covered = 0;
  for (var i = 0; i < pixels; i++) {
    final w = accW[i];
    if (w > 1e-6) {
      covered++;
      out.setPixelRgba(
        i % canvasWidth,
        i ~/ canvasWidth,
        (accR[i] / w).round().clamp(0, 255),
        (accG[i] / w).round().clamp(0, 255),
        (accB[i] / w).round().clamp(0, 255),
        255,
      );
    }
  }

  final jpg = Uint8List.fromList(img.encodeJpg(out, quality: 90));
  final tagged = injectGpanoXmp(jpg, canvasWidth, canvasHeight);
  return StitchResult(
    jpegBytes: tagged,
    coverage: covered / pixels,
  );
}

class _Bounds {
  final int left, right, top, bottom;
  const _Bounds(this.left, this.right, this.top, this.bottom);
}

/// Canvas span covered by one frame (corners through pose homography).
_Bounds _photoBounds(
    Quat q, double tanH, double tanV, int canvasW, int canvasH) {
  var minU = canvasW.toDouble();
  var maxU = -1.0;
  var minV = canvasH.toDouble();
  var maxV = -1.0;
  for (final c in [
    [-1.0, -1.0],
    [1.0, -1.0],
    [-1.0, 1.0],
    [1.0, 1.0],
  ]) {
    final dir = q.rotate([c[0] * tanH, c[1] * tanV, -1.0]);
    final len =
        math.sqrt(dir[0] * dir[0] + dir[1] * dir[1] + dir[2] * dir[2]);
    final yaw = math.atan2(dir[0] / len, -dir[2] / len);
    final pitch = math.asin((dir[1] / len).clamp(-1.0, 1.0));
    final u = (yaw + math.pi) / (2 * math.pi) * canvasW;
    final v = (math.pi / 2 - pitch) / math.pi * canvasH;
    if (u < minU) minU = u;
    if (u > maxU) maxU = u;
    if (v < minV) minV = v;
    if (v > maxV) maxV = v;
  }
  var left = (minU - 2).floor();
  var right = (maxU + 2).ceil();
  // Antimeridian wrap: fall back to full width.
  if (maxU - minU > canvasW * 0.7) {
    left = 0;
    right = canvasW - 1;
  }
  return _Bounds(
    left.clamp(0, canvasW - 1),
    right.clamp(0, canvasW - 1),
    (minV - 2).floor().clamp(0, canvasH - 1),
    (maxV + 2).ceil().clamp(0, canvasH - 1),
  );
}

List<double> _bilinear(img.Image frame, double x, double y) {
  final x0 = x.floor().clamp(0, frame.width - 1);
  final y0 = y.floor().clamp(0, frame.height - 1);
  final x1 = (x0 + 1).clamp(0, frame.width - 1);
  final y1 = (y0 + 1).clamp(0, frame.height - 1);
  final fx = (x - x0).clamp(0.0, 1.0);
  final fy = (y - y0).clamp(0.0, 1.0);
  final p00 = frame.getPixel(x0, y0);
  final p10 = frame.getPixel(x1, y0);
  final p01 = frame.getPixel(x0, y1);
  final p11 = frame.getPixel(x1, y1);
  double mix(num a, num b, num c, num d) =>
      (a * (1 - fx) * (1 - fy) +
              b * fx * (1 - fy) +
              c * (1 - fx) * fy +
              d * fx * fy)
          .toDouble();
  return [
    mix(p00.r, p10.r, p01.r, p11.r),
    mix(p00.g, p10.g, p01.g, p11.g),
    mix(p00.b, p10.b, p01.b, p11.b),
  ];
}

/// Injects the GPano XMP block (§7) as an APP1 segment right after SOI so
/// galleries and VR viewers recognize the output as a 360 photo sphere.
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
