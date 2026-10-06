import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itfits/core/models/floor_plan_data.dart';
import 'package:itfits/core/services/providers.dart';
import 'package:itfits/features/create/presentation/isometric_explorer_screen.dart';
import 'package:itfits/features/create/presentation/isometric_room_painter.dart';

FloorPlanData richPlan() {
  final plan = FloorPlanData.defaultRoom();
  final top = plan.splitWall(0, 0.5);
  plan.walls.add(WallSegment(
      start: plan.walls[top].start, end: const Offset(2, 3.5), isExternal: false));
  plan.doors.add(const Door(positionAlongWall: 0.5, wallIndex: 1));
  plan.windows.add(const FloorWindow(positionAlongWall: 0.5, wallIndex: 3));
  plan.outlets.add(const Outlet(positionAlongWall: 0.3, wallIndex: 4));
  return plan;
}

void main() {
  test('3D painter paints every camera angle without throwing', () {
    final plan = richPlan();
    for (final ry in [0.0, 0.785, 2.0, 3.6, 5.5]) {
      for (final rx in [0.1, 0.523, 1.45]) {
        final recorder = ui.PictureRecorder();
        IsometricRoomPainter(floorPlan: plan, rotationY: ry, rotationX: rx)
            .paint(Canvas(recorder), const Size(400, 600));
        recorder.endRecording();
      }
    }
  });

  testWidgets('3D explorer builds and handles rotate and pinch', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [floorPlanDataProvider.overrideWith((ref) => richPlan())],
      child: MaterialApp(
        home: IsometricExplorerScreen(onComplete: () {}),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);

    final center = tester.getCenter(find.byType(CustomPaint).first);
    await tester.dragFrom(center, const Offset(80, 40));
    await tester.pump();

    final a = await tester.startGesture(center - const Offset(30, 0));
    final b = await tester.startGesture(center + const Offset(30, 0));
    await a.moveBy(const Offset(-40, 0));
    await b.moveBy(const Offset(40, 0));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
