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
    start: Offset(json['startX'] as double, json['startY'] as double),
    end: Offset(json['endX'] as double, json['endY'] as double),
    isExternal: json['isExternal'] as bool? ?? true,
    controlPoint: json['controlX'] != null
        ? Offset(json['controlX'] as double, json['controlY'] as double)
        : null,
  );
}

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

  Map<String, dynamic> toJson() => {
    'positionAlongWall': positionAlongWall,
    'width': width,
    'height': height,
    'swing': swing.index,
    'wallIndex': wallIndex,
  };

  factory Door.fromJson(Map<String, dynamic> json) => Door(
    positionAlongWall: json['positionAlongWall'] as double,
    width: (json['width'] as num?)?.toDouble() ?? 0.9,
    height: (json['height'] as num?)?.toDouble() ?? 2.1,
    swing: DoorSwing.values[json['swing'] as int? ?? 1],
    wallIndex: json['wallIndex'] as int,
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

  Map<String, dynamic> toJson() => {
    'positionAlongWall': positionAlongWall,
    'width': width,
    'height': height,
    'sillHeight': sillHeight,
    'type': type.index,
    'wallIndex': wallIndex,
  };

  factory FloorWindow.fromJson(Map<String, dynamic> json) => FloorWindow(
    positionAlongWall: json['positionAlongWall'] as double,
    width: (json['width'] as num?)?.toDouble() ?? 1.2,
    height: (json['height'] as num?)?.toDouble() ?? 1.2,
    sillHeight: (json['sillHeight'] as num?)?.toDouble() ?? 0.9,
    type: WindowType.values[json['type'] as int? ?? 0],
    wallIndex: json['wallIndex'] as int,
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

  Map<String, dynamic> toJson() => {
    'positionAlongWall': positionAlongWall,
    'type': type.index,
    'heightFromFloor': heightFromFloor,
    'wallIndex': wallIndex,
  };

  factory Outlet.fromJson(Map<String, dynamic> json) => Outlet(
    positionAlongWall: json['positionAlongWall'] as double,
    type: OutletType.values[json['type'] as int? ?? 0],
    heightFromFloor: (json['heightFromFloor'] as num?)?.toDouble() ?? 0.3,
    wallIndex: json['wallIndex'] as int,
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

  String get wallDirections {
    if (walls.isEmpty) return '';
    final dirs = <String>[];
    for (int i = 0; i < walls.length; i++) {
      final w = walls[i];
      final angle = w.angle;
      if (angle.abs() < 0.1 || (angle - 2 * pi).abs() < 0.1) {
        dirs.add('South');
      } else if ((angle - pi / 2).abs() < 0.1) {
        dirs.add('West');
      } else if ((angle - pi).abs() < 0.1 || (angle + pi).abs() < 0.1) {
        dirs.add('North');
      } else if ((angle + pi / 2).abs() < 0.1 || (angle - 3 * pi / 2).abs() < 0.1) {
        dirs.add('East');
      } else {
        dirs.add('Diagonal');
      }
    }
    return dirs.join(', ');
  }

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

  String _getWallDirection(int wallIndex) {
    if (wallIndex >= walls.length) return 'Unknown';
    final angle = walls[wallIndex].angle;
    if (angle.abs() < 0.1 || (angle - 2 * pi).abs() < 0.1) return 'South';
    if ((angle - pi / 2).abs() < 0.1) return 'West';
    if ((angle - pi).abs() < 0.1 || (angle + pi).abs() < 0.1) return 'North';
    if ((angle + pi / 2).abs() < 0.1 || (angle - 3 * pi / 2).abs() < 0.1) return 'East';
    return 'Diagonal';
  }

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
