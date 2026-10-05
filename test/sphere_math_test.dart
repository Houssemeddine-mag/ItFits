import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:itfits/features/capture/engine/sphere_math.dart';
import 'package:itfits/features/capture/engine/sphere_stitcher.dart';

const d2r = math.pi / 180.0;

List<double> pluginEuler(List<double> r) {
  double f32(double v) => (Float32List(1)..[0] = v)[0];
  final az = math.atan2(r[1], r[4]);
  final pitch = math.asin((-r[7]).clamp(-1.0, 1.0));
  final roll = math.atan2(-r[6], r[8]);
  return [f32(-az), f32(-pitch), f32(roll)];
}

List<double> portraitPose(double headingDeg,
    [double elevationDeg = 0, double rollDeg = 0]) {
  final h = headingDeg * d2r, e = elevationDeg * d2r, k = rollDeg * d2r;
  final fwd = [math.sin(h) * math.cos(e), math.cos(h) * math.cos(e), math.sin(e)];
  final right0 = [math.cos(h), -math.sin(h), 0.0];
  final up0 = [
    -math.sin(h) * math.sin(e),
    -math.cos(h) * math.sin(e),
    math.cos(e),
  ];
  final right = List.generate(3, (i) => math.cos(k) * right0[i] + math.sin(k) * up0[i]);
  final up = List.generate(3, (i) => -math.sin(k) * right0[i] + math.cos(k) * up0[i]);
  return [
    right[0], up[0], -fwd[0],
    right[1], up[1], -fwd[1],
    right[2], up[2], -fwd[2],
  ];
}

Quat poseFromPlugin(LevelFrame frame, List<double> r) {
  final e = pluginEuler(r);
  return frame.relativePose(deviceToWorldFromEuler(e[0], e[1], e[2]));
}

