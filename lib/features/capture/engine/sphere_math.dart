import 'dart:math' as math;

class Quat {
  final double x, y, z, w;
  const Quat(this.x, this.y, this.z, this.w);

  static const identity = Quat(0, 0, 0, 1);

  factory Quat.yaw(double angleRad) {
    final h = -angleRad / 2;
    return Quat(0, math.sin(h), 0, math.cos(h));
  }

  factory Quat.pitch(double angleRad) {
    final h = angleRad / 2;
    return Quat(math.sin(h), 0, 0, math.cos(h));
  }

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

  List<double> rotate(List<double> v) {
    final qv = Quat(v[0], v[1], v[2], 0);
    final r = this * qv * conjugated;
    return [r.x, r.y, r.z];
  }

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

double angularDistanceDeg(Quat a, Quat b) {
  final d = a.normalized.dot(b.normalized).abs().clamp(-1.0, 1.0);
  return 2.0 * math.acos(d) * 180.0 / math.pi;
}

double viewAngleDeg(Quat pose, SphereTarget target) {
  final a = pose.rotate(const [0, 0, -1]);
  final b = target.direction;
  final d = (a[0] * b[0] + a[1] * b[1] + a[2] * b[2]).clamp(-1.0, 1.0);
  return math.acos(d) * 180.0 / math.pi;
}

class CameraFov {
  final double tanHalfWidth;

  final double tanHalfHeight;

  const CameraFov(this.tanHalfWidth, this.tanHalfHeight);

  static final typical = CameraFov.from35mm(26, 4 / 3);

  factory CameraFov.from35mm(double focal35, double aspect) {
    final tanLong = (43.27 * 0.8 / 2) / focal35;
    return CameraFov(tanLong / aspect, tanLong);
  }

  double get horizontalDeg => 2 * math.atan(tanHalfWidth) * 180 / math.pi;
  double get verticalDeg => 2 * math.atan(tanHalfHeight) * 180 / math.pi;
}

enum SphereRing { equator, upper, lower, zenith, nadir }

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

  Quat get orientation {
    const d2r = math.pi / 180.0;
    return (Quat.yaw(yawDeg * d2r) * Quat.pitch(pitchDeg * d2r)).normalized;
  }

  List<double> get direction =>
      orientation.rotate(const [0, 0, -1]);
}

List<SphereTarget> buildSphereLattice() {
  final targets = <SphereTarget>[];
  for (var i = 0; i < 8; i++) {
    targets.add(SphereTarget(
      id: 'eq-$i',
      yawDeg: i * 45.0,
      pitchDeg: 0,
      ring: SphereRing.equator,
    ));
  }
  for (var i = 0; i < 6; i++) {
    targets.add(SphereTarget(
      id: 'up-$i',
      yawDeg: 22.5 + i * 60.0,
      pitchDeg: 45,
      ring: SphereRing.upper,
    ));
  }
  for (var i = 0; i < 6; i++) {
    targets.add(SphereTarget(
      id: 'lo-$i',
      yawDeg: i * 60.0,
      pitchDeg: -45,
      ring: SphereRing.lower,
    ));
  }
  targets.add(const SphereTarget(
      id: 'zenith', yawDeg: 0, pitchDeg: 90, ring: SphereRing.zenith));
  targets.add(const SphereTarget(
      id: 'nadir', yawDeg: 0, pitchDeg: -90, ring: SphereRing.nadir));
  return targets;
}

double wrapAngleDeg(double deg) {
  var d = deg % 360.0;
  if (d >= 180.0) d -= 360.0;
  if (d < -180.0) d += 360.0;
  return d;
}

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
      viewAngleDeg(pose, current) <= stickRadiusDeg) {
    return current;
  }
  SphereTarget? best;
  var bestErr = double.infinity;
  for (final t in targets) {
    if (done.contains(t.id)) continue;
    final err = viewAngleDeg(pose, t);
    if (err < bestErr) {
      bestErr = err;
      best = t;
    }
  }
  return best;
}

List<double> deviceToWorldFromEuler(double yaw, double pitch, double roll) {
  final cy = math.cos(yaw), sy = math.sin(yaw);
  final cp = math.cos(pitch), sp = math.sin(pitch);
  final cr = math.cos(roll), sr = math.sin(roll);
  return [
    cy * cr - sy * sp * sr, -sy * cp, cy * sr + sy * sp * cr,
    sy * cr + cy * sp * sr, cy * cp, sy * sr - cy * sp * cr,
    -cp * sr, sp, cp * cr,
  ];
}

class LevelFrame {
  final List<double> rows;
  const LevelFrame._(this.rows);

  factory LevelFrame.fromStartPose(List<double> r0) {
    var hx = -r0[2], hy = -r0[5];
    if (math.sqrt(hx * hx + hy * hy) < 0.25) {
      final sign = -r0[8] < 0 ? 1.0 : -1.0;
      hx = sign * r0[1];
      hy = sign * r0[4];
    }
    final n = math.sqrt(hx * hx + hy * hy);
    if (n < 1e-9) {
      hx = 0;
      hy = 1;
    } else {
      hx /= n;
      hy /= n;
    }
    return LevelFrame._([hy, -hx, 0, 0, 0, 1, -hx, -hy, 0]);
  }

  Quat relativePose(List<double> r) {
    final m = List<double>.filled(9, 0);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        m[i * 3 + j] = rows[i * 3] * r[j] +
            rows[i * 3 + 1] * r[3 + j] +
            rows[i * 3 + 2] * r[6 + j];
      }
    }
    return Quat.fromRotationMatrix(m);
  }
}

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
