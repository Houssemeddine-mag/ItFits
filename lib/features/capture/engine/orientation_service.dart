import 'dart:async';
import 'dart:math' as math;

import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';

import 'sphere_math.dart';

/// Device pose sample: orientation of the device relative to the session
/// start frame, plus gyroscope magnitude for the stability check.
class PoseSample {
  final Quat relative;
  final double gyroRadPerSec;
  final DateTime timestamp;
  final bool sensorsValid;

  /// Yaw/pitch aim error (degrees) of the device vs the session start view.
  /// Kept for debugging; the UI derives per-target errors itself.
  final double yawDeg;
  final double pitchDeg;

  const PoseSample({
    required this.relative,
    required this.gyroRadPerSec,
    required this.timestamp,
    required this.sensorsValid,
    required this.yawDeg,
    required this.pitchDeg,
  });
}

/// IMU tracker built on the game rotation vector (§3 of the guide).
///
/// The game rotation vector fuses gyroscope + accelerometer WITHOUT the
/// magnetometer, so the pose is smooth and never jumps around metal objects
/// indoors — the fixed targets stay put on screen. Deltas are measured from
/// the frame latched at session start, which is exactly the frame the
/// capture lattice is defined in.
class OrientationService {
  static const double gyroStabilityThreshold = 0.08;
  static const Duration stabilityWindow = Duration(milliseconds: 150);

  StreamSubscription<OrientationEvent>? _orientationSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double? _yaw;
  double? _pitch;
  double? _roll;
  double? _yaw0;
  double? _pitch0;
  double? _roll0;

  double _gyroMagnitude = 0;
  DateTime? _lastUnstable;
  DateTime? _lastOrientationTime;

  final _controller = StreamController<PoseSample>.broadcast();
  Stream<PoseSample> get poses => _controller.stream;

  PoseSample? _latest;
  PoseSample? get latest => _latest;

  bool _running = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    try {
      motionSensors.orientationUpdateInterval = 20000;
    } catch (_) {}
    try {
      motionSensors.gyroscopeUpdateInterval = 20000;
    } catch (_) {}
    _orientationSub = motionSensors.orientation.listen((e) {
      _yaw = e.yaw;
      _pitch = e.pitch;
      _roll = e.roll;
      _lastOrientationTime = DateTime.now();
      _emit();
    });
    _gyroSub = motionSensors.gyroscope.listen((e) {
      _gyroMagnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (_gyroMagnitude >= gyroStabilityThreshold) {
        _lastUnstable = DateTime.now();
      }
      _emit();
    });
  }

  /// Locks the current orientation as the session start frame.
  /// Returns false when no sensor data is available yet.
  bool latchStartFrame() {
    if (_yaw0 != null) return true;
    if (_yaw == null || _pitch == null || _roll == null) return false;
    _yaw0 = _yaw;
    _pitch0 = _pitch;
    _roll0 = _roll;
    return true;
  }

  bool get hasStartFrame => _yaw0 != null;

  /// True once fused orientation samples are flowing.
  bool get hasOrientation =>
      _lastOrientationTime != null &&
      DateTime.now().difference(_lastOrientationTime!) <
          const Duration(seconds: 3);

  void _emit() {
    if (!_running || _controller.isClosed) return;
    if (_yaw == null || _pitch == null || _roll == null) return;
    final now = DateTime.now();
    final stable = _lastUnstable == null ||
        now.difference(_lastUnstable!) >= stabilityWindow;
    final rel = (_yaw0 == null)
        ? Quat.identity
        : relativeQuatFromDeltas(
            yaw: _yaw!,
            yaw0: _yaw0!,
            pitch: _pitch!,
            pitch0: _pitch0!,
            roll: _roll!,
            roll0: _roll0!,
          );
    _latest = PoseSample(
      relative: rel,
      gyroRadPerSec: _gyroMagnitude,
      timestamp: now,
      sensorsValid: stable && hasOrientation,
      yawDeg: _yaw0 == null
          ? 0
          : wrapAngleDeg((_yaw0! - _yaw!) * 180.0 / math.pi),
      pitchDeg: _yaw0 == null ? 0 : (_pitch! - _pitch0!) * 180.0 / math.pi,
    );
    _controller.add(_latest!);
  }

  Future<void> dispose() async {
    _running = false;
    await _orientationSub?.cancel();
    await _gyroSub?.cancel();
    await _controller.close();
  }
}