void main() {
  group('lattice', () {
    test('is a 22-stop guided tour in capture order', () {
      final lattice = buildSphereLattice();
      expect(lattice.length, 22);
      int count(SphereRing r) => lattice.where((t) => t.ring == r).length;
      expect(count(SphereRing.equator), 8);
      expect(count(SphereRing.upper), 6);
      expect(count(SphereRing.lower), 6);
      expect(count(SphereRing.zenith), 1);
      expect(count(SphereRing.nadir), 1);
      expect(lattice.sublist(0, 8).every((t) => t.ring == SphereRing.equator),
          isTrue);
      expect(lattice.last.ring, SphereRing.nadir);
      expect(lattice.map((t) => t.id).toSet().length, 22);
    });

    test('covers the whole sphere with a typical lens and 3° aim error', () {
      final lattice = buildSphereLattice();
      final fov = CameraFov.typical;
      final ex = math.tan(math.atan(fov.tanHalfWidth) - 3 * d2r);
      final ey = math.tan(math.atan(fov.tanHalfHeight) - 3 * d2r);
      var missed = 0.0, total = 0.0;
      for (var v = 0; v < 90; v++) {
        for (var u = 0; u < 180; u++) {
          final p = (90 - (v + 0.5) * 2) * d2r, y = ((u + 0.5) * 2 - 180) * d2r;
          final d = [math.cos(p) * math.sin(y), math.sin(p), -math.cos(p) * math.cos(y)];
          final w = math.cos(p);
          total += w;
          final hit = lattice.any((t) {
            final c = t.orientation.conjugated.rotate(d);
            if (c[2] >= 0) return false;
            return (c[0] / -c[2]).abs() <= ex && (c[1] / -c[2]).abs() <= ey;
          });
          if (!hit) missed += w;
        }
      }
      expect(1 - missed / total, greaterThan(0.99));
    });

    test('upper ring target tilts the view direction upward', () {
      final target =
          buildSphereLattice().firstWhere((t) => t.ring == SphereRing.upper);
      expect(target.direction[1], greaterThan(0.6));
    });
  });

  group('quaternions', () {
    test('round-trip preserves vectors', () {
      final q = (Quat.yaw(0.7) * Quat.pitch(0.3)).normalized;
      final v = q.rotate(const [0, 0, -1]);
      final back = q.conjugated.rotate(v);
      expect(back[0].abs(), lessThan(1e-9));
      expect(back[1].abs(), lessThan(1e-9));
      expect(back[2], closeTo(-1, 1e-9));
    });

    test('identity rotation matrix yields identity quaternion', () {
      final q = Quat.fromRotationMatrix([1, 0, 0, 0, 1, 0, 0, 0, 1]);
      expect(angularDistanceDeg(q, Quat.identity), lessThan(1e-6));
    });

    test('fused accel/mag orientation is not mirrored', () {
      final r = rotationMatrixFromSensors([0, 0, 9.81], [-25.0, 0, -5.0])!;
      final world = Quat.fromRotationMatrix(r).rotate(const [1, 0, 0]);
      expect(world[1], lessThan(-0.9));
    });
  });

  group('device pose', () {
    test('Euler rebuild inverts the plugin decomposition', () {
      final rnd = math.Random(7);
      for (var i = 0; i < 200; i++) {
        final r = portraitPose(rnd.nextDouble() * 360,
            rnd.nextDouble() * 170 - 85, rnd.nextDouble() * 60 - 30);
        final e = pluginEuler(r);
        final back = deviceToWorldFromEuler(e[0], e[1], e[2]);
        for (var k = 0; k < 9; k++) {
          expect(back[k], closeTo(r[k], 1e-5), reason: 'sample $i, m[$k]');
        }
      }
    });

    test('start pose maps to identity in the level frame', () {
      final r0 = portraitPose(123, 0.4, 0.3);
      final frame = LevelFrame.fromStartPose(r0);
      expect(viewAngleDeg(poseFromPlugin(frame, r0), buildSphereLattice()[0]),
          lessThan(1));
    });

    test('upright portrait turns are tracked at the gimbal-lock pose', () {
      final frame = LevelFrame.fromStartPose(portraitPose(10, 0.3, -0.2));
      for (final turn in [45.0, 90.0, 135.0, 180.0, 270.0, 315.0]) {
        final q = poseFromPlugin(frame, portraitPose(10 + turn, 0.3, 0.2));
        final f = q.rotate(const [0, 0, -1]);
        final yaw = math.atan2(f[0], -f[2]) / d2r;
        expect(wrapAngleDeg(yaw - turn).abs(), lessThan(0.5),
            reason: 'turn $turn');
        expect(f[1].abs(), lessThan(0.01));
        final target = buildSphereLattice()
            .firstWhere((t) => t.ring == SphereRing.equator &&
                wrapAngleDeg(t.yawDeg - turn).abs() < 1e-9,
                orElse: () => buildSphereLattice()[0]);
        if (wrapAngleDeg(target.yawDeg - turn).abs() < 1e-9) {
          expect(viewAngleDeg(q, target), lessThan(0.5));
        }
      }
    });

    test('tilted start still yields a level horizon frame', () {
      final frame = LevelFrame.fromStartPose(portraitPose(0, -25, 8));
      final level = poseFromPlugin(frame, portraitPose(0, 0.3, 0.2));
      final f = level.rotate(const [0, 0, -1]);
      expect(f[1].abs(), lessThan(0.01));
      final up = poseFromPlugin(frame, portraitPose(30, 45));
      final target = buildSphereLattice().firstWhere((t) => t.id == 'up-0');
      expect(viewAngleDeg(up, target), closeTo(7.5 * math.cos(45 * d2r), 1.0));
    });

    test('starting while pointing at the floor still picks a heading', () {
      final frame = LevelFrame.fromStartPose(portraitPose(60, -89.5));
      final q = poseFromPlugin(frame, portraitPose(60, 0.3, 0.2));
      final f = q.rotate(const [0, 0, -1]);
      expect(f[2], lessThan(-0.99));
    });
  });

  group('aim', () {
    test('view angle ignores roll, so the zenith works from any heading', () {
      final zenith =
          buildSphereLattice().firstWhere((t) => t.ring == SphereRing.zenith);
      for (final heading in [0.0, 90.0, 200.0]) {
        final frame = LevelFrame.fromStartPose(portraitPose(0));
        final q = poseFromPlugin(frame, portraitPose(heading, 89.9));
        expect(viewAngleDeg(q, zenith), lessThan(0.5));
      }
    });

    test('rotating toward a target reduces the error', () {
      final target = buildSphereLattice().firstWhere((t) => t.id == 'eq-1');
      double errAt(double yaw) => viewAngleDeg(Quat.yaw(yaw * d2r), target);
      expect(errAt(0), closeTo(45, 0.01));
      expect(errAt(20), closeTo(25, 0.01));
      expect(errAt(44), closeTo(1, 0.01));
    });

    test('sticky target does not flip between two close targets', () {
      final lattice = buildSphereLattice();
      final pose = Quat.yaw(15 * d2r);
      final first = selectStickyTarget(
          targets: lattice, done: {}, pose: pose, current: null);
      expect(first?.id, 'eq-0');
      final drifted = Quat.yaw(28 * d2r);
      expect(
          selectStickyTarget(
                  targets: lattice,
                  done: {},
                  pose: drifted,
                  current: first,
                  stickRadiusDeg: 30)
              ?.id,
          'eq-0');
      expect(
          selectStickyTarget(
                  targets: lattice, done: {'eq-0'}, pose: drifted, current: first)
              ?.id,
          'eq-1');
    });

    test('sticky selection returns null when everything is captured', () {
      final lattice = buildSphereLattice();
      expect(
          selectStickyTarget(
              targets: lattice,
              done: lattice.map((t) => t.id).toSet(),
              pose: Quat.identity,
              current: null),
          isNull);
    });

    test('wrapAngleDeg folds to [-180, 180)', () {
      expect(wrapAngleDeg(0), 0);
      expect(wrapAngleDeg(350), closeTo(-10, 1e-9));
      expect(wrapAngleDeg(-190), closeTo(170, 1e-9));
      expect(wrapAngleDeg(720 + 45), closeTo(45, 1e-9));
    });
  });

  group('camera FOV', () {
    test('26 mm equivalent on 4:3 is about 53° × 67° in portrait', () {
      final fov = CameraFov.from35mm(26, 4 / 3);
      expect(fov.horizontalDeg, closeTo(53.1, 0.5));
      expect(fov.verticalDeg, closeTo(67.3, 0.5));
    });

    test('reads FocalLengthIn35mmFilm from EXIF', () {
      final image = img.Image(width: 8, height: 8);
      image.exif.exifIfd['FocalLengthIn35mmFilm'] = img.IfdValueShort(24);
      final jpg = Uint8List.fromList(img.encodeJpg(image));
      expect(readFocal35mm(jpg), 24);
      expect(readFocal35mm(Uint8List.fromList(
          img.encodeJpg(img.Image(width: 8, height: 8)))), isNull);
    });
  });

  group('stitcher', () {
    test('fillHoles closes caps, gaps and empty columns', () {
      const w = 4, h = 5;
      final rgb = Uint8List(w * h * 3);
      final cov = Uint8List(w * h);
      void set(int u, int v, int value) {
        cov[v * w + u] = 1;
        for (var c = 0; c < 3; c++) {
          rgb[(v * w + u) * 3 + c] = value;
        }
      }

      set(0, 1, 100);
      set(0, 3, 200);
      set(2, 2, 50);
      fillHoles(rgb, cov, w, h);
      int at(int u, int v) => rgb[(v * w + u) * 3];
      expect(at(0, 0), 100);
      expect(at(0, 2), 150);
      expect(at(0, 4), 200);
      expect(at(1, 2), anyOf(150, 50));
      expect(at(3, 0), anyOf(50, 100));
    });

    test('XMP injection keeps a valid JPEG with an APP1 segment', () {
      final out = injectGpanoXmp(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]), 2048, 1024);
      expect(out.sublist(0, 4), [0xFF, 0xD8, 0xFF, 0xE1]);
      expect(out.sublist(out.length - 2), [0xFF, 0xD9]);
    });

    test('reconstructs a synthetic room from frames at the lattice poses',
        () async {
      List<int> scene(List<double> d) {
        final yaw = math.atan2(d[0], -d[2]);
        final pitch = math.asin(d[1].clamp(-1.0, 1.0));
        final r = 128 + 100 * math.sin(yaw);
        final g = 128 + 100 * math.cos(yaw);
        final b = 128 + 120 * pitch / (math.pi / 2);
        return [r.round(), g.round(), b.round()];
      }

      final dir = await Directory.systemTemp.createTemp('stitch_test');
      addTearDown(() => dir.delete(recursive: true));
      final fov = CameraFov.typical;
      const fw = 240, fh = 320;
      final shots = <SphereShot>[];
      for (final t in buildSphereLattice()) {
        final q = (t.orientation * Quat(0, 0, math.sin(0.05), math.cos(0.05)))
            .normalized;
        final frame = img.Image(width: fw, height: fh);
        for (var y = 0; y < fh; y++) {
          for (var x = 0; x < fw; x++) {
            final cx = (x / (fw - 1) * 2 - 1) * fov.tanHalfWidth;
            final cy = (1 - y / (fh - 1) * 2) * fov.tanHalfHeight;
            final d = q.rotate([cx, cy, -1]);
            final n = math.sqrt(d[0] * d[0] + d[1] * d[1] + d[2] * d[2]);
            final c = scene([d[0] / n, d[1] / n, d[2] / n]);
            frame.setPixelRgb(x, y, c[0], c[1], c[2]);
          }
        }
        final path = '${dir.path}/${t.id}.jpg';
        File(path).writeAsBytesSync(img.encodeJpg(frame, quality: 95));
        shots.add(SphereShot(filePath: path, quatRelative: q.toList()));
      }

      final result = await stitchSphereOffline(shots: shots, canvasWidth: 512);
      expect(result.coverage, greaterThan(0.995));

      final pano = img.decodeJpg(result.jpegBytes)!;
      expect(pano.width, 512);
      expect(pano.height, 256);
      var err = 0.0, n = 0;
      for (var v = 4; v < pano.height - 4; v += 3) {
        for (var u = 0; u < pano.width; u += 3) {
          final p = math.pi / 2 - (v + 0.5) / pano.height * math.pi;
          final y = (u + 0.5) / pano.width * 2 * math.pi - math.pi;
          final c = scene([
            math.cos(p) * math.sin(y),
            math.sin(p),
            -math.cos(p) * math.cos(y),
          ]);
          final px = pano.getPixel(u, v);
          err += (px.r - c[0]).abs() + (px.g - c[1]).abs() + (px.b - c[2]).abs();
          n += 3;
        }
      }
      expect(err / n, lessThan(6), reason: 'mean abs error per channel');
    });
  });
}
