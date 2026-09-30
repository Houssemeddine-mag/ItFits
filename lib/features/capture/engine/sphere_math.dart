import 'dart:math' as math;

/// Pure-Dart math core of the offline 360 photo-sphere engine.
///
/// Conventions (right-handed, Y-up start frame):
/// * A [Quat] maps vectors from the CURRENT device frame into the START frame
///   (the device pose when the capture session began, identity = start).
/// * The camera looks along -Z in device space; "up" is +Y.
/// * A [SphereTarget] with yaw/pitch offsets defines a target orientation
///   `qTarget = qYaw(yaw) * qPitch(pitch)` in the start frame.
/// * Capture error = angular distance between current pose and target pose.
class Quat {
  final double x, y, z, w;
  const Quat(this.x, this.y, this.z, this.w);

  static const identity = Quat(0, 0, 0, 1);

  /// Rotation of [angleRad] about the Y axis (yaw).
  /// Right-turning / clockwise: +yaw moves the camera forward (-Z) towards +X (right).
  factory Quat.yaw(double angleRad) {
    final h = -angleRad / 2;
    return Quat(0, math.sin(h), 0, math.cos(h));
  }

  /// Rotation of [angleRad] about the X axis (pitch, +up).
  factory Quat.pitch(double angleRad) {
    final h = angleRad / 2;
    return Quat(math.sin(h), 0, 0, math.cos(h));
  }

  /// Hamilton product: apply [other] first, then this.
  Quat operator *(Quat other) => Quat(
        w * other.x + x * other.w + y * other.z - z * other.y,
        w * other.y - x * other.z + y * other.w + z * other.x,
        w * other.z + x * other.y - y * other.x + z * other.w,
        w * other.w - x * other.x - y * other.y - z * other.z,
      );

  Quat get conjugated => Quat(-x, -y, -z, w);

  Quat get normalized {
    final n = math.sqrt(x * x + y * y + z * z + w * w);
    if (n < 1e-12) return Quat.identity;
    return Quat(x / n, y / n, z / n, w / n);
  }

  double dot(Quat other) => x * other.x + y * other.y + z * other.z + w * other.w;

  /// Rotates vector [v] ([x, y, z]) by this quaternion.
  List<double> rotate(List<double> v) {
    final qv = Quat(v[0], v[1], v[2], 0);
    final r = this * qv * conjugated;
    return [r.x, r.y, r.z];
  }

  /// Builds a quaternion from a row-major 3x3 rotation matrix.
  factory Quat.fromRotationMatrix(List<double> m) {
    final trace = m[0] + m[4] + m[8];
    double x, y, z, w;
    if (trace > 0) {
      final s = 0.5 / math.sqrt(trace + 1.0);
      w = 0.25 / s;
      x = (m[7] - m[5]) * s;
      y = (m[2] - m[6]) * s;
      z = (m[3] - m[1]) * s;
    } else if (m[0] > m[4] && m[0] > m[8]) {
      final s = 2.0 * math.sqrt(1.0 + m[0] - m[4] - m[8]);
      w = (m[7] - m[5]) / s;
      x = 0.25 * s;
      y = (m[1] + m[3]) / s;
      z = (m[2] + m[6]) / s;
    } else if (m[4] > m[8]) {
      final s = 2.0 * math.sqrt(1.0 + m[4] - m[0] - m[8]);
      w = (m[2] - m[6]) / s;
      x = (m[1] + m[3]) / s;
      y = 0.25 * s;
      z = (m[5] + m[7]) / s;
    } else {
      final s = 2.0 * math.sqrt(1.0 + m[8] - m[0] - m[4]);
      w = (m[3] - m[1]) / s;
      x = (m[2] + m[6]) / s;
      y = (m[5] + m[7]) / s;
      z = 0.25 * s;
    }
    return Quat(x, y, z, w).normalized;
  }

  List<double> toList() => [x, y, z, w];

  factory Quat.fromList(List<double> l) =>
      Quat(l[0], l[1], l[2], l[3]).normalized;
}

/// Angular distance in degrees between two orientations.
double angularDistanceDeg(Quat a, Quat b) {
  final d = a.normalized.dot(b.normalized).abs().clamp(-1.0, 1.0);
  return 2.0 * math.acos(d) * 180.0 / math.pi;
}

enum SphereRing { equator, upper, lower, zenith, nadir }

/// One acquisition target on the virtual sphere (§2 of the guide).
class SphereTarget {
  final String id;
  final double yawDeg;
  final double pitchDeg;
  final SphereRing ring;

  const SphereTarget({
    required this.id,
    required this.yawDeg,
    required this.pitchDeg,
    required this.ring,
  });

  /// Target orientation in the start frame.
  Quat get orientation {
    const d2r = math.pi / 180.0;
    return (Quat.yaw(yawDeg * d2r) * Quat.pitch(pitchDeg * d2r)).normalized;
  }

  /// Target view direction in the start frame.
  List<double> get direction =>
      orientation.rotate(const [0, 0, -1]);
}

