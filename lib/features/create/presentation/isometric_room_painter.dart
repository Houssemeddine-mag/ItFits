import 'dart:math';
import 'package:flutter/material.dart';
import 'package:itfits/core/models/floor_plan_data.dart';

class IsometricRoomPainter extends CustomPainter {
  final FloorPlanData floorPlan;
  final double rotationY;
  final double rotationX;
  final double scale;
  final double offsetX;
  final double offsetY;
  final bool showGrid;
  final bool showLabels;
  final List<int>? palette;

  IsometricRoomPainter({
    required this.floorPlan,
    this.rotationY = 0.785,
    this.rotationX = 0.523,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.showGrid = true,
    this.showLabels = true,
    this.palette,
  });

  static const double _nearWallAlpha = 0.22;

  Color get _floorColor => palette?.isNotEmpty == true
      ? Color(palette!.first).withValues(alpha: 0.35)
      : const Color(0xFFF0E8D8);

  Color _wallColor(int i) {
    if (palette != null && palette!.isNotEmpty) {
      final c = Color(palette!.first);
      final b = i.isEven ? 0.78 : 0.62;
      return Color.fromARGB(255, (c.r * b * 255).round().clamp(0, 255),
          (c.g * b * 255).round().clamp(0, 255), (c.b * b * 255).round().clamp(0, 255));
    }
    return Color.fromARGB(255, i.isEven ? 210 : 180, i.isEven ? 200 : 170, i.isEven ? 185 : 158);
  }

  Color get _wallStroke => palette?.isNotEmpty == true
      ? Color(palette!.first).withValues(alpha: 0.4)
      : const Color(0xFFB0A898);

  Color get _doorFill {
    if (palette != null && palette!.length > 2) return Color(palette![2]).withValues(alpha: 0.8);
    return const Color(0xFF9B7B6A);
  }

  static const Color _glass = Color(0x66ADD8E6);
  static const Color _frame = Color(0xFF5A7A8A);

  late Offset _pivot;
  late double _cY, _sY, _cX, _sX;

  void _setupCamera() {
    _pivot = floorPlan.bounds.center;
    _cY = cos(rotationY);
    _sY = sin(rotationY);
    _cX = cos(rotationX);
    _sX = sin(rotationX);
  }

  double _right(double x, double y) =>
      (x - _pivot.dx) * _cY - (y - _pivot.dy) * _sY;

  double _away(double x, double y) =>
      -((x - _pivot.dx) * _sY + (y - _pivot.dy) * _cY);

  Offset _p(double x, double y, double z, double ppm, Offset c) {
    final up = _away(x, y) * _sX + z * _cX;
    return Offset(_right(x, y) * ppm + c.dx + offsetX, -up * ppm + c.dy + offsetY);
  }

  double _depth(double x, double y, double z) => _away(x, y) * _cX - z * _sX;

  bool _facesViewer(int i) {
    final n = floorPlan.inwardNormal(i);
    return n.dx * _sY + n.dy * _cY > 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (floorPlan.walls.isEmpty) return;
    _setupCamera();
    final center = Offset(size.width / 2, size.height / 2);
    final b = floorPlan.bounds;
    final roomMax = max(b.width, b.height);
    final ppm = min(size.width, size.height) * 0.6 / (roomMax + 1.0) * scale;

    if (showGrid) _drawGrid(canvas, ppm, center);
    _drawFloor(canvas, ppm, center);

    final h = floorPlan.ceilingHeight;
    final order = List<int>.generate(floorPlan.walls.length, (i) => i)
      ..sort((a, b) {
        final ma = floorPlan.walls[a].midpoint;
        final mb = floorPlan.walls[b].midpoint;
        return _depth(mb.dx, mb.dy, h / 2).compareTo(_depth(ma.dx, ma.dy, h / 2));
      });

    for (final i in order) {
      final opaque = !floorPlan.walls[i].isExternal || _facesViewer(i);
      final alpha = opaque ? 1.0 : _nearWallAlpha;
      _drawWall(canvas, i, ppm, center, alpha);
      for (final d in floorPlan.doors.where((d) => d.wallIndex == i)) {
        _drawDoor(canvas, d, ppm, center, alpha);
      }
      for (final w in floorPlan.windows.where((w) => w.wallIndex == i)) {
        _drawWindow(canvas, w, ppm, center, alpha);
      }
      if (opaque) {
        for (final o in floorPlan.outlets.where((o) => o.wallIndex == i)) {
          _drawOutlet(canvas, o, ppm, center);
        }
      }
    }

    if (showLabels) _drawLabels(canvas, ppm, center);
  }

