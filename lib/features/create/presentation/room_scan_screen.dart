import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:itfits/features/capture/engine/orientation_service.dart';
import 'package:itfits/features/capture/engine/sphere_math.dart';
import 'package:itfits/features/capture/engine/sphere_stitcher.dart';

class RoomScanScreen extends ConsumerStatefulWidget {
  final Function(List<String>) onComplete;

  const RoomScanScreen({super.key, required this.onComplete});

  @override
  ConsumerState<RoomScanScreen> createState() => _RoomScanScreenState();
}

class _RoomScanScreenState extends ConsumerState<RoomScanScreen>
    with WidgetsBindingObserver {

  static const double autoFireThresholdDeg = 6.0;
  static const double autoFireGyroLimit = 0.20;
  static const Duration autoFireHold = Duration(milliseconds: 320);
  static const Duration shutterCooldown = Duration(milliseconds: 800);

  static const double manualCaptureMaxDeg = 15.0;

  static const int minShotsToStitch = 8;

  static const double _alignedDeg = 7.0;

  static const int _workingShortEdge = 960;

  static const double _pxPerDeg = 12.0;


  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _cameraUnavailable = false;

  Future<void>? _cameraInit;

  CameraFov _fov = CameraFov.typical;

  final OrientationService _orientation = OrientationService();
  StreamSubscription<PoseSample>? _poseSub;
  PoseSample? _pose;
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);


  final List<SphereTarget> _targets = buildSphereLattice();
  final Set<String> _done = {};

  final LinkedHashMap<String, SphereShot> _shots = LinkedHashMap();

  final Map<String, Future<void>> _shotPrep = {};
  Directory? _shotDir;

  SphereTarget? _current;
  double _currentErrDeg = 180;
  double _currentYawErrDeg = 0;
  double _currentPitchErrDeg = 0;
  bool _currentBehind = false;

  bool _autoFire = true;
  bool _isCapturing = false;
  bool _stitching = false;
  DateTime? _lastCapture;

  DateTime? _lockStart;
  double _lockProgress = 0;

  Offset? _focusPoint;
  bool _showFocusCircle = false;
  Timer? _focusTimer;
  bool _showShutterFlash = false;


  bool _undoAvailable = false;
  Timer? _undoTimer;
  SphereTarget? _lastCapturedTarget;


  String? _ringPrompt;
  bool _ringPromptVisible = false;
  Timer? _ringPromptTimer;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(const []);
    _poseSub?.cancel();
    _orientation.dispose();
    _cameraController?.dispose();
    _cameraController = null;
    _undoTimer?.cancel();
    _ringPromptTimer?.cancel();
    _focusTimer?.cancel();
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
      if (_cameraInit != null) return;
      final controller = _cameraController;
      if (controller == null) return;
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController == null) _initCamera();
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

  Future<void> _initCamera() {
    return _cameraInit ??= _doInitCamera().whenComplete(() => _cameraInit = null);
  }

  Future<void> _doInitCamera() async {
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
        ResolutionPreset.max,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _cameraController = controller;
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}
      try {
        await controller.setExposureMode(
            _shots.isEmpty ? ExposureMode.auto : ExposureMode.locked);
      } catch (_) {}
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
    if (now.difference(_lastUiUpdate) > const Duration(milliseconds: 50)) {
      _lastUiUpdate = now;
      if (mounted) setState(() {});
    }
    _maybeAutoFire();
  }

  void _updateCurrent() {
    final pose = _pose;
    if (pose == null) return;

    final next = selectStickyTarget(
      targets: _targets,
      done: _done,
      pose: pose.relative.normalized,
      current: _current,
      stickRadiusDeg: 20.0,
    );

    _current = next;
    if (next == null) {
      _currentErrDeg = double.infinity;
      _currentBehind = false;
      return;
    }
    final rel = pose.relative.normalized;
    _currentErrDeg = viewAngleDeg(rel, next);
    final vCam = (rel.conjugated * next.orientation).rotate(const [0, 0, -1]);
    _currentYawErrDeg = math.atan2(vCam[0], -vCam[2]) * 180.0 / math.pi;
    _currentPitchErrDeg =
        math.asin(vCam[1].clamp(-1.0, 1.0)) * 180.0 / math.pi;
    _currentBehind = vCam[2] >= 0;
  }


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
        (now.difference(_lockStart!).inMilliseconds /
                autoFireHold.inMilliseconds)
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


  Future<void> _captureManual() async {
    if (_isCapturing || _stitching) return;
    final target = _current;
    if (target == null) return;
    if (_currentErrDeg > manualCaptureMaxDeg) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Aim at the green target first'),
          duration: Duration(milliseconds: 1200),
        ));
      return;
    }
    await _captureShot(target);
  }

  Future<void> _captureShot(SphereTarget target) async {
    final controller = _cameraController;
    final pose = _pose;
    if (controller == null || pose == null || _shotDir == null) return;
    _resetLock();
    _undoTimer?.cancel();
    if (mounted) {
      setState(() {
        _isCapturing = true;
        _undoAvailable = false;
      });
    }
    HapticFeedback.mediumImpact();
    final quat = pose.relative.normalized.toList();
    final isFirst = _shots.isEmpty;
    try {
      final shot = await controller.takePicture();
      final dest = '${_shotDir!.path}/${target.id}_'
          '${DateTime.now().microsecondsSinceEpoch}.jpg';
      await shot.saveTo(dest);
      try {
        await File(shot.path).delete();
      } catch (_) {}
      _shots[target.id] = SphereShot(filePath: dest, quatRelative: quat);
      _shotPrep[target.id] = _prepareShot(target.id, dest, quat);
      _done.add(target.id);
      _lastCapturedTarget = target;

      if (isFirst) {
        try {
          await controller.setExposureMode(ExposureMode.locked);
        } catch (_) {}
      }
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}

      if (mounted) {
        setState(() => _showShutterFlash = true);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() => _showShutterFlash = false);
        });
      }

      HapticFeedback.lightImpact();
      _lastCapture = DateTime.now();

      final nextTarget = selectStickyTarget(
        targets: _targets,
        done: _done,
        pose: pose.relative.normalized,
        current: null,
      );
      if (nextTarget != null && nextTarget.ring != target.ring) {
        _showRingPrompt(nextTarget.ring);
      }

      if (mounted) setState(() => _undoAvailable = true);
      _undoTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _undoAvailable = false);
      });
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

  Future<void> _prepareShot(String id, String path, List<double> quat) async {
    try {
      await _prepareShotUnsafe(id, path, quat);
    } catch (e) {
      debugPrint('Shot preparation skipped for $id: $e');
    }
  }

  Future<void> _prepareShotUnsafe(
      String id, String path, List<double> quat) async {
    final focal = await Isolate.run(
        () => readFocal35mm(File(path).readAsBytesSync()));
    if (focal != null && mounted) {
      setState(() => _fov = CameraFov.from35mm(focal, 4 / 3));
    }
    var finalPath = path;
    try {
      final small = path.replaceFirst(RegExp(r'\.jpg$'), '_w.jpg');
      final out = await FlutterImageCompress.compressAndGetFile(
        path,
        small,
        minWidth: _workingShortEdge,
        minHeight: _workingShortEdge,
        quality: 92,
        autoCorrectionAngle: true,
        keepExif: false,
      );
      if (out != null) {
        finalPath = out.path;
        try {
          await File(path).delete();
        } catch (_) {}
      }
    } catch (_) {}
    if (_shots[id]?.filePath == path) {
      _shots[id] =
          SphereShot(filePath: finalPath, quatRelative: quat, focal35mm: focal);
    } else if (finalPath != path) {
      try {
        await File(finalPath).delete();
      } catch (_) {}
    }
  }

  void _undoLastShot() {
    if (!_undoAvailable || _lastCapturedTarget == null || _shots.isEmpty) {
      return;
    }
    _undoTimer?.cancel();
    final target = _lastCapturedTarget!;
    _done.remove(target.id);
    final removed = _shots.remove(target.id);
    _shotPrep.remove(target.id);
    try {
      if (removed != null) {
        final file = File(removed.filePath);
        if (file.existsSync()) file.deleteSync();
      }
    } catch (_) {}
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _undoAvailable = false;
        _lastCapturedTarget = null;
      });
    }
  }


  Future<void> _stitchAndFinish() async {
    if (_stitching || _isCapturing || _shots.isEmpty) return;
    if (mounted) setState(() => _stitching = true);
    try {
      await Future.wait(_shotPrep.values);
      final result = await stitchSphereOffline(
        shots: List<SphereShot>.from(_shots.values),
      );
      final base64Image =
          'data:image/jpeg;base64,${base64Encode(result.jpegBytes)}';
      if (!mounted) return;
      if (result.coverage < 0.97) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${((1 - result.coverage) * 100).round()}% of the sphere was '
              'not captured and has been filled in'),
        ));
      }
      widget.onComplete([base64Image]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stitching failed: $e')),
        );
        setState(() => _stitching = false);
      }
    }
  }


  void _showRingPrompt(SphereRing ring) {
    _ringPromptTimer?.cancel();
    final prompt = switch (ring) {
      SphereRing.equator => 'Sweep around the room →',
      SphereRing.upper => 'Now tilt UP ↑',
      SphereRing.lower => 'Now tilt DOWN ↓',
      SphereRing.zenith => 'Point at the CEILING ↑↑',
      SphereRing.nadir => 'Point at the FLOOR ↓↓',
    };
    if (mounted) {
      setState(() {
        _ringPrompt = prompt;
        _ringPromptVisible = true;
      });
    }
    _ringPromptTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _ringPromptVisible = false);
    });
  }


  void _onTapToFocus(TapDownDetails details) async {
    final controller = _cameraController;
    if (controller == null || !_isCameraInitialized) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPoint = details.localPosition;
    final size = box.size;
    final normX = (localPoint.dx / size.width).clamp(0.0, 1.0);
    final normY = (localPoint.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      _focusPoint = localPoint;
      _showFocusCircle = true;
    });
    try {
      await controller.setFocusPoint(Offset(normX, normY));
      if (_shots.isEmpty) {
        await controller.setExposurePoint(Offset(normX, normY));
      }
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {}
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showFocusCircle = false);
    });
  }

  Widget _buildFocusIndicator() {
    if (!_showFocusCircle || _focusPoint == null) return const SizedBox.shrink();
    return Positioned(
      left: _focusPoint!.dx - 32,
      top: _focusPoint!.dy - 32,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 250),
          tween: Tween(begin: 1.35, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFD740), width: 1.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD740),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  String _ringLabel(SphereRing ring) => switch (ring) {
        SphereRing.equator => 'Horizon',
        SphereRing.upper => 'Upper',
        SphereRing.lower => 'Lower',
        SphereRing.zenith => 'Ceiling',
        SphereRing.nadir => 'Floor',
      };


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

    final canStitch =
        _shots.length >= minShotsToStitch && !_stitching && !_isCapturing;
    final allDone =
        _current == null && _orientation.hasStartFrame && _done.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                RepaintBoundary(child: _buildCameraPreview()),
                _buildGuidanceOverlay(),
                _buildFocusIndicator(),
                if (_showShutterFlash)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                if (_ringPromptVisible && _ringPrompt != null)
                  _buildRingBanner(),
                if (_stitching) _buildStitchingOverlay(),
              ],
            ),
          ),
          _buildBottomControls(canStitch, allDone),
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
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white),
                    onPressed: () => context.go('/'),
                  ),
                  Expanded(
                    child: Text(
                      _current == null
                          ? 'Capture Complete'
                          : 'Stop ${_done.length + 1} of ${_targets.length}'
                              ' — ${_ringLabel(_current!.ring)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapToFocus,
      child: Center(child: CameraPreview(_cameraController!)),
    );
  }

  double _previewWidth(Size area) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return area.width;
    }
    final portraitAspect = 1 / controller.value.aspectRatio;
    return math.min(area.width, area.height * portraitAspect);
  }


  Widget _buildGuidanceOverlay() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final center = size.center(Offset.zero);
          final children = <Widget>[];

          if (_current != null && _orientation.hasStartFrame) {
            final targetCard = _buildTargetCard(center, size);
            if (targetCard != null) {
              children.add(targetCard);
            }

            final dx = _currentYawErrDeg * _pxPerDeg;
            final dy = -_currentPitchErrDeg * _pxPerDeg;
            children.add(_buildCenterReticle(center, dx, dy));

            if (_currentErrDeg > _alignedDeg) {
              children.add(_hintPill(
                _currentBehind
                    ? 'Turn around — ${_currentErrDeg.toStringAsFixed(0)}°'
                    : '${_currentErrDeg.toStringAsFixed(0)}° to target',
              ));
            } else if (_autoFire) {
              children.add(_hintPill('Hold steady…'));
            }
          } else if (_orientation.hasStartFrame && _current == null) {
            children.add(_hintPill('Sphere complete! Ready to stitch'));
          } else {
            children.add(const Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: Text(
                  'Hold still — locking your starting view…',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ));
          }

          return Stack(children: children);
        },
      ),
    );
  }

  Widget _buildCenterReticle(Offset center, double dx, double dy) {
    final aligned = _currentErrDeg <= _alignedDeg;
    final pointerVisible = _currentErrDeg > _alignedDeg && _current != null;
    final angle = math.atan2(dy, dx);
    const circleRadius = 36.0;

    return Positioned(
      left: center.dx - circleRadius - 18,
      top: center.dy - circleRadius - 18,
      child: SizedBox(
        width: (circleRadius + 18) * 2,
        height: (circleRadius + 18) * 2,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (pointerVisible)
              Positioned(
                left: (circleRadius + 18) + (circleRadius + 12) * math.cos(angle) - 14,
                top: (circleRadius + 18) + (circleRadius + 12) * math.sin(angle) - 14,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: angle + math.pi / 2,
                    child: Icon(
                      Icons.navigation_rounded,
                      color: _currentBehind
                          ? Colors.lightBlueAccent
                          : Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),

            if (aligned)
              SizedBox(
                width: circleRadius * 2 + 10,
                height: circleRadius * 2 + 10,
                child: CircularProgressIndicator(
                  value: _lockProgress > 0 ? _lockProgress : null,
                  strokeWidth: 4,
                  color: const Color(0xFF00E676),
                  backgroundColor: Colors.white24,
                ),
              ),

            GestureDetector(
              onTap: aligned ? _captureManual : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: circleRadius * 2,
                height: circleRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: aligned
                      ? const Color(0xFF00E676).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: aligned ? const Color(0xFF00E676) : Colors.white,
                    width: aligned ? 3.5 : 2.5,
                  ),
                  boxShadow: aligned
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E676).withValues(alpha: 0.45),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: aligned
                      ? const Text(
                          'HOLD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        )
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white70,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildTargetCard(Offset center, Size size) {
    final target = _current;
    final pose = _pose;
    if (target == null || pose == null || !_orientation.hasStartFrame) {
      return null;
    }

    final rel = pose.relative.normalized;
    final qRel = (rel.conjugated * target.orientation).normalized;
    final vCam = qRel.rotate(const [0, 0, -1]);

    if (vCam[2] >= 0) return null;
    final zDepth = -vCam[2];
    if (zDepth < 0.05) return null;

    final focal = (_previewWidth(size) / 2) / _fov.tanHalfWidth;
    final dx = (vCam[0] / zDepth) * focal;
    final dy = -(vCam[1] / zDepth) * focal;

    const cardW = 120.0;
    const cardH = 160.0;
    const apertureR = 38.0;

    final cardCenter = Offset(center.dx + dx, center.dy + dy);

    if (cardCenter.dx < -150 ||
        cardCenter.dx > size.width + 150 ||
        cardCenter.dy < -150 ||
        cardCenter.dy > size.height + 150) {
      return null;
    }

    final aligned = _currentErrDeg <= _alignedDeg;
    final color = aligned ? const Color(0xFF00E676) : const Color(0xAA00E676);

    return Positioned(
      left: cardCenter.dx - cardW / 2,
      top: cardCenter.dy - cardH / 2,
      child: IgnorePointer(
        child: CustomPaint(
          size: const Size(cardW, cardH),
          painter: _TargetCardPainter(
            cardWidth: cardW,
            cardHeight: cardH,
            apertureRadius: apertureR,
            color: color,
            aligned: aligned,
          ),
        ),
      ),
    );
  }

  Widget _hintPill(String text) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildRingBanner() {
    return Positioned(
      left: 24,
      right: 24,
      top: 24,
      child: AnimatedOpacity(
        opacity: _ringPromptVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 350),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            _ringPrompt ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildBottomControls(bool canStitch, bool allDone) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canStitch)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
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
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            if (_undoAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextButton.icon(
                  onPressed: _undoLastShot,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text(
                    'Undo last shot',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CustomPaint(
                      painter: _SphereMatrixPainter(
                        targets: _targets,
                        done: _done,
                        current: _current,
                        pulseValue: _miniMapPulse(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _captureButton(),
                  const Spacer(),
                  SizedBox(
                    width: 76,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _autoFire
                                ? Icons.auto_awesome_rounded
                                : Icons.auto_awesome_outlined,
                            color: _autoFire
                                ? Colors.amber
                                : Colors.white38,
                            size: 24,
                          ),
                          tooltip: 'Auto-fire when steady',
                          onPressed: () {
                            _resetLock();
                            setState(() => _autoFire = !_autoFire);
                          },
                        ),
                        Text(
                          _autoFire ? 'Auto' : 'Manual',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _miniMapPulse() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return 0.4 + 0.6 * ((math.sin(ms / 500.0) + 1) / 2);
  }

  Widget _captureButton() {
    final active = _current != null && !_isCapturing && !_stitching;
    final aligned = _currentErrDeg <= _alignedDeg;
    final ringColor = active
        ? (aligned ? const Color(0xFF00E676) : Colors.white)
        : Colors.white24;
    final holding = _lockProgress > 0 && !_isCapturing && !_stitching;

    return GestureDetector(
      onTap: active ? _captureManual : null,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (holding)
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: _lockProgress,
                  color: const Color(0xFF00E676),
                  backgroundColor: Colors.white12,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                ),
              ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 3.5),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isCapturing ? 30 : 58,
              height: _isCapturing ? 30 : 58,
              decoration: BoxDecoration(
                shape: _isCapturing
                    ? BoxShape.rectangle
                    : BoxShape.circle,
                borderRadius:
                    _isCapturing ? BorderRadius.circular(6) : null,
                color: active ? Colors.white : Colors.white24,
              ),
            ),
            if (_isCapturing)
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: Colors.black87,
                  strokeWidth: 2.5,
                ),
              ),
          ],
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


class _TargetCardPainter extends CustomPainter {
  final double cardWidth;
  final double cardHeight;
  final double apertureRadius;
  final Color color;
  final bool aligned;

  const _TargetCardPainter({
    required this.cardWidth,
    required this.cardHeight,
    required this.apertureRadius,
    required this.color,
    required this.aligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cardRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    final cardPath = Path()..addRRect(cardRRect);
    final holePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: apertureRadius));

    final cutoutPath =
        Path.combine(PathOperation.difference, cardPath, holePath);

    final fillPaint = Paint()
      ..color = aligned
          ? color.withValues(alpha: 0.35)
          : color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cutoutPath, fillPaint);

    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = aligned ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(cardRRect, borderPaint);

    final apertureRimPaint = Paint()
      ..color = color.withValues(alpha: aligned ? 0.95 : 0.65)
      ..strokeWidth = aligned ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, apertureRadius, apertureRimPaint);
  }

  @override
  bool shouldRepaint(_TargetCardPainter old) =>
      old.aligned != aligned || old.color != color;
}


class _SphereMatrixPainter extends CustomPainter {
  final List<SphereTarget> targets;
  final Set<String> done;
  final SphereTarget? current;
  final double pulseValue;

  _SphereMatrixPainter({
    required this.targets,
    required this.done,
    required this.current,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final rowY = [
      size.height * 0.12,
      size.height * 0.31,
      size.height * 0.50,
      size.height * 0.69,
      size.height * 0.88,
    ];

    void drawTargetDot(SphereTarget t, Offset pos) {
      final isDone = done.contains(t.id);
      final isCurrent = current != null && t.id == current!.id;

      if (isDone) {
        final fillPaint = Paint()..color = const Color(0xFF00E676);
        canvas.drawCircle(pos, 3.5, fillPaint);
        final haloPaint = Paint()
          ..color = const Color(0xFF00E676).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(pos, 5.2, haloPaint);
      } else if (isCurrent) {
        final r = 3.8 + 1.2 * pulseValue;
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.35 + 0.25 * pulseValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pos, r + 2.2, glowPaint);
        final fillPaint = Paint()..color = Colors.white;
        canvas.drawCircle(pos, r, fillPaint);
      } else {
        final fillPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.24);
        canvas.drawCircle(pos, 2.5, fillPaint);
      }
    }

    final zenith = targets.firstWhere(
      (t) => t.id == 'zenith',
      orElse: () => targets.first,
    );
    drawTargetDot(zenith, Offset(centerX, rowY[0]));

    void drawRing(SphereRing ring, double y, double widthFactor) {
      final dots = targets.where((t) => t.ring == ring).toList();
      if (dots.isEmpty) return;
      final w = size.width * widthFactor;
      final spacing = w / (dots.length + 1);
      for (var i = 0; i < dots.length; i++) {
        drawTargetDot(
            dots[i], Offset(centerX - w / 2 + spacing * (i + 1), y));
      }
    }

    drawRing(SphereRing.upper, rowY[1], 0.82);
    drawRing(SphereRing.equator, rowY[2], 1.0);
    drawRing(SphereRing.lower, rowY[3], 0.82);

    final nadir = targets.firstWhere(
      (t) => t.id == 'nadir',
      orElse: () => targets.last,
    );
    drawTargetDot(nadir, Offset(centerX, rowY[4]));
  }

  @override
  bool shouldRepaint(_SphereMatrixPainter old) => true;
}
