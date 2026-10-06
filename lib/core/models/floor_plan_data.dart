import 'dart:math';
import 'dart:ui';

enum DoorSwing { left, right, double, sliding }

enum WindowType { standard, bay, sliding, floorToCeiling, arched }

enum OutletType { power, data, coax, usb, hdmi }

class WallSegment {
  final Offset start;
  final Offset end;
  final bool isExternal;
  final Offset? controlPoint;

  const WallSegment({
    required this.start,
    required this.end,
    this.isExternal = true,
    this.controlPoint,
  });

  double get length => (end - start).distance;

  double get angle => atan2(end.dy - start.dy, end.dx - start.dx);

  Offset get midpoint => Offset(
    (start.dx + end.dx) / 2,
    (start.dy + end.dy) / 2,
  );

  Offset get normal {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len == 0) return Offset.zero;
    return Offset(-dy / len, dx / len);
  }

  double positionToOffset(double position, double totalLength) {
    return position * totalLength;
  }

  Offset getPointAtPosition(double position) {
    return Offset(
      start.dx + (end.dx - start.dx) * position,
      start.dy + (end.dy - start.dy) * position,
    );
  }

  WallSegment copyWith({
    Offset? start,
    Offset? end,
    bool? isExternal,
    Offset? controlPoint,
    bool clearControlPoint = false,
  }) {
    return WallSegment(
      start: start ?? this.start,
      end: end ?? this.end,
      isExternal: isExternal ?? this.isExternal,
      controlPoint: clearControlPoint ? null : (controlPoint ?? this.controlPoint),
    );
  }

  Map<String, dynamic> toJson() => {
    'startX': start.dx,
    'startY': start.dy,
    'endX': end.dx,
    'endY': end.dy,
    'isExternal': isExternal,
    if (controlPoint != null) ...{
      'controlX': controlPoint!.dx,
      'controlY': controlPoint!.dy,
    },
  };

  factory WallSegment.fromJson(Map<String, dynamic> json) => WallSegment(
    start: Offset(_d(json['startX']), _d(json['startY'])),
    end: Offset(_d(json['endX']), _d(json['endY'])),
    isExternal: json['isExternal'] as bool? ?? true,
    controlPoint: json['controlX'] != null
        ? Offset(_d(json['controlX']), _d(json['controlY']))
        : null,
  );
}

