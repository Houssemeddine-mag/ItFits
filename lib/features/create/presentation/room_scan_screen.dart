import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:itfits/features/capture/engine/orientation_service.dart';
import 'package:itfits/features/capture/engine/sphere_math.dart';
import 'package:itfits/features/capture/engine/sphere_stitcher.dart';

/// Guided offline 360° photo-sphere capture.
///
/// Flow: the 12-stop lattice is walked in tour order, ONE target at a time.
/// The preview shows a fixed white alignment frame plus a green ghost frame
/// for the current stop — overlap them, hold briefly (or just tap HOLD),
/// and the shot is taken. The bottom dot map tracks overall progress.
///
/// Rules: the ghost is a passive guide and capture always works — one tap
/// on HOLD (or the camera button) instantly takes the current stop, with no
/// gates. Auto-fire is only a quiet bonus when the phone sits steady.
///
/// Underneath: gyro-fused pose tracking, AE/AF lock from the first frame,
/// and an on-device equirectangular stitch with GPano XMP tagging.
///
/// Emits the finished panorama as a base64 data URL via [onComplete], exactly
/// like the previous capture step, so the rest of the flow is untouched.
class RoomScanScreen extends ConsumerStatefulWidget {
  final Function(List<String>) onComplete;

  const RoomScanScreen({super.key, required this.onComplete});

  @override
  ConsumerState<RoomScanScreen> createState() => _RoomScanScreenState();
}

