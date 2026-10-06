import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:itfits/core/models/floor_plan_data.dart';

FloorPlanData addWallLikeSpec(FloorPlanData plan) {
  final top = plan.splitWall(0, 0.5);
  final a = plan.walls[top].start;
  final rightIdx = plan.walls.indexWhere(
      (w) => w.start == const Offset(4, 0) && w.end == const Offset(4, 3.5));
  final r2 = plan.splitWall(rightIdx, 0.5);
  final b = plan.walls[r2].start;
  plan.walls.add(WallSegment(start: a, end: b, isExternal: false));
  return plan;
}

void main() {
  group('directions', () {
    test('default room: top is North, right East, bottom South, left West', () {
      final plan = FloorPlanData.defaultRoom();
      expect(List.generate(4, plan.wallDirection),
          ['North', 'East', 'South', 'West']);
      expect(plan.wallIndexForDirection('south'), 2);
    });

    test('reversed winding gives the same compass names', () {
      final plan = FloorPlanData(walls: [
        const WallSegment(start: Offset(0, 0), end: Offset(0, 3)),
        const WallSegment(start: Offset(0, 3), end: Offset(4, 3)),
        const WallSegment(start: Offset(4, 3), end: Offset(4, 0)),
        const WallSegment(start: Offset(4, 0), end: Offset(0, 0)),
      ]);
      expect(List.generate(4, plan.wallDirection),
          ['West', 'South', 'East', 'North']);
    });
  });

  group('spec: add then delete a wall', () {
    test('deleting the new wall merges the split corners back', () {
      final plan = addWallLikeSpec(FloorPlanData.defaultRoom());
      expect(plan.walls.length, 7);
      plan.deleteWall(plan.walls.length - 1);
      expect(plan.walls.length, 4);
      final pts = plan.outline;
      expect(pts.length, 4);
      for (final p in [
        const Offset(0, 0),
        const Offset(4, 0),
        const Offset(4, 3.5),
        const Offset(0, 3.5),
      ]) {
        expect(pts.any((q) => (q - p).distance < 1e-6), isTrue, reason: '$p');
      }
    });

    test('elements keep their real position through split and merge', () {
      final plan = FloorPlanData.defaultRoom();
      plan.doors.add(const Door(positionAlongWall: 0.75, wallIndex: 0));
      plan.windows.add(const FloorWindow(positionAlongWall: 0.25, wallIndex: 0));
      plan.outlets.add(const Outlet(positionAlongWall: 0.5, wallIndex: 2));
      Offset at(int wall, double pos) => plan.walls[wall].getPointAtPosition(pos);
      final doorPt = at(0, 0.75), winPt = at(0, 0.25), outPt = at(2, 0.5);

      addWallLikeSpec(plan);
      expect((at(plan.doors[0].wallIndex, plan.doors[0].positionAlongWall) - doorPt).distance,
          lessThan(1e-9));
      expect((at(plan.windows[0].wallIndex, plan.windows[0].positionAlongWall) - winPt).distance,
          lessThan(1e-9));
      expect((at(plan.outlets[0].wallIndex, plan.outlets[0].positionAlongWall) - outPt).distance,
          lessThan(1e-9));

      plan.deleteWall(plan.walls.length - 1);
      expect((at(plan.doors[0].wallIndex, plan.doors[0].positionAlongWall) - doorPt).distance,
          lessThan(1e-9));
      expect((at(plan.windows[0].wallIndex, plan.windows[0].positionAlongWall) - winPt).distance,
          lessThan(1e-9));
      expect((at(plan.outlets[0].wallIndex, plan.outlets[0].positionAlongWall) - outPt).distance,
          lessThan(1e-9));
    });

    test('merging two walls that point at each other keeps orientation', () {
      final plan = FloorPlanData(walls: [
        const WallSegment(start: Offset(0, 0), end: Offset(2, 0)),
        const WallSegment(start: Offset(4, 0), end: Offset(2, 0)),
      ], doors: [
        const Door(positionAlongWall: 0.5, wallIndex: 1),
      ]);
      final door = plan.walls[1].getPointAtPosition(0.5);
      expect(plan.mergeAt(const Offset(2, 0)), isTrue);
      expect(plan.walls.length, 1);
      expect(plan.walls[0].start, const Offset(0, 0));
      expect(plan.walls[0].end, const Offset(4, 0));
      final d = plan.doors.single;
      expect((plan.walls[d.wallIndex].getPointAtPosition(d.positionAlongWall) - door).distance,
          lessThan(1e-9));
    });

    test('a corner is not merged when walls are not collinear', () {
      final plan = FloorPlanData.defaultRoom();
      expect(plan.mergeAt(const Offset(4, 0)), isFalse);
      expect(plan.walls.length, 4);
    });

    test('deleting a wall drops only its elements and reindexes the rest', () {
      final plan = FloorPlanData.defaultRoom();
      plan.doors.add(const Door(positionAlongWall: 0.5, wallIndex: 1));
      plan.windows.add(const FloorWindow(positionAlongWall: 0.5, wallIndex: 3));
      plan.deleteWall(1);
      expect(plan.doors, isEmpty);
      expect(plan.windows.single.wallIndex, 2);
    });
  });

  group('outline', () {
    test('interior walls do not distort the floor polygon', () {
      final plan = addWallLikeSpec(FloorPlanData.defaultRoom());
      final pts = plan.outline;
      expect(pts.length, 6);
      expect(pts.any((p) => (p - const Offset(2, 0)).distance < 1e-9), isTrue);
      expect(plan.centroid.dx, closeTo(2, 1e-9));
      expect(plan.centroid.dy, closeTo(1.75, 1e-9));
    });
  });

  group('resize', () {
    test('keeps doors, windows and outlets', () {
      final plan = FloorPlanData.defaultRoom();
      plan.doors.add(const Door(positionAlongWall: 0.5, wallIndex: 0));
      plan.resizeTo(6, 5);
      expect(plan.roomWidth, closeTo(6, 1e-9));
      expect(plan.roomDepth, closeTo(5, 1e-9));
      expect(plan.doors.length, 1);
      expect(plan.walls[1].end, const Offset(6, 5));
    });
  });

  group('json', () {
    test('accepts whole numbers stored as int', () {
      final raw = jsonDecode(jsonEncode({
        'roomWidth': 4,
        'roomDepth': 3,
        'walls': [
          {'startX': 0, 'startY': 0, 'endX': 4, 'endY': 0, 'isExternal': true},
        ],
        'doors': [
          {'positionAlongWall': 1, 'wallIndex': 0},
        ],
      })) as Map<String, dynamic>;
      final plan = FloorPlanData.fromJson(raw);
      expect(plan.walls.single.end, const Offset(4, 0));
      expect(plan.doors.single.positionAlongWall, 1.0);
    });
  });

  group('clampPosition', () {
    test('keeps the whole opening on the wall', () {
      final plan = FloorPlanData.defaultRoom();
      expect(plan.clampPosition(0, 0.99, 1.0), closeTo(1 - 0.5 / 4, 1e-9));
      expect(plan.clampPosition(0, 0.0, 1.0), closeTo(0.5 / 4, 1e-9));
    });
  });
}