double _d(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : fallback;

class Door {
  final double positionAlongWall;
  final double width;
  final double height;
  final DoorSwing swing;
  final int wallIndex;

  const Door({
    required this.positionAlongWall,
    this.width = 0.9,
    this.height = 2.1,
    this.swing = DoorSwing.right,
    required this.wallIndex,
  });

  Door copyWith({double? positionAlongWall, int? wallIndex}) => Door(
    positionAlongWall: positionAlongWall ?? this.positionAlongWall,
    width: width,
    height: height,
    swing: swing,
    wallIndex: wallIndex ?? this.wallIndex,
  );

  Map<String, dynamic> toJson() => {
    'positionAlongWall': positionAlongWall,
    'width': width,
    'height': height,
    'swing': swing.index,
    'wallIndex': wallIndex,
  };

  factory Door.fromJson(Map<String, dynamic> json) => Door(
    positionAlongWall: _d(json['positionAlongWall'], 0.5),
    width: (json['width'] as num?)?.toDouble() ?? 0.9,
    height: (json['height'] as num?)?.toDouble() ?? 2.1,
    swing: DoorSwing.values[json['swing'] as int? ?? 1],
    wallIndex: (json['wallIndex'] as num? ?? 0).toInt(),
  );
}

class FloorWindow {
  final double positionAlongWall;
  final double width;
  final double height;
  final double sillHeight;
  final WindowType type;
  final int wallIndex;

  const FloorWindow({
    required this.positionAlongWall,
    this.width = 1.2,
    this.height = 1.2,
    this.sillHeight = 0.9,
    this.type = WindowType.standard,
    required this.wallIndex,
  });

  FloorWindow copyWith({double? positionAlongWall, int? wallIndex}) =>
      FloorWindow(
        positionAlongWall: positionAlongWall ?? this.positionAlongWall,
        width: width,
        height: height,
        sillHeight: sillHeight,
        type: type,
        wallIndex: wallIndex ?? this.wallIndex,
      );

  Map<String, dynamic> toJson() => {
    'positionAlongWall': positionAlongWall,
    'width': width,
    'height': height,
    'sillHeight': sillHeight,
    'type': type.index,
    'wallIndex': wallIndex,
  };

  factory FloorWindow.fromJson(Map<String, dynamic> json) => FloorWindow(
    positionAlongWall: _d(json['positionAlongWall'], 0.5),
    width: (json['width'] as num?)?.toDouble() ?? 1.2,
    height: (json['height'] as num?)?.toDouble() ?? 1.2,
    sillHeight: (json['sillHeight'] as num?)?.toDouble() ?? 0.9,
    type: WindowType.values[json['type'] as int? ?? 0],
    wallIndex: (json['wallIndex'] as num? ?? 0).toInt(),
  );
}

class Outlet {
  final double positionAlongWall;
  final OutletType type;
  final double heightFromFloor;
  final int wallIndex;

  const Outlet({
    required this.positionAlongWall,
    this.type = OutletType.power,
    this.heightFromFloor = 0.3,
    required this.wallIndex,
  });

  Outlet copyWith({double? positionAlongWall, int? wallIndex}) => Outlet(
    positionAlongWall: positionAlongWall ?? this.positionAlongWall,
    type: type,
    heightFromFloor: heightFromFloor,
    wallIndex: wallIndex ?? this.wallIndex,
  );

  Map<String, dynamic> toJson() => {
    'positionAlongWall': positionAlongWall,
    'type': type.index,
    'heightFromFloor': heightFromFloor,
    'wallIndex': wallIndex,
  };

  factory Outlet.fromJson(Map<String, dynamic> json) => Outlet(
    positionAlongWall: _d(json['positionAlongWall'], 0.5),
    type: OutletType.values[json['type'] as int? ?? 0],
    heightFromFloor: (json['heightFromFloor'] as num?)?.toDouble() ?? 0.3,
    wallIndex: (json['wallIndex'] as num? ?? 0).toInt(),
  );
}

class FloorPlanData {
  double roomWidth;
  double roomDepth;
  double ceilingHeight;
  final List<WallSegment> walls;
  final List<Door> doors;
  final List<FloorWindow> windows;
  final List<Outlet> outlets;

  FloorPlanData({
    this.roomWidth = 4.0,
    this.roomDepth = 3.5,
    this.ceilingHeight = 2.7,
    List<WallSegment>? walls,
    List<Door>? doors,
    List<FloorWindow>? windows,
    List<Outlet>? outlets,
  })  : walls = walls ?? [],
        doors = doors ?? [],
        windows = windows ?? [],
        outlets = outlets ?? [];

  double get area => roomWidth * roomDepth;

  static const double _eps = 1e-3;

  static bool samePoint(Offset a, Offset b) => (a - b).distance < _eps;

  Rect get bounds {
    if (walls.isEmpty) return Rect.fromLTWH(0, 0, roomWidth, roomDepth);
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final w in walls) {
      for (final p in [w.start, w.end]) {
        minX = min(minX, p.dx);
        minY = min(minY, p.dy);
        maxX = max(maxX, p.dx);
        maxY = max(maxY, p.dy);
      }
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void updateBounds() {
    final b = bounds;
    roomWidth = max(0.5, b.width);
    roomDepth = max(0.5, b.height);
  }

  List<Offset> get outline {
    final ext = walls.where((w) => w.isExternal).toList();
    if (ext.length < 3) return walls.map((w) => w.start).toList();
    final used = List<bool>.filled(ext.length, false);
    used[0] = true;
    final pts = <Offset>[ext.first.start];
    var tip = ext.first.end;
    for (var step = 1; step < ext.length; step++) {
      var found = false;
      for (var k = 0; k < ext.length && !found; k++) {
        if (used[k]) continue;
        if (samePoint(ext[k].start, tip)) {
          pts.add(ext[k].start);
          tip = ext[k].end;
        } else if (samePoint(ext[k].end, tip)) {
          pts.add(ext[k].end);
          tip = ext[k].start;
        } else {
          continue;
        }
        used[k] = true;
        found = true;
      }
      if (!found) break;
    }
    return pts;
  }

  Offset get centroid {
    final pts = outline;
    if (pts.length < 3) return bounds.center;
    var a = 0.0, cx = 0.0, cy = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i], q = pts[(i + 1) % pts.length];
      final cross = p.dx * q.dy - q.dx * p.dy;
      a += cross;
      cx += (p.dx + q.dx) * cross;
      cy += (p.dy + q.dy) * cross;
    }
    if (a.abs() < 1e-9) return bounds.center;
    return Offset(cx / (3 * a), cy / (3 * a));
  }

  Offset inwardNormal(int i) {
    final w = walls[i];
    final n = w.normal;
    final toCenter = centroid - w.midpoint;
    return (n.dx * toCenter.dx + n.dy * toCenter.dy) >= 0 ? n : -n;
  }

  String wallDirection(int i) {
    if (i < 0 || i >= walls.length) return 'Unknown';
    if (!walls[i].isExternal) return 'Interior';
    final out = -inwardNormal(i);
    if (out.dx.abs() >= out.dy.abs()) return out.dx > 0 ? 'East' : 'West';
    return out.dy < 0 ? 'North' : 'South';
  }

  int? wallIndexForDirection(String direction) {
    final d = direction.toLowerCase();
    int? best;
    var bestLen = -1.0;
    for (var i = 0; i < walls.length; i++) {
      if (wallDirection(i).toLowerCase() == d && walls[i].length > bestLen) {
        best = i;
        bestLen = walls[i].length;
      }
    }
    return best;
  }

  double clampPosition(int wallIndex, double t, double elementWidth) {
    final len = walls[wallIndex].length;
    if (len <= 0) return 0.5;
    final half = (elementWidth / 2) / len;
    if (half >= 0.5) return 0.5;
    return t.clamp(half, 1 - half);
  }

  void _remapElements(({int wall, double pos})? Function(int wall, double pos) map) {
    for (var i = doors.length - 1; i >= 0; i--) {
      final r = map(doors[i].wallIndex, doors[i].positionAlongWall);
      if (r == null) {
        doors.removeAt(i);
      } else {
        doors[i] = doors[i].copyWith(wallIndex: r.wall, positionAlongWall: r.pos);
      }
    }
    for (var i = windows.length - 1; i >= 0; i--) {
      final r = map(windows[i].wallIndex, windows[i].positionAlongWall);
      if (r == null) {
        windows.removeAt(i);
      } else {
        windows[i] = windows[i].copyWith(wallIndex: r.wall, positionAlongWall: r.pos);
      }
    }
    for (var i = outlets.length - 1; i >= 0; i--) {
      final r = map(outlets[i].wallIndex, outlets[i].positionAlongWall);
      if (r == null) {
        outlets.removeAt(i);
      } else {
        outlets[i] = outlets[i].copyWith(wallIndex: r.wall, positionAlongWall: r.pos);
      }
    }
  }

  int splitWall(int index, double t) {
    final wall = walls[index];
    final p = wall.getPointAtPosition(t);
    walls[index] = WallSegment(start: wall.start, end: p, isExternal: wall.isExternal);
    walls.insert(index + 1, WallSegment(start: p, end: wall.end, isExternal: wall.isExternal));
    _remapElements((w, pos) {
      if (w < index) return (wall: w, pos: pos);
      if (w > index) return (wall: w + 1, pos: pos);
      return pos < t
          ? (wall: index, pos: pos / t)
          : (wall: index + 1, pos: (pos - t) / (1 - t));
    });
    return index + 1;
  }

  bool mergeAt(Offset point) {
    final at = <int>[];
    for (var i = 0; i < walls.length; i++) {
      if (samePoint(walls[i].start, point) || samePoint(walls[i].end, point)) {
        at.add(i);
      }
    }
    if (at.length != 2) return false;
    var ia = at[0], ib = at[1];
    var a = walls[ia], b = walls[ib];
    if (a.isExternal != b.isExternal) return false;
    if (a.length < _eps || b.length < _eps) return false;
    final da = (a.end - a.start) / a.length;
    final db = (b.end - b.start) / b.length;
    if ((da.dx * db.dy - da.dy * db.dx).abs() > 0.02) return false;

    var flipA = false, flipB = false;
    if (samePoint(b.end, point) && samePoint(a.start, point)) {
      final t = ia; ia = ib; ib = t;
      final w = a; a = b; b = w;
    } else if (samePoint(a.start, point) && samePoint(b.start, point)) {
      flipA = true;
    } else if (samePoint(a.end, point) && samePoint(b.end, point)) {
      flipB = true;
    }
    final aStart = flipA ? a.end : a.start;
    final bEnd = flipB ? b.start : b.end;
    final merged = WallSegment(start: aStart, end: bEnd, isExternal: a.isExternal);
    final total = merged.length;
    final fa = a.length / total;

    final keep = min(ia, ib), drop = max(ia, ib);
    walls[keep] = merged;
    walls.removeAt(drop);
    _remapElements((w, pos) {
      if (w == ia) {
        final p = flipA ? 1 - pos : pos;
        return (wall: keep, pos: p * fa);
      }
      if (w == ib) {
        final p = flipB ? 1 - pos : pos;
        return (wall: keep, pos: fa + p * (1 - fa));
      }
      return (wall: w > drop ? w - 1 : w, pos: pos);
    });
    return true;
  }

  void deleteWall(int index) {
    final wall = walls[index];
    walls.removeAt(index);
    _remapElements((w, pos) {
      if (w == index) return null;
      return (wall: w > index ? w - 1 : w, pos: pos);
    });
    mergeAt(wall.start);
    mergeAt(wall.end);
    updateBounds();
  }

  void moveCorner(Offset from, Offset to) {
    for (var i = 0; i < walls.length; i++) {
      final w = walls[i];
      if (samePoint(w.start, from)) walls[i] = w.copyWith(start: to);
      if (samePoint(walls[i].end, from)) walls[i] = walls[i].copyWith(end: to);
    }
  }

  void resizeTo(double width, double depth) {
    if (walls.isEmpty) {
      roomWidth = width;
      roomDepth = depth;
      return;
    }
    final b = bounds;
    final sx = b.width > _eps ? width / b.width : 1.0;
    final sy = b.height > _eps ? depth / b.height : 1.0;
    Offset s(Offset p) =>
        Offset(b.left + (p.dx - b.left) * sx, b.top + (p.dy - b.top) * sy);
    for (var i = 0; i < walls.length; i++) {
      final w = walls[i];
      walls[i] = WallSegment(
        start: s(w.start),
        end: s(w.end),
        isExternal: w.isExternal,
        controlPoint: w.controlPoint == null ? null : s(w.controlPoint!),
      );
    }
    updateBounds();
  }

  static FloorPlanData defaultRoom() {
    return FloorPlanData(
      roomWidth: 4.0,
      roomDepth: 3.5,
      walls: [
        const WallSegment(
          start: Offset(0, 0),
          end: Offset(4.0, 0),
          isExternal: true,
        ),
        const WallSegment(
          start: Offset(4.0, 0),
          end: Offset(4.0, 3.5),
          isExternal: true,
        ),
        const WallSegment(
          start: Offset(4.0, 3.5),
          end: Offset(0, 3.5),
          isExternal: true,
        ),
        const WallSegment(
          start: Offset(0, 3.5),
          end: Offset(0, 0),
          isExternal: true,
        ),
      ],
    );
  }

  String get wallDirections =>
      List.generate(walls.length, wallDirection).join(', ');

  String toPromptDescription() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Room: ${roomWidth.toStringAsFixed(1)}m × ${roomDepth.toStringAsFixed(1)}m '
      '(${area.toStringAsFixed(1)} m²), ceiling ${ceilingHeight.toStringAsFixed(1)}m.',
    );

    for (int i = 0; i < windows.length; i++) {
      final w = windows[i];
      final wallDir = _getWallDirection(w.wallIndex);
      final pos = (w.positionAlongWall * 100).round();
      final typeName = _windowTypeName(w.type);
      buffer.writeln(
        '$wallDir wall: ${typeName} ${w.width.toStringAsFixed(1)}m wide '
        'at $pos% from left corner, height ${w.height.toStringAsFixed(1)}m.',
      );
    }

    for (int i = 0; i < doors.length; i++) {
      final d = doors[i];
      final wallDir = _getWallDirection(d.wallIndex);
      final pos = (d.positionAlongWall * 100).round();
      final swingName = _doorSwingName(d.swing);
      buffer.writeln(
        '$wallDir wall: Door ${d.width.toStringAsFixed(1)}m wide '
        'at $pos% from left corner, swinging $swingName.',
      );
    }

    if (outlets.isNotEmpty) {
      final outletsByWall = <int, List<Outlet>>{};
      for (final o in outlets) {
        outletsByWall.putIfAbsent(o.wallIndex, () => []).add(o);
      }
      for (final entry in outletsByWall.entries) {
        final wallDir = _getWallDirection(entry.key);
        final count = entry.value.length;
        final typeName = _outletTypeName(entry.value.first.type);
        final positions = entry.value
            .map((o) => '${(o.positionAlongWall * 100).round()}%')
            .join(' and ');
        buffer.writeln(
          '$wallDir wall: $count $typeName outlet(s) at $positions from left corner.',
        );
      }
    }

    final solidWalls = <String>[];
    for (int i = 0; i < walls.length; i++) {
      final hasDoor = doors.any((d) => d.wallIndex == i);
      final hasWindow = windows.any((w) => w.wallIndex == i);
      if (!hasDoor && !hasWindow) {
        solidWalls.add(_getWallDirection(i));
      }
    }
    if (solidWalls.isNotEmpty) {
      buffer.writeln('${solidWalls.join(", ")} wall(s): solid, no openings.');
    }

    return buffer.toString();
  }

  String toFurnitureGuidance(String roomType) {
    final guidance = <String>[];
    final normalizedType = _normalizeRoomType(roomType);

    if (windows.isNotEmpty) {
      guidance.add(
        'Natural light enters from ${_getWallDirection(windows.first.wallIndex)} wall. '
        'Place seating/work areas to benefit from this light.',
      );
    }

    if (doors.isNotEmpty) {
      guidance.add(
        'Traffic enters from ${_getWallDirection(doors.first.wallIndex)} wall. '
        'Keep the entry path clear of furniture.',
      );
    }

    if (outlets.isNotEmpty) {
      final outletWall = _getWallDirection(outlets.first.wallIndex);
      guidance.add(
        'Power outlets on $outletWall wall. '
        'Place electronics (TV, desk, lamps) near this wall.',
      );
    }

    switch (normalizedType) {
      case 'Bedroom':
        guidance.add('Bed typically faces the door, away from windows to avoid direct light.');
        break;
      case 'Living Room':
        guidance.add('Sofa faces the focal point (TV/fireplace). Arrange around natural light.');
        break;
      case 'Kitchen':
        guidance.add('Work triangle: sink, stove, refrigerator should form efficient triangle.');
        break;
      case 'Home Office':
        guidance.add('Desk faces the door or window. Outlets are critical for equipment.');
        break;
      case 'Bathroom':
        guidance.add('Vanity near door, shower/tub on exterior wall for ventilation.');
        break;
      case 'Dining Room':
        guidance.add('Table centered under light fixture. Chairs need walking space around.');
        break;
      case 'Entryway':
        guidance.add('Console table against wall, clear path from door inward.');
        break;
    }

    return guidance.join(' ');
  }

  String _normalizeRoomType(String roomType) {
    const aliases = {
      'living_room': 'Living Room',
      'bedroom': 'Bedroom',
      'kitchen': 'Kitchen',
      'bathroom': 'Bathroom',
      'dining_room': 'Dining Room',
      'dining': 'Dining Room',
      'home_office': 'Home Office',
      'office': 'Home Office',
      'entryway': 'Entryway',
      'garden': 'Garden',
      'toilet': 'Toilet',
    };
    return aliases[roomType] ?? roomType;
  }

  String _getWallDirection(int wallIndex) => wallDirection(wallIndex);

  String _windowTypeName(WindowType type) {
    switch (type) {
      case WindowType.standard:
        return 'Standard window';
      case WindowType.bay:
        return 'Bay window';
      case WindowType.sliding:
        return 'Sliding window';
      case WindowType.floorToCeiling:
        return 'Floor-to-ceiling window';
      case WindowType.arched:
        return 'Arched window';
    }
  }

  String _doorSwingName(DoorSwing swing) {
    switch (swing) {
      case DoorSwing.left:
        return 'left';
      case DoorSwing.right:
        return 'right';
      case DoorSwing.double:
        return 'double';
      case DoorSwing.sliding:
        return 'sliding';
    }
  }

  String _outletTypeName(OutletType type) {
    switch (type) {
      case OutletType.power:
        return 'power';
      case OutletType.data:
        return 'data/network';
      case OutletType.coax:
        return 'coax/cable';
      case OutletType.usb:
        return 'USB';
      case OutletType.hdmi:
        return 'HDMI';
    }
  }

  Map<String, dynamic> toJson() => {
    'roomWidth': roomWidth,
    'roomDepth': roomDepth,
    'ceilingHeight': ceilingHeight,
    'walls': walls.map((w) => w.toJson()).toList(),
    'doors': doors.map((d) => d.toJson()).toList(),
    'windows': windows.map((w) => w.toJson()).toList(),
    'outlets': outlets.map((o) => o.toJson()).toList(),
  };

  factory FloorPlanData.fromJson(Map<String, dynamic> json) => FloorPlanData(
    roomWidth: (json['roomWidth'] as num?)?.toDouble() ?? 4.0,
    roomDepth: (json['roomDepth'] as num?)?.toDouble() ?? 3.5,
    ceilingHeight: (json['ceilingHeight'] as num?)?.toDouble() ?? 2.7,
    walls: (json['walls'] as List?)
            ?.map((w) => WallSegment.fromJson(w as Map<String, dynamic>))
            .toList() ??
        [],
    doors: (json['doors'] as List?)
            ?.map((d) => Door.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [],
    windows: (json['windows'] as List?)
            ?.map((w) => FloorWindow.fromJson(w as Map<String, dynamic>))
            .toList() ??
        [],
    outlets: (json['outlets'] as List?)
            ?.map((o) => Outlet.fromJson(o as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