  void _drawFloor(Canvas canvas, double ppm, Offset c) {
    final outline = floorPlan.outline;
    if (outline.length < 3) return;
    final verts = outline.map((p) => _p(p.dx, p.dy, 0, ppm, c)).toList();

    final path = Path()..addPolygon(verts, true);
    canvas.drawPath(path, Paint()..color = _floorColor);

    canvas.save();
    canvas.clipPath(path);
    final b = floorPlan.bounds;
    const plankW = 0.25;
    final lineP = Paint()
      ..color = _wallStroke.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (double x = b.left + plankW; x < b.right; x += plankW) {
      canvas.drawLine(_p(x, b.top, 0, ppm, c), _p(x, b.bottom, 0, ppm, c), lineP);
    }
    for (double y = b.top + plankW; y < b.bottom; y += plankW) {
      final row = ((y - b.top) / plankW).round();
      final off = row.isOdd ? plankW / 2 : 0.0;
      canvas.drawLine(_p(b.left + off, y, 0, ppm, c), _p(b.right - off, y, 0, ppm, c), lineP);
    }
    canvas.restore();

    canvas.drawPath(path, Paint()
      ..color = _wallStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
  }

  Offset _onWall(WallSegment wall, Offset inward, double t, double offset) => Offset(
        wall.start.dx + (wall.end.dx - wall.start.dx) * t + inward.dx * offset,
        wall.start.dy + (wall.end.dy - wall.start.dy) * t + inward.dy * offset,
      );

  void _drawWall(Canvas canvas, int i, double ppm, Offset c, double alpha) {
    final wall = floorPlan.walls[i];
    final inward = floorPlan.inwardNormal(i);
    final h = floorPlan.ceilingHeight;
    const thick = 0.06;

    final s = _onWall(wall, inward, 0, thick);
    final e = _onWall(wall, inward, 1, thick);
    final quad = Path()
      ..addPolygon([
        _p(s.dx, s.dy, 0, ppm, c),
        _p(e.dx, e.dy, 0, ppm, c),
        _p(e.dx, e.dy, h, ppm, c),
        _p(s.dx, s.dy, h, ppm, c),
      ], true);

    canvas.drawPath(quad, Paint()..color = _wallColor(i).withValues(alpha: alpha));
    canvas.drawPath(quad, Paint()
      ..color = _wallStroke.withValues(alpha: alpha < 1 ? 0.6 : 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6);
    canvas.drawLine(
      _p(wall.start.dx, wall.start.dy, h, ppm, c),
      _p(wall.end.dx, wall.end.dy, h, ppm, c),
      Paint()
        ..color = _wallStroke.withValues(alpha: 0.3)
        ..strokeWidth = 0.4,
    );
  }

  (double, double) _span(WallSegment wall, double pos, double width) {
    final half = wall.length > 0 ? width / wall.length / 2 : 0.0;
    return ((pos - half).clamp(0.0, 1.0), (pos + half).clamp(0.0, 1.0));
  }

  void _drawDoor(Canvas canvas, Door door, double ppm, Offset c, double alpha) {
    final wall = floorPlan.walls[door.wallIndex];
    final inward = floorPlan.inwardNormal(door.wallIndex);
    const thick = 0.065;
    final (l, r) = _span(wall, door.positionAlongWall, door.width);
    Offset at(double t, double z) {
      final p = _onWall(wall, inward, t, thick);
      return _p(p.dx, p.dy, z, ppm, c);
    }

    final path = Path()
      ..addPolygon([at(l, 0.01), at(r, 0.01), at(r, door.height), at(l, door.height)], true);
    canvas.drawPath(path, Paint()..color = _doorFill.withValues(alpha: 0.8 * alpha));
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF5A3E2A).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);

    if (door.swing == DoorSwing.double) {
      final m = (l + r) / 2;
      canvas.drawLine(at(m, 0.01), at(m, door.height), Paint()
        ..color = const Color(0xFF5A3E2A).withValues(alpha: alpha)
        ..strokeWidth = 1.5);
    }
    final hs = door.swing == DoorSwing.left ? 0.85 : 0.15;
    canvas.drawCircle(at(l + (r - l) * hs, door.height * 0.5), 2.5 * scale,
        Paint()..color = const Color(0xFF5A3E2A).withValues(alpha: 0.7 * alpha));
  }