/// Builds the capture lattice: a 12-frame guided tour derived from §2 of
/// the guide. Listed in capture order so the UI can walk the user through
/// one target at a time: full turn around the horizon, then upper, lower,
/// zenith and nadir.
/// 6 equator (60° steps) + 2 upper (+50°) + 2 lower (−50°) + zenith + nadir.
/// With a ~70° lens this still closes the sphere with healthy overlap.
List<SphereTarget> buildSphereLattice() {
  final targets = <SphereTarget>[];
  for (var i = 0; i < 6; i++) {
    targets.add(SphereTarget(
      id: 'eq-$i',
      yawDeg: i * 60.0,
      pitchDeg: 0,
      ring: SphereRing.equator,
    ));
  }
  for (var i = 0; i < 2; i++) {
    targets.add(SphereTarget(
      id: 'up-$i',
      yawDeg: 90.0 + i * 180.0,
      pitchDeg: 50,
      ring: SphereRing.upper,
    ));
  }
  for (var i = 0; i < 2; i++) {
    targets.add(SphereTarget(
      id: 'lo-$i',
      yawDeg: i * 180.0,
      pitchDeg: -50,
      ring: SphereRing.lower,
    ));
  }
  targets.add(const SphereTarget(
      id: 'zenith', yawDeg: 0, pitchDeg: 90, ring: SphereRing.zenith));
  targets.add(const SphereTarget(
      id: 'nadir', yawDeg: 0, pitchDeg: -90, ring: SphereRing.nadir));
  return targets;
}

/// Wraps degrees to [-180, 180).
double wrapAngleDeg(double deg) {
  var d = deg % 360.0;
  if (d >= 180.0) d -= 360.0;
  if (d < -180.0) d += 360.0;
  return d;
}

/// Picks the active capture target with stickiness (hysteresis).
///
/// Returns [current] while it stays open and within [stickRadiusDeg] of the
/// pose, so the guide never jumps between targets mid-aim. Otherwise falls
/// back to the nearest open target, or null when everything is captured.
SphereTarget? selectStickyTarget({
  required List<SphereTarget> targets,
  required Set<String> done,
  required Quat pose,
  required SphereTarget? current,
  double stickRadiusDeg = 20.0,
}) {
  if (current != null &&
      !done.contains(current.id) &&
      targets.any((t) => t.id == current.id) &&
      angularDistanceDeg(pose, current.orientation) <= stickRadiusDeg) {
    return current;
  }
  SphereTarget? best;
  var bestErr = double.infinity;
  for (final t in targets) {
    if (done.contains(t.id)) continue;
    final err = angularDistanceDeg(pose, t.orientation);
    if (err < bestErr) {
      bestErr = err;
      best = t;
    }
  }
  return best;
}

/// Relative orientation from fused yaw/pitch/roll deltas (radians).
///
/// Used with gyro-fused rotation-vector sensors: yaw/pitch/roll are sampled
/// at session start (yaw0/pitch0/roll0) and every delta is measured from
/// there, so no magnetometer — and none of its indoor jumpiness — is
/// involved. Same yaw→pitch→roll composition order as [SphereTarget].
Quat relativeQuatFromDeltas({
  required double yaw,
  required double yaw0,
  required double pitch,
  required double pitch0,
  required double roll,
  required double roll0,
}) {
  // In dchs_motion_sensors on Android, yaw decreases as device rotates clockwise (to the right).
  // Negating (yaw - yaw0) makes right turns positive, matching SphereTarget's clockwise tour.
  final dy = wrapAngleDeg((yaw0 - yaw) * 180.0 / math.pi) * math.pi / 180.0;
  final dp = (pitch - pitch0);
  final dr = (roll - roll0);
  return (Quat.yaw(dy) * Quat.pitch(dp) * _rollQuat(dr)).normalized;
}

Quat _rollQuat(double angleRad) {
  final h = angleRad / 2;
  return Quat(0, 0, math.sin(h), math.cos(h));
}

/// Android SensorManager.getRotationMatrix() port.
/// [gravity] and [geomagnetic] are raw sensor vectors (device frame).
/// Returns row-major 3x3 (world→device), or null if unsolvable.
List<double>? rotationMatrixFromSensors(
    List<double> gravity, List<double> geomagnetic) {
  final ax = gravity[0], ay = gravity[1], az = gravity[2];
  final ex = geomagnetic[0], ey = geomagnetic[1], ez = geomagnetic[2];

  var hx = ey * az - ez * ay;
  var hy = ez * ax - ex * az;
  var hz = ex * ay - ey * ax;
  final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
  if (normH < 0.1) return null;
  final invH = 1.0 / normH;
  hx *= invH;
  hy *= invH;
  hz *= invH;

  final normA = math.sqrt(ax * ax + ay * ay + az * az);
  if (normA < 0.1) return null;
  final invA = 1.0 / normA;
  final nax = ax * invA, nay = ay * invA, naz = az * invA;

  final mx = nay * hz - naz * hy;
  final my = naz * hx - nax * hz;
  final mz = nax * hy - nay * hx;

  return [hx, hy, hz, mx, my, mz, nax, nay, naz];
}