class _RoomScanScreenState extends ConsumerState<RoomScanScreen>
    with WidgetsBindingObserver {
  // Relaxed auto-fire bonus gates (manual capture has NO gates at all).
  static const double autoFireThresholdDeg = 10.0;
  static const double autoFireGyroLimit = 0.15;
  static const Duration autoFireHold = Duration(milliseconds: 350);
  static const double horizontalFovDeg = 70;
  static const Duration shutterCooldown = Duration(milliseconds: 800);

  /// Minimum frames before stitching is offered (the 6-shot horizon ring).
  static const int minShotsToStitch = 6;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _cameraUnavailable = false;

  final OrientationService _orientation = OrientationService();
  StreamSubscription<PoseSample>? _poseSub;
  PoseSample? _pose;
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  /// Tour-ordered lattice; [_current] is always the first open stop.
  final List<SphereTarget> _targets = buildSphereLattice();
  final Set<String> _done = {};
  final List<SphereShot> _shots = [];
  Directory? _shotDir;

  SphereTarget? _current;
  double _currentErrDeg = 180;
  double _currentYawErrDeg = 0;
  double _currentPitchErrDeg = 0;
  bool _currentBehind = false;

  bool _autoFire = true;
  bool _isCapturing = false;
  bool _stitching = false;
  bool _aeAfLocked = false;
  DateTime? _lastCapture;

  DateTime? _lockStart;
  double _lockProgress = 0;

  Offset? _focusPoint;
  bool _showFocusCircle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Capturing a sphere takes a while — never let the screen sleep mid-flow.
    WakelockPlus.enable();
    _startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _poseSub?.cancel();
    _orientation.dispose();
    _cameraController?.dispose();
    _cameraController = null;
    final dir = _shotDir;
    if (dir != null && dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _startSession() async {
    final tmp = await getTemporaryDirectory();
    _shotDir = await Directory(
      '${tmp.path}/sphere_${DateTime.now().millisecondsSinceEpoch}',
    ).create(recursive: true);
    await _orientation.start();
    _poseSub = _orientation.poses.listen(_onPose);
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        if (mounted) setState(() => _hasPermission = false);
        return;
      }
      if (mounted) setState(() => _hasPermission = true);
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraUnavailable = true);
        return;
      }
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        rear,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      _cameraController = controller;
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraUnavailable = true;
          _isCameraInitialized = false;
        });
      }
    }
  }

  void _onPose(PoseSample pose) {
    _pose = pose;
    if (!_orientation.hasStartFrame) {
      if (_orientation.latchStartFrame() && mounted) setState(() {});
      return;
    }
    _updateCurrent();
    final now = DateTime.now();
    if (now.difference(_lastUiUpdate) > const Duration(milliseconds: 120)) {
      _lastUiUpdate = now;
      if (mounted) setState(() {});
    }
    _maybeAutoFire();
  }

  /// One target at a time: the first open stop in tour order.
  void _updateCurrent() {
    final pose = _pose;
    if (pose == null) return;
    SphereTarget? next;
    for (final t in _targets) {
      if (!_done.contains(t.id)) {
        next = t;
        break;
      }
    }
    _current = next;
    if (next == null) {
      _currentErrDeg = double.infinity;
      _currentBehind = false;
      return;
    }
    final rel = pose.relative.normalized;
    _currentErrDeg = angularDistanceDeg(rel, next.orientation);
    // Per-axis error of the current stop in the camera frame.
    final errQ = next.orientation.conjugated * rel;
    final f = errQ.rotate(const [0, 0, -1]);
    _currentYawErrDeg = math.atan2(-f[0], -f[2]) * 180.0 / math.pi;
    _currentPitchErrDeg =
        math.asin(f[1].clamp(-1.0, 1.0)) * 180.0 / math.pi;
    _currentBehind = -f[2] <= 0;
  }

  /// Quiet bonus only: fires when the phone sits steady on the current stop.
  /// Manual capture below never waits for any of this.
  void _maybeAutoFire() {
    if (!_autoFire || _isCapturing || _stitching) {
      _resetLock();
      return;
    }
    final target = _current;
    final pose = _pose;
    if (target == null || pose == null) {
      _resetLock();
      return;
    }
    if (_currentErrDeg > autoFireThresholdDeg ||
        pose.gyroRadPerSec >= autoFireGyroLimit) {
      _resetLock();
      return;
    }
    final last = _lastCapture;
    if (last != null && DateTime.now().difference(last) < shutterCooldown) {
      return;
    }
    final now = DateTime.now();
    _lockStart ??= now;
    _lockProgress =
        (now.difference(_lockStart!).inMilliseconds / autoFireHold.inMilliseconds)
            .clamp(0.0, 1.0);
    if (_lockProgress >= 1.0) {
      _resetLock();
      _captureShot(target);
    }
  }

  void _resetLock() {
    _lockStart = null;
    _lockProgress = 0;
  }

  /// One tap, always works: captures the current stop instantly.
  Future<void> _captureManual() async {
    if (_isCapturing || _stitching) return;
    final target = _current;
    if (target == null) return;
    await _captureShot(target);
  }

  Future<void> _captureShot(SphereTarget target) async {
    final controller = _cameraController;
    final pose = _pose;
    if (controller == null || pose == null || _shotDir == null) return;
    _resetLock();
    if (mounted) setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();
    try {
      final shot = await controller.takePicture();
      final dest = '${_shotDir!.path}/${target.id}.jpg';
      await shot.saveTo(dest);
      _shots.add(SphereShot(
        filePath: dest,
        quatRelative: pose.relative.normalized.toList(),
      ));
      _done.add(target.id);
      if (!_aeAfLocked) {
        // Guide §3: lock AE/AF from shot #1 against brightness banding.
        try {
          await controller.setFocusMode(FocusMode.locked);
        } catch (_) {}
        try {
          await controller.setExposureMode(ExposureMode.locked);
        } catch (_) {}
        _aeAfLocked = true;
      }
      HapticFeedback.lightImpact();
      _lastCapture = DateTime.now();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _stitchAndFinish() async {
    if (_stitching || _isCapturing || _shots.isEmpty) return;
    if (mounted) setState(() => _stitching = true);
    try {
      final result = await stitchSphereOffline(
        shots: List<SphereShot>.from(_shots),
        hfovDeg: horizontalFovDeg,
      );
      final base64Image =
          'data:image/jpeg;base64,${base64Encode(result.jpegBytes)}';
      if (mounted) widget.onComplete([base64Image]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stitching failed: $e')),
        );
        setState(() => _stitching = false);
      }
    }
  }

  void _onTapToFocus(TapUpDetails details) async {
    final controller = _cameraController;
    if (controller == null || _aeAfLocked) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPoint = box.globalToLocal(details.globalPosition);
    final offset = Offset(
      localPoint.dx / box.size.width,
      localPoint.dy / box.size.height,
    );
    try {
      await controller.setFocusPoint(offset);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _focusPoint = localPoint;
        _showFocusCircle = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showFocusCircle = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission && !_cameraUnavailable) {
      return _messageScaffold(
        icon: Icons.camera_alt_outlined,
        title: 'Camera Access Required',
        body: 'Grant camera permission to capture your 360° photo sphere.',
        actionLabel: 'Open Settings',
        action: openAppSettings,
      );
    }
    if (_cameraUnavailable) {
      return _messageScaffold(
        icon: Icons.no_photography_outlined,
        title: 'Capture Needs a Phone',
        body:
            'Guided 360° capture needs a rear camera plus motion sensors, '
            'which this device does not expose.',
      );
    }

    final canStitch = _shots.length >= minShotsToStitch &&
        !_stitching &&
        !_isCapturing;
    final allDone =
        _current == null && _orientation.hasStartFrame && _done.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Stack(
                  children: [
                    _buildCameraPreview(),
                    _buildAimOverlay(),
                    if (_stitching) _buildStitchingOverlay(),
                  ],
                ),
              ),
              _buildDotMapBar(),
            ],
          ),
          if (canStitch)
            Positioned(
              left: 24,
              right: 24,
              bottom: 148,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _stitchAndFinish,
                    icon: const Icon(
                        Icons.panorama_photosphere_rounded,
                        size: 20),
                    label: Text(
                      allDone
                          ? 'All ${_targets.length} done — Stitch Panorama'
                          : 'Stitch (${_shots.length}/${_targets.length})',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      elevation: 6,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _messageScaffold({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    Future<void> Function()? action,
  }) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 64),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => action?.call(),
                    child: Text(actionLabel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => context.go('/'),
                  ),
                  Expanded(
                    child: Text(
                      _current == null
                          ? 'Capture 360° Sphere'
                          : 'Stop ${_done.length + 1} of ${_targets.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_done.length}/${_targets.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _targets.isEmpty
                      ? 0
                      : _done.length / _targets.length,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00E676)),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }
    return GestureDetector(
      onTapUp: _onTapToFocus,
      child: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_cameraController!)),
          if (_showFocusCircle && _focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 20,
              top: _focusPoint!.dy - 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// One ghost at a time: fixed white frame + green ghost of the current
  /// stop + tappable HOLD button. The ghost is a passive guide — tapping
  /// HOLD (or the camera button below) always captures instantly.
  Widget _buildAimOverlay() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final boxW = size.width * 0.44;
          final boxH = size.height * 0.30;
          final center = size.center(Offset.zero);

          Widget? ghost;
          String? hint;
          if (_current != null && _orientation.hasStartFrame) {
            const pxPerDeg = 14.0;
            var dx = _currentYawErrDeg * pxPerDeg;
            var dy = -_currentPitchErrDeg * pxPerDeg;
            final maxDx = size.width / 2 - boxW / 2 - 8;
            final maxDy = size.height / 2 - boxH / 2 - 8;
            dx = dx.clamp(-maxDx, maxDx);
            dy = dy.clamp(-maxDy, maxDy);
            final aligned =
                _currentErrDeg <= autoFireThresholdDeg;
            ghost = Positioned(
              left: center.dx - boxW / 2 + dx,
              top: center.dy - boxH / 2 + dy,
              child: Container(
                width: boxW,
                height: boxH,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _currentBehind
                        ? Colors.lightBlueAccent
                        : const Color(0xFF00E676).withOpacity(0.9),
                    width: 2,
                  ),
                ),
              ),
            );
            if (_currentBehind) {
              hint = 'Turn around';
            } else if (!aligned) {
              hint =
                  '${_currentErrDeg.toStringAsFixed(0)}° — overlap the green frame, or just tap';
            }
          }

          final holding = _lockProgress > 0 && !_isCapturing && !_stitching;
          final alignedShot = _current != null &&
              _currentErrDeg <= autoFireThresholdDeg;

          return Stack(
            children: [
              Positioned(
                left: center.dx - boxW / 2,
                top: center.dy - boxH / 2,
                child: Container(
                  width: boxW,
                  height: boxH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
              if (ghost != null) ghost,
              // Tappable HOLD button: one tap always captures.
              Positioned(
                left: center.dx - 34,
                top: center.dy - 34,
                child: GestureDetector(
                  onTap: _isCapturing || _stitching ? null : _captureManual,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isCapturing)
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              color: Colors.black87,
                              strokeWidth: 3,
                            ),
                          )
                        else if (holding || alignedShot)
                          Text(
                            holding
                                ? '${(_lockProgress * 100).round()}'
                                : 'HOLD',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        else
                          const Icon(
                            Icons.camera_rounded,
                            color: Colors.black,
                            size: 30,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (holding && !_isCapturing)
                Positioned(
                  left: center.dx - 40,
                  top: center.dy - 40,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _lockProgress,
                        color: const Color(0xFF00E676),
                        backgroundColor: Colors.white24,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                ),
              if (hint != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hint,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!_orientation.hasStartFrame)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(
                    child: Text(
                      'Hold still — locking your starting view…',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Fixed bottom dot map: zenith / upper / equator / lower / nadir rows.
  /// Done = bright green, current stop = white, todo = dim.
  Widget _buildDotMapBar() {
    List<SphereTarget> ring(SphereRing r) =>
        _targets.where((t) => t.ring == r).toList();

    Widget dot(SphereTarget t) {
      final done = _done.contains(t.id);
      final isCurrent = identical(t, _current);
      final color = done
          ? const Color(0xFF00E676)
          : isCurrent
              ? Colors.white
              : const Color(0xFF00E676).withOpacity(0.30);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Container(
          width: isCurrent ? 13 : 11,
          height: isCurrent ? 13 : 11,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );
    }

    Widget row(List<SphereTarget> targets) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (final t in targets) dot(t)],
        ),
      );
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 104,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 26),
                onPressed: () => context.go('/'),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    row(ring(SphereRing.zenith)),
                    row(ring(SphereRing.upper)),
                    row(ring(SphereRing.equator)),
                    row(ring(SphereRing.lower)),
                    row(ring(SphereRing.nadir)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _autoFire
                      ? Icons.auto_awesome_rounded
                      : Icons.auto_awesome_outlined,
                  color: _autoFire ? Colors.amber : Colors.white38,
                  size: 26,
                ),
                tooltip: 'Auto-fire when steady',
                onPressed: () {
                  _resetLock();
                  setState(() => _autoFire = !_autoFire);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.camera_rounded,
                  color: (_current == null || _isCapturing || _stitching)
                      ? Colors.white24
                      : Colors.white,
                  size: 26,
                ),
                tooltip: 'Capture now',
                onPressed: (_current == null || _isCapturing || _stitching)
                    ? null
                    : _captureManual,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStitchingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: Color(0xFF00E676), strokeWidth: 3),
              const SizedBox(height: 24),
              const Text(
                'Stitching panorama…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_shots.length} frames • 100% offline on your phone',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
