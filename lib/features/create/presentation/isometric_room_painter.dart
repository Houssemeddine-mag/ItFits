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

  Color _doorFill(int i) {
    if (palette != null && palette!.length > 2) return Color(palette![2]).withValues(alpha: 0.8);
    return const Color(0xFF9B7B6A);
  }

  static const Color _glass = Color(0x66ADD8E6);
  static const Color _frame = Color(0xFF5A7A8A);

  Offset _p(double x, double y, double z, double ppm, Offset c) {
    final cY = cos(rotationY), sY = sin(rotationY);
    final cX = cos(rotationX), sX = sin(rotationX);
    final x1 = x * cY - y * sY;
    final y1 = x * sY + y * cY;
    final y2 = y1 * cX - z * sX;
    final z2 = y1 * sX + z * cX;
    return Offset(x1 * ppm + c.dx + offsetX, -y2 * ppm + c.dy + offsetY);
  }

  double _depth(double x, double y, double z) {
    final cY = cos(rotationY), sY = sin(rotationY);
    final cX = cos(rotationX), sX = sin(rotationX);
    final x1 = x * cY - y * sY;
    final y1 = x * sY + y * cY;
    return y1 * sX + z * cX;
  }

  _WallDir _wallDir(WallSegment wall) {
    final dx = wall.end.dx - wall.start.dx;
    final dy = wall.end.dy - wall.start.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1e-10) return _WallDir(0, 0);

    double cx = 0, cy = 0;
    final walls = floorPlan.walls;
    for (final w in walls) {
      cx += w.start.dx;
      cy += w.start.dy;
    }
    cx /= walls.length;
    cy /= walls.length;

    final mx = (wall.start.dx + wall.end.dx) / 2;
    final my = (wall.start.dy + wall.end.dy) / 2;

    final toCx = cx - mx, toCy = cy - my;

    final nx1 = -dy / len, ny1 = dx / len;
    final nx2 = dy / len, ny2 = -dx / len;

    if (nx1 * toCx + ny1 * toCy > 0) {
      return _WallDir(nx1, ny1);
    }
    return _WallDir(nx2, ny2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final roomMax = max(floorPlan.roomWidth, floorPlan.roomDepth);
    final ppm = min(size.width, size.height) * 0.6 / (roomMax + 1.0) * scale;

    if (showGrid) _drawGrid(canvas, ppm, center);
    _drawFloor(canvas, ppm, center);
    _drawWalls(canvas, ppm, center);

    for (final door in floorPlan.doors) _drawDoor(canvas, door, ppm, center);
    for (final win in floorPlan.windows) _drawWindow(canvas, win, ppm, center);
    for (final outlet in floorPlan.outlets) _drawOutlet(canvas, outlet, ppm, center);

    if (showLabels) _drawLabels(canvas, ppm, center);
  }

  void _drawFloor(Canvas canvas, double ppm, Offset c) {
    final verts = floorPlan.walls.map((w) => _p(w.start.dx, w.start.dy, 0, ppm, c)).toList();
    if (verts.length < 3) return;

    final path = Path()..moveTo(verts[0].dx, verts[0].dy);
    for (int i = 1; i < verts.length; i++) path.lineTo(verts[i].dx, verts[i].dy);
    path.close();

    canvas.drawPath(path, Paint()..color = _floorColor);

    canvas.save();
    canvas.clipPath(path);
    final walls = floorPlan.walls;
    final xs = walls.map((w) => w.start.dx).toList();
    final ys = walls.map((w) => w.start.dy).toList();
    final minX = xs.reduce(min), maxX = xs.reduce(max);
    final minY = ys.reduce(min), maxY = ys.reduce(max);
    final plankW = 0.25;
    final lineP = Paint()..color = _wallStroke.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 0.5;

    for (double x = minX + plankW; x < maxX; x += plankW) {
      canvas.drawLine(_p(x, minY, 0, ppm, c), _p(x, maxY, 0, ppm, c), lineP);
    }
    for (double y = minY + plankW; y < maxY; y += plankW) {
      final row = ((y - minY) / plankW).round();
      final off = row.isOdd ? plankW / 2 : 0.0;
      canvas.drawLine(_p(minX + off, y, 0, ppm, c), _p(maxX - off, y, 0, ppm, c), lineP);
    }
    canvas.restore();

    canvas.drawPath(path, Paint()..color = _wallStroke..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  void _drawWalls(Canvas canvas, double ppm, Offset c) {
    final walls = floorPlan.walls;
    final h = floorPlan.ceilingHeight;

    final sorted = List<int>.generate(walls.length, (i) => i);
    sorted.sort((a, b) {
      final ma = walls[a].midpoint;
      final mb = walls[b].midpoint;
      return _depth(ma.dx, ma.dy, h / 2).compareTo(_depth(mb.dx, mb.dy, h / 2));
    });

    for (final i in sorted) {
      final wall = walls[i];
      final dir = _wallDir(wall);
      final thick = 0.06;

      final sx = wall.start.dx + dir.nx * thick;
      final sy = wall.start.dy + dir.ny * thick;
      final ex = wall.end.dx + dir.nx * thick;
      final ey = wall.end.dy + dir.ny * thick;

      final bl = _p(sx, sy, 0, ppm, c);
      final br = _p(ex, ey, 0, ppm, c);
      final tl = _p(sx, sy, h, ppm, c);
      final tr = _p(ex, ey, h, ppm, c);

      final wallPath = Path()
        ..moveTo(bl.dx, bl.dy)
        ..lineTo(br.dx, br.dy)
        ..lineTo(tr.dx, tr.dy)
        ..lineTo(tl.dx, tl.dy)
        ..close();

      canvas.drawPath(wallPath, Paint()..color = _wallColor(i));
      canvas.drawPath(wallPath, Paint()..color = _wallStroke..style = PaintingStyle.stroke..strokeWidth = 0.6);

      final oBl = _p(wall.start.dx, wall.start.dy, h, ppm, c);
      final oBr = _p(wall.end.dx, wall.end.dy, h, ppm, c);
      canvas.drawLine(oBl, oBr, Paint()..color = _wallStroke.withValues(alpha: 0.3)..strokeWidth = 0.4);
    }
  }

  void _drawDoor(Canvas canvas, Door door, double ppm, Offset c) {
    final walls = floorPlan.walls;
    if (door.wallIndex >= walls.length) return;
    final wall = walls[door.wallIndex];
    final dir = _wallDir(wall);
    final thick = 0.065;

    final pos = door.positionAlongWall;
    final halfW = door.width / wall.length / 2;
    final l = (pos - halfW).clamp(0.0, 1.0);
    final r = (pos + halfW).clamp(0.0, 1.0);

    final pts = [
      _p(wall.start.dx + (wall.end.dx - wall.start.dx) * l + dir.nx * thick,
         wall.start.dy + (wall.end.dy - wall.start.dy) * l + dir.ny * thick, 0.01, ppm, c),
      _p(wall.start.dx + (wall.end.dx - wall.start.dx) * r + dir.nx * thick,
         wall.start.dy + (wall.end.dy - wall.start.dy) * r + dir.ny * thick, 0.01, ppm, c),
      _p(wall.start.dx + (wall.end.dx - wall.start.dx) * r + dir.nx * thick,
         wall.start.dy + (wall.end.dy - wall.start.dy) * r + dir.ny * thick, door.height, ppm, c),
      _p(wall.start.dx + (wall.end.dx - wall.start.dx) * l + dir.nx * thick,
         wall.start.dy + (wall.end.dy - wall.start.dy) * l + dir.ny * thick, door.height, ppm, c),
    ];

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
    path.close();

    canvas.drawPath(path, Paint()..color = _doorFill(door.wallIndex));
    canvas.drawPath(path, Paint()..color = const Color(0xFF5A3E2A)..style = PaintingStyle.stroke..strokeWidth = 2.5);

    final hs = door.swing == DoorSwing.left || door.swing == DoorSwing.double ? 0.75 : 0.25;
    final hp = l + (r - l) * hs;
    final hx = wall.start.dx + (wall.end.dx - wall.start.dx) * hp + dir.nx * thick;
    final hy = wall.start.dy + (wall.end.dy - wall.start.dy) * hp + dir.ny * thick;
    canvas.drawCircle(_p(hx, hy, door.height * 0.5, ppm, c), 2.5 * scale, Paint()..color = const Color(0xFF5A3E2A).withValues(alpha: 0.7));
  }

  void _drawWindow(Canvas canvas, FloorWindow win, double ppm, Offset c) {
    final walls = floorPlan.walls;
    if (win.wallIndex >= walls.length) return;
    final wall = walls[win.wallIndex];
    final dir = _wallDir(wall);
    final thick = 0.065;

    final pos = win.positionAlongWall;
    final halfW = win.width / wall.length / 2;
    final l = (pos - halfW).clamp(0.0, 1.0);
    final r = (pos + halfW).clamp(0.0, 1.0);
    final sill = win.sillHeight;
    final top = sill + win.height;

    Offset wp(double t, double z) {
      final wx = wall.start.dx + (wall.end.dx - wall.start.dx) * t + dir.nx * thick;
      final wy = wall.start.dy + (wall.end.dy - wall.start.dy) * t + dir.ny * thick;
      return _p(wx, wy, z, ppm, c);
    }

    final glass = Path()
      ..moveTo(wp(l, sill).dx, wp(l, sill).dy)
      ..lineTo(wp(r, sill).dx, wp(r, sill).dy)
      ..lineTo(wp(r, top).dx, wp(r, top).dy)
      ..lineTo(wp(l, top).dx, wp(l, top).dy)
      ..close();

    canvas.drawPath(glass, Paint()..color = _glass);
    canvas.drawPath(glass, Paint()..color = _frame..style = PaintingStyle.stroke..strokeWidth = 2.5);

    final midH = (sill + top) / 2;
    canvas.drawLine(wp(l, midH), wp(r, midH), Paint()..color = _frame..strokeWidth = 1.2);
    final midT = (l + r) / 2;
    canvas.drawLine(wp(midT, sill), wp(midT, top), Paint()..color = _frame..strokeWidth = 1.2);

    canvas.drawLine(wp(l + (r - l) * 0.15, top - (top - sill) * 0.1), wp(l + (r - l) * 0.35, sill + (top - sill) * 0.1),
        Paint()..color = Colors.white.withValues(alpha: 0.25)..strokeWidth = 1.5);
  }

  void _drawOutlet(Canvas canvas, Outlet outlet, double ppm, Offset c) {
    final walls = floorPlan.walls;
    if (outlet.wallIndex >= walls.length) return;
    final wall = walls[outlet.wallIndex];
    final dir = _wallDir(wall);
    final thick = 0.07;

    final pos = outlet.positionAlongWall;
    final wx = wall.start.dx + (wall.end.dx - wall.start.dx) * pos + dir.nx * thick;
    final wy = wall.start.dy + (wall.end.dy - wall.start.dy) * pos + dir.ny * thick;
    final h = outlet.heightFromFloor;

    final color = switch (outlet.type) {
      OutletType.power => const Color(0xFFE8A317),
      OutletType.data => const Color(0xFF4A90D9),
      OutletType.hdmi => const Color(0xFF2C2C2C),
      OutletType.usb => const Color(0xFF4CAF50),
      OutletType.coax => const Color(0xFF7B68EE),
    };

    final center = _p(wx, wy, h, ppm, c);
    final r = 4.0 * scale;
    canvas.drawOval(Rect.fromCenter(center: center, width: r * 2, height: r * 2.4), Paint()..color = const Color(0xFFF5F5F0));
    canvas.drawOval(Rect.fromCenter(center: center, width: r * 2, height: r * 2.4),
        Paint()..color = color.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  void _drawGrid(Canvas canvas, double ppm, Offset c) {
    final p = Paint()..color = const Color(0x1A808080)..strokeWidth = 0.5;
    final s = (max(floorPlan.roomWidth, floorPlan.roomDepth) / 2 + 1.5).ceilToDouble();
    for (double i = -s; i <= s; i += 0.5) {
      canvas.drawLine(_p(i, -s, 0, ppm, c), _p(i, s, 0, ppm, c), p);
      canvas.drawLine(_p(-s, i, 0, ppm, c), _p(s, i, 0, ppm, c), p);
    }
  }

  void _drawLabels(Canvas canvas, double ppm, Offset c) {
    final h = floorPlan.ceilingHeight;
    for (final w in floorPlan.walls) {
      if (w.length < 0.5) continue;
      final sp = _p(w.midpoint.dx, w.midpoint.dy, h + 0.15, ppm, c);
      final tp = TextPainter(
        text: TextSpan(text: '${w.length.toStringAsFixed(1)}m', style: TextStyle(color: _wallStroke, fontSize: 9, fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sp.dx - tp.width / 2, sp.dy - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant IsometricRoomPainter o) =>
      o.floorPlan != floorPlan || o.rotationY != rotationY || o.rotationX != rotationX ||
      o.scale != scale || o.offsetX != offsetX || o.offsetY != offsetY || o.palette != palette;
}

class _WallDir {
  final double nx, ny;
  const _WallDir(this.nx, this.ny);
}
