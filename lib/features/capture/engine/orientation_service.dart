import 'dart:async';
import 'dart:math' as math;

import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';

import 'sphere_math.dart';

class PoseSample {
  final Quat relative;
  final double gyroRadPerSec;
  final DateTime timestamp;
  final bool sensorsValid;

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

class OrientationService {
  static const double gyroStabilityThreshold = 0.08;
  static const Duration stabilityWindow = Duration(milliseconds: 150);

  StreamSubscription<OrientationEvent>? _orientationSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  List<double>? _deviceToWorld;
  LevelFrame? _frame;

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
      _deviceToWorld = deviceToWorldFromEuler(e.yaw, e.pitch, e.roll);
      _lastOrientationTime = DateTime.now();
      _emit();
    });
    _gyroSub = motionSensors.gyroscope.listen((e) {
      _gyroMagnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (_gyroMagnitude >= gyroStabilityThreshold) {
        _lastUnstable = DateTime.now();
      }
    });
  }

  bool latchStartFrame() {
    if (_frame != null) return true;
    final r = _deviceToWorld;
    if (r == null) return false;
    _frame = LevelFrame.fromStartPose(r);
    _emit();
    return true;
  }

  bool get hasStartFrame => _frame != null;

  bool get hasOrientation =>
      _lastOrientationTime != null &&
      DateTime.now().difference(_lastOrientationTime!) <
          const Duration(seconds: 3);

  void _emit() {
    if (!_running || _controller.isClosed) return;
    final r = _deviceToWorld;
    if (r == null) return;
    final now = DateTime.now();
    final stable = _lastUnstable == null ||
        now.difference(_lastUnstable!) >= stabilityWindow;
    final rel = _frame?.relativePose(r) ?? Quat.identity;
    final fwd = rel.rotate(const [0, 0, -1]);
    _latest = PoseSample(
      relative: rel,
      gyroRadPerSec: _gyroMagnitude,
      timestamp: now,
      sensorsValid: stable && hasOrientation,
      yawDeg: math.atan2(fwd[0], -fwd[2]) * 180.0 / math.pi,
      pitchDeg: math.asin(fwd[1].clamp(-1.0, 1.0)) * 180.0 / math.pi,
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
