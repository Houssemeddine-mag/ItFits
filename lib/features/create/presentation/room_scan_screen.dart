import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import 'package:itfits/core/services/image_compress_service.dart';

class RoomScanScreen extends ConsumerStatefulWidget {
  final Function(List<String>) onComplete;

  const RoomScanScreen({super.key, required this.onComplete});

  @override
  ConsumerState<RoomScanScreen> createState() => _RoomScanScreenState();
}

class _RoomScanScreenState extends ConsumerState<RoomScanScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _isCapturing = false;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  Offset? _focusPoint;
  bool _showFocusCircle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
    _isCapturing = false;
    _focusPoint = null;
    _showFocusCircle = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _cameraController = null;
      _isCameraInitialized = false;
      _isCapturing = false;
      _focusPoint = null;
      _showFocusCircle = false;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission.isGranted) {
      setState(() => _hasPermission = true);
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        _minZoom = await _cameraController!.getMinZoomLevel();
        _maxZoom = await _cameraController!.getMaxZoomLevel();
        _currentZoom = _minZoom;
        await _cameraController!.setZoomLevel(_minZoom);
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } else {
      setState(() => _hasPermission = false);
    }
  }

  Future<void> _openPanoramaCamera() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) {
        if (mounted) setState(() => _isCapturing = false);
        return;
      }

      final compressedFile = await ImageCompressService.compressImage(File(photo.path));
      final bytes = await compressedFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (mounted) {
        widget.onComplete([base64Image]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture: $e')),
        );
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    final compressedFile = await ImageCompressService.compressImage(File(image.path));
    final bytes = await compressedFile.readAsBytes();
    final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    if (mounted) {
      widget.onComplete([base64Image]);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_cameraController == null) return;
    final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    _cameraController!.setZoomLevel(newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _onTapToFocus(TapUpDetails details) async {
    if (_cameraController == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPoint = box.globalToLocal(details.globalPosition);
    final x = localPoint.dx / box.size.width;
    final y = localPoint.dy / box.size.height;
    await _cameraController!.setFocusPoint(Offset(x, y));
    setState(() {
      _focusPoint = localPoint;
      _showFocusCircle = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showFocusCircle = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildTopBar(),
          _buildZoomBadge(),
          _buildBottomBar(),
          if (!_hasPermission) _buildPermissionOverlay(),
        ],
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
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
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
              ).animate().scale(duration: 200.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => context.go('/'),
                ),
                const Expanded(
                  child: Text(
                    'Capture Panorama',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomBadge() {
    if (_currentZoom >= 1.0) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentZoom.toStringAsFixed(1)}x wider',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Text(
                        _isCapturing
                            ? 'Opening panorama camera...'
                            : 'Use your phone\'s panorama mode',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sweep slowly around the room for best results',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isCameraInitialized && _minZoom < 1.0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.zoom_out, color: Colors.white54, size: 16),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayColor: Colors.white24,
                              trackHeight: 2,
                            ),
                            child: Slider(
                              value: _currentZoom,
                              min: _minZoom,
                              max: _maxZoom,
                              onChanged: (value) {
                                _cameraController?.setZoomLevel(value);
                                setState(() => _currentZoom = value);
                              },
                            ),
                          ),
                        ),
                        const Icon(Icons.zoom_in, color: Colors.white54, size: 16),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 6),
                          const Text('Gallery', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _isCapturing ? null : _openPanoramaCamera,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isCapturing ? 68 : 76,
                        height: _isCapturing ? 68 : 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isCapturing ? Colors.red : Colors.transparent,
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _cameras.length < 2 ? null : _switchCamera,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 6),
                          const Text('Switch', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isCapturing)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Capturing...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _openPanoramaCamera,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Open Panorama Camera', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_rounded, color: Colors.white70, size: 16),
                        SizedBox(width: 6),
                        Text('Home', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionOverlay() {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 64),
              const SizedBox(height: 24),
              Text(
                'Camera Access Required',
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Grant camera permission to capture your room panorama',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;
    final newCamera = _cameras[_cameras.indexOf(_cameraController!.description) == 0 ? 1 : 0];
    await _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
    _focusPoint = null;
    _showFocusCircle = false;
    _cameraController = CameraController(newCamera, ResolutionPreset.high, enableAudio: false);
    await _cameraController!.initialize();
    _minZoom = await _cameraController!.getMinZoomLevel();
    _maxZoom = await _cameraController!.getMaxZoomLevel();
    _currentZoom = _minZoom;
    await _cameraController!.setZoomLevel(_minZoom);
    if (mounted) setState(() => _isCameraInitialized = true);
  }
}
