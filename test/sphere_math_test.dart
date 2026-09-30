import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:itfits/features/capture/engine/sphere_math.dart';
import 'package:itfits/features/capture/engine/sphere_stitcher.dart';

void main() {
  test('lattice is a 12-stop guided tour in capture order', () {
    final lattice = buildSphereLattice();
    expect(lattice.length, 12);
    expect(lattice.where((t) => t.ring == SphereRing.equator).length, 6);
    expect(lattice.where((t) => t.ring == SphereRing.upper).length, 2);
    expect(lattice.where((t) => t.ring == SphereRing.lower).length, 2);
    expect(lattice.where((t) => t.ring == SphereRing.zenith).length, 1);
    expect(lattice.where((t) => t.ring == SphereRing.nadir).length, 1);
    // Equator steps of 60°, tour starts with the full horizon turn.
    final eq = lattice.where((t) => t.ring == SphereRing.equator).toList();
    for (var i = 0; i < 6; i++) {
      expect(eq[i].yawDeg, i * 60.0);
      expect(eq[i].pitchDeg, 0);
    }
    expect(lattice.sublist(0, 6).every((t) => t.ring == SphereRing.equator),
        isTrue);
    final up = lattice.where((t) => t.ring == SphereRing.upper).toList();
    expect(up[0].yawDeg, 90);
    expect(up[0].pitchDeg, 50);
    expect(lattice.firstWhere((t) => t.ring == SphereRing.zenith).pitchDeg, 90);
    expect(lattice.firstWhere((t) => t.ring == SphereRing.nadir).pitchDeg, -90);
    expect(lattice.last.ring, SphereRing.nadir);
  });

  test('identity pose has ~0 error on the first equator target', () {
    final target = buildSphereLattice().first;
    expect(angularDistanceDeg(Quat.identity, target.orientation), lessThan(1e-6));
  });

  test('upper ring target tilts the view direction upward', () {
    final target = buildSphereLattice()
        .firstWhere((t) => t.ring == SphereRing.upper);
    final dir = target.direction;
    expect(dir[1], greaterThan(0.5)); // +Y is up
  });

  test('quaternion round-trip preserves vectors', () {
    final q = (Quat.yaw(0.7) * Quat.pitch(0.3)).normalized;
    final v = q.rotate(const [0, 0, -1]);
    final back = q.conjugated.rotate(v);
    expect((back[0]).abs(), lessThan(1e-9));
    expect((back[1]).abs(), lessThan(1e-9));
    expect(back[2], closeTo(-1, 1e-9));
  });

  test('rotation matrix of identity yields identity quaternion', () {
    final q = Quat.fromRotationMatrix([1, 0, 0, 0, 1, 0, 0, 0, 1]);
    expect(angularDistanceDeg(q, Quat.identity), lessThan(1e-6));
  });

  test('flat device facing north fuses to identity orientation', () {
    // Lying flat, top toward magnetic north: accel opposes gravity (+z),
    // magnetometer points along +y (north).
    final r = rotationMatrixFromSensors(
        [0, 0, 9.81], [0, 25.0, -5.0])!;
    final q = Quat.fromRotationMatrix(r);
    expect(angularDistanceDeg(q, Quat.identity), lessThan(1.0));
  });

  test('fused orientation is not mirrored (top east => right is south)', () {
    // Top toward east: north now lies along device -x.
    final r = rotationMatrixFromSensors(
        [0, 0, 9.81], [-25.0, 0, -5.0])!;
    final q = Quat.fromRotationMatrix(r);
    // Device +x (right edge) must map to world south (0,-1,0)-ish, never north.
    final world = q.rotate(const [1, 0, 0]);
    expect(world[1], lessThan(-0.9));
  });

  test('rotating toward a target strictly reduces alignment error', () {
    final target = buildSphereLattice()
        .firstWhere((t) => t.id == 'eq-1'); // yaw 60°
    double errAt(double yawDeg) {
      const d2r = 3.141592653589793 / 180.0;
      final rel = Quat.yaw(yawDeg * d2r).normalized;
      return angularDistanceDeg(rel, target.orientation);
    }
    expect(errAt(0), closeTo(60, 0.5));
    expect(errAt(20), closeTo(40, 0.5));
    expect(errAt(55), closeTo(5, 0.5));
    expect(errAt(20) < errAt(0), isTrue);
    expect(errAt(55) < errAt(20), isTrue);
  });

  test('sticky target does not flip between two close targets', () {
    final lattice = buildSphereLattice();
    // Pose at yaw 20°: nearest is eq-0 (20° away vs 40° for eq-1 at 60°).
    final pose = Quat.yaw(20 * 3.141592653589793 / 180.0).normalized;
    final first = selectStickyTarget(
        targets: lattice, done: {}, pose: pose, current: null);
    expect(first?.id, 'eq-0');
    // Drift to yaw 35° (eq-1 now nearer at 25°): sticky keeps eq-0.
    final drifted = Quat.yaw(35 * 3.141592653589793 / 180.0).normalized;
    final kept = selectStickyTarget(
        targets: lattice,
        done: {},
        pose: drifted,
        current: first,
        stickRadiusDeg: 40);
    expect(kept?.id, 'eq-0');
    // Captured targets are never re-selected.
    final afterCapture = selectStickyTarget(
        targets: lattice, done: {'eq-0'}, pose: drifted, current: first);
    expect(afterCapture?.id, isNot('eq-0'));
  });

  test('sticky selection returns null when everything is captured', () {
    final lattice = buildSphereLattice();
    final done = lattice.map((t) => t.id).toSet();
    expect(
        selectStickyTarget(
            targets: lattice,
            done: done,
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

  test('zero deltas give identity relative orientation', () {
    final q = relativeQuatFromDeltas(
      yaw: 1.2, yaw0: 1.2, pitch: 0.3, pitch0: 0.3, roll: 0.1, roll0: 0.1);
    expect(angularDistanceDeg(q, Quat.identity), lessThan(1e-6));
  });

  test('pure yaw delta rotates the view by that yaw', () {
    // In dchs_motion_sensors, turning right decreases yaw, so yaw0 > yaw is a right turn (+0.5 rad).
    final q = relativeQuatFromDeltas(
      yaw: 0.0, yaw0: 0.5, pitch: 0.0, pitch0: 0.0, roll: 0.0, roll0: 0.0);
    final fwd = q.rotate(const [0, 0, -1]);
    // Right turn rotates forward (-Z) towards +X (right).
    expect(fwd[0], closeTo(0.4794, 1e-3));
    expect(fwd[1], closeTo(0, 1e-9));
    expect(fwd[2], closeTo(-0.8776, 1e-3));
  });

  test('XMP injection keeps a valid JPEG with an APP1 segment', () {
    final fakeJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);
    final out = injectGpanoXmp(fakeJpeg, 2048, 1024);
    expect(out[0], 0xFF);
    expect(out[1], 0xD8);
    expect(out[2], 0xFF);
    expect(out[3], 0xE1); // APP1
    expect(out[out.length - 2], 0xFF);
    expect(out[out.length - 1], 0xD9); // EOI preserved
  });
}