  void _drawWindow(Canvas canvas, FloorWindow win, double ppm, Offset c, double alpha) {
    final wall = floorPlan.walls[win.wallIndex];
    final inward = floorPlan.inwardNormal(win.wallIndex);
    const thick = 0.065;
    final (l, r) = _span(wall, win.positionAlongWall, win.width);
    final sill = win.sillHeight;
    final top = min(sill + win.height, floorPlan.ceilingHeight);
    Offset at(double t, double z) {
      final p = _onWall(wall, inward, t, thick);
      return _p(p.dx, p.dy, z, ppm, c);
    }

    final frame = _frame.withValues(alpha: alpha);
    final glass = Path()..addPolygon([at(l, sill), at(r, sill), at(r, top), at(l, top)], true);
    canvas.drawPath(glass, Paint()..color = _glass.withValues(alpha: _glass.a * alpha));
    canvas.drawPath(glass, Paint()
      ..color = frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);

    final midH = (sill + top) / 2;
    canvas.drawLine(at(l, midH), at(r, midH), Paint()..color = frame..strokeWidth = 1.2);
    final midT = (l + r) / 2;
    canvas.drawLine(at(midT, sill), at(midT, top), Paint()..color = frame..strokeWidth = 1.2);
    canvas.drawLine(
      at(l + (r - l) * 0.15, top - (top - sill) * 0.1),
      at(l + (r - l) * 0.35, sill + (top - sill) * 0.1),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25 * alpha)
        ..strokeWidth = 1.5,
    );
  }

  void _drawOutlet(Canvas canvas, Outlet outlet, double ppm, Offset c) {
    final wall = floorPlan.walls[outlet.wallIndex];
    final inward = floorPlan.inwardNormal(outlet.wallIndex);
    final p = _onWall(wall, inward, outlet.positionAlongWall, 0.07);

    final color = switch (outlet.type) {
      OutletType.power => const Color(0xFFE8A317),
      OutletType.data => const Color(0xFF4A90D9),
      OutletType.hdmi => const Color(0xFF2C2C2C),
      OutletType.usb => const Color(0xFF4CAF50),
      OutletType.coax => const Color(0xFF7B68EE),
    };

    final center = _p(p.dx, p.dy, outlet.heightFromFloor, ppm, c);
    final r = 4.0 * scale;
    final rect = Rect.fromCenter(center: center, width: r * 2, height: r * 2.4);
    canvas.drawOval(rect, Paint()..color = const Color(0xFFF5F5F0));
    canvas.drawOval(rect, Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
  }

  void _drawGrid(Canvas canvas, double ppm, Offset c) {
    final p = Paint()
      ..color = const Color(0x1A808080)
      ..strokeWidth = 0.5;
    final b = floorPlan.bounds;
    final s = (max(b.width, b.height) / 2 + 1.5).ceilToDouble();
    final cx = (_pivot.dx * 2).roundToDouble() / 2;
    final cy = (_pivot.dy * 2).roundToDouble() / 2;
    for (double i = -s; i <= s; i += 0.5) {
      canvas.drawLine(_p(cx + i, cy - s, 0, ppm, c), _p(cx + i, cy + s, 0, ppm, c), p);
      canvas.drawLine(_p(cx - s, cy + i, 0, ppm, c), _p(cx + s, cy + i, 0, ppm, c), p);
    }
  }

  void _drawLabels(Canvas canvas, double ppm, Offset c) {
    final h = floorPlan.ceilingHeight;
    for (final w in floorPlan.walls) {
      if (w.length < 0.5) continue;
      final sp = _p(w.midpoint.dx, w.midpoint.dy, h + 0.15, ppm, c);
      final tp = TextPainter(
        text: TextSpan(
            text: '${w.length.toStringAsFixed(1)}m',
            style: TextStyle(color: _wallStroke, fontSize: 9, fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sp.dx - tp.width / 2, sp.dy - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant IsometricRoomPainter o) => true;
}
