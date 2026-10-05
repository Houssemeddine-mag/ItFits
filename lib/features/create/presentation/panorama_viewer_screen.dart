import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import 'package:itfits/core/services/providers.dart';

class PanoramaViewerScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;
  const PanoramaViewerScreen({super.key, required this.onComplete, this.onBack});

  @override
  ConsumerState<PanoramaViewerScreen> createState() => _PanoramaViewerScreenState();
}

class _PanoramaViewerScreenState extends ConsumerState<PanoramaViewerScreen> {
  bool _gyroEnabled = true;
  String? _decodedSource;
  Uint8List? _decodedBytes;
  final double _minimumZoom = 0.5;
  final double _maximumZoom = 5.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final capturedImages = ref.watch(capturedImagesProvider);

    if (capturedImages.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.view_in_ar_outlined, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text('No panorama captured', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                child: const Text('Go back to capture'),
              ),
            ],
          ),
        ),
      );
    }

    if (!identical(capturedImages.first, _decodedSource)) {
      _decodedSource = capturedImages.first;
      _decodedBytes = _decodeImage(capturedImages.first);
    }
    final panoramaBytes = _decodedBytes;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (panoramaBytes != null)
            PanoramaViewer(
              animSpeed: 0.5,
              sensorControl: _gyroEnabled
                  ? SensorControl.orientation
                  : SensorControl.none,
              minZoom: _minimumZoom,
              maxZoom: _maximumZoom,
              child: Image.memory(
                panoramaBytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '360° Panorama',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _gyroEnabled
                                  ? 'Tilt your phone to look around'
                                  : 'Drag to look around',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    children: [
                      _ControlButton(
                        icon: Icons.screen_rotation_outlined,
                        label: 'Gyro',
                        isActive: _gyroEnabled,
                        onTap: () => setState(() => _gyroEnabled = !_gyroEnabled),
                      ),
                      const SizedBox(width: 12),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: widget.onComplete,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Next'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeImage(String base64String) {
    try {
      final data = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
