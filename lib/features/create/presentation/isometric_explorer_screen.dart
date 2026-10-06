import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itfits/core/models/floor_plan_data.dart';
import 'package:itfits/core/services/providers.dart';
import 'isometric_room_painter.dart';

class IsometricExplorerScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const IsometricExplorerScreen({super.key, required this.onComplete, this.onBack});

  @override
  ConsumerState<IsometricExplorerScreen> createState() => _IsometricExplorerScreenState();
}

class _IsometricExplorerScreenState extends ConsumerState<IsometricExplorerScreen> {
  double _rotationY = 0.785;
  double _rotationX = 0.523;
  double _zoom = 1.0;
  double _baseZoom = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  bool _showGrid = true;
  bool _showLabels = true;
<<<<<<< HEAD
  Offset? _lastFocal;
  double _zoomAtStart = 1.0;
=======
  Offset? _lastFocalPoint;
  bool _isRotating = false;
>>>>>>> c34caadaa955844d60d1c9833eca9f9da2971229

  static const double _minZoom = 0.2;
  static const double _maxZoom = 4.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final floorPlan = ref.watch(floorPlanDataProvider);

    if (floorPlan == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.view_in_ar_outlined, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text('No floor plan data', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                child: const Text('Go back to Floor Plan'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme, theme, floorPlan),
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
<<<<<<< HEAD
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    onScaleEnd: (_) => _lastFocal = null,
=======
                    // Note: scale is a superset of pan — a single-finger drag
                    // arrives as onScaleUpdate with pointerCount == 1, so no
                    // separate onPan handlers (they would fight the scale
                    // recognizer and Flutter logs the redundancy).
                    onLongPressStart: _handleLongPressStart,
                    onLongPressMoveUpdate: _handleLongPressMove,
                    onLongPressEnd: (_) {
                      _lastFocalPoint = null;
                      _isRotating = false;
                    },
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    onScaleEnd: (_) => _lastFocalPoint = null,
>>>>>>> c34caadaa955844d60d1c9833eca9f9da2971229
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: constraints.biggest,
                          painter: IsometricRoomPainter(
                            floorPlan: floorPlan,
                            rotationY: _rotationY,
                            rotationX: _rotationX,
                            scale: _zoom,
                            offsetX: _offsetX,
                            offsetY: _offsetY,
                            showGrid: _showGrid,
                            showLabels: _showLabels,
                            palette: ref.read(selectedPaletteProvider2).isNotEmpty
                                ? ref.read(selectedPaletteProvider2)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  _buildZoomIndicator(colorScheme),
                  _buildZoomButtons(colorScheme),
                ],
              ),
            ),
            _buildControls(colorScheme, theme),
            _buildBottomBar(colorScheme, theme),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocal = details.focalPoint;
    _zoomAtStart = _zoom;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final last = _lastFocal;
    _lastFocal = details.focalPoint;
    if (last == null) return;
    final delta = details.focalPoint - last;
    setState(() {
      if (details.pointerCount == 1) {
        _rotationY += delta.dx * 0.008;
        _rotationX = (_rotationX + delta.dy * 0.006).clamp(0.1, 1.45);
      } else {
        _zoom = (_zoomAtStart * details.scale).clamp(_minZoom, _maxZoom);
        _offsetX += delta.dx;
        _offsetY += delta.dy;
      }
    });
=======
  void _handleLongPressStart(LongPressStartDetails details) {
    _isRotating = true;
    _lastFocalPoint = details.localPosition;
  }

  void _handleLongPressMove(LongPressMoveUpdateDetails details) {
    if (_lastFocalPoint != null) {
      final dx = details.localPosition.dx - _lastFocalPoint!.dx;
      final dy = details.localPosition.dy - _lastFocalPoint!.dy;
      setState(() {
        _rotationY += dx * 0.005;
        _rotationX = (_rotationX - dy * 0.005).clamp(0.1, 1.2);
      });
    }
    _lastFocalPoint = details.localPosition;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    // Long-press rotate wins while held; ignore scale panning meanwhile.
    if (_isRotating) return;
    _lastFocalPoint = details.focalPoint;
    _baseZoom = _zoom;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isRotating) return;
    if (details.pointerCount == 1) {
      // Single-finger drag = pan.
      if (_lastFocalPoint != null) {
        final dx = details.focalPoint.dx - _lastFocalPoint!.dx;
        final dy = details.focalPoint.dy - _lastFocalPoint!.dy;
        setState(() {
          _offsetX += dx;
          _offsetY += dy;
        });
      }
    } else {
      // Two+ fingers = pinch zoom, anchored to zoom at gesture start.
      setState(() {
        _zoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
      });
    }
    _lastFocalPoint = details.focalPoint;
>>>>>>> c34caadaa955844d60d1c9833eca9f9da2971229
  }

  void _zoomIn() {
    HapticFeedback.lightImpact();
    setState(() {
      _zoom = (_zoom * 1.3).clamp(_minZoom, _maxZoom);
    });
  }

  void _zoomOut() {
    HapticFeedback.lightImpact();
    setState(() {
      _zoom = (_zoom / 1.3).clamp(_minZoom, _maxZoom);
    });
  }

  void _resetView() {
    HapticFeedback.mediumImpact();
    setState(() {
      _rotationY = 0.785;
      _rotationX = 0.523;
      _zoom = 1.0;
      _offsetX = 0.0;
      _offsetY = 0.0;
    });
  }

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme, FloorPlanData floorPlan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3D Preview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Drag to rotate \u2022 Two fingers to pan \u2022 Pinch to zoom',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${floorPlan.roomWidth.toStringAsFixed(1)}\u00D7${floorPlan.roomDepth.toStringAsFixed(1)}m',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomIndicator(ColorScheme colorScheme) {
    final percent = (_zoom * 100).round();
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
        ),
        child: Text(
          '$percent%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButtons(ColorScheme colorScheme) {
    return Positioned(
      bottom: 12,
      right: 12,
      child: Column(
        children: [
          _ZoomButton(icon: Icons.add, onTap: _zoomIn, colorScheme: colorScheme),
          const SizedBox(height: 6),
          _ZoomButton(icon: Icons.remove, onTap: _zoomOut, colorScheme: colorScheme),
          const SizedBox(height: 6),
          _ZoomButton(icon: Icons.fit_screen_outlined, onTap: _resetView, colorScheme: colorScheme),
        ],
      ),
    );
  }

  Widget _buildControls(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ControlChip(icon: Icons.grid_on_outlined, label: 'Grid', isSelected: _showGrid, onTap: () => setState(() => _showGrid = !_showGrid), colorScheme: colorScheme),
          const SizedBox(width: 8),
          _ControlChip(icon: Icons.label_outlined, label: 'Labels', isSelected: _showLabels, onTap: () => setState(() => _showLabels = !_showLabels), colorScheme: colorScheme),
          const SizedBox(width: 8),
          _ControlChip(icon: Icons.refresh, label: 'Reset', isSelected: false, onTap: _resetView, colorScheme: colorScheme),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit Plan'),
              onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: const Text('Choose Style'),
              onPressed: widget.onComplete,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ControlChip({required this.icon, required this.label, required this.isSelected, required this.onTap, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ZoomButton({required this.icon, required this.onTap, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Icon(icon, size: 20, color: colorScheme.onSurface),
      ),
    );
  }
}
