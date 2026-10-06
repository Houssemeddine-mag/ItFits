import 'package:flutter/material.dart';

import '../models/floor_plan_data.dart' as editor;
import '../models/project_model.dart' as model;

/// Metadata for one step of the creation wizard, in wizard order.
class CreationStageInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final model.ProjectStatus status;

  const CreationStageInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
  });
}

/// The 7 wizard steps (mirrors CreateScreen._steps) with the
/// [model.ProjectStatus] that marks each step as reached.
const List<CreationStageInfo> creationStages = [
  CreationStageInfo(
    title: 'Capture',
    subtitle: 'Scan your space',
    icon: Icons.camera_alt_outlined,
    status: model.ProjectStatus.scanning,
  ),
  CreationStageInfo(
    title: '360 View',
    subtitle: 'Review panorama',
    icon: Icons.view_in_ar_outlined,
    status: model.ProjectStatus.processing,
  ),
  CreationStageInfo(
    title: 'Floor Plan',
    subtitle: 'Draw walls, doors & layout',
    icon: Icons.architecture_outlined,
    status: model.ProjectStatus.reviewingPlan,
  ),
  CreationStageInfo(
    title: 'Style',
    subtitle: 'Choose aesthetic & colors',
    icon: Icons.palette_outlined,
    status: model.ProjectStatus.styling,
  ),
  CreationStageInfo(
    title: 'AI Designer',
    subtitle: 'Chat with your designer',
    icon: Icons.auto_awesome_outlined,
    status: model.ProjectStatus.generating,
  ),
  CreationStageInfo(
    title: 'Generate',
    subtitle: 'Create your redesign',
    icon: Icons.auto_awesome,
    status: model.ProjectStatus.generating,
  ),
  CreationStageInfo(
    title: 'Result',
    subtitle: 'Your redesigned room',
    icon: Icons.check_circle_outline,
    status: model.ProjectStatus.complete,
  ),
];

/// Wizard step index to resume at for a persisted [status].
/// Points at the first step the user still has to do.
int stepIndexForStatus(model.ProjectStatus status) {
  switch (status) {
    case model.ProjectStatus.scanning:
      return 1; // Scan saved → review the 360.
    case model.ProjectStatus.processing:
      return 2; // 360 reviewed → draw floor plan.
    case model.ProjectStatus.reviewingPlan:
      return 3; // Plan saved → pick a style.
    case model.ProjectStatus.styling:
      return 4; // Style saved → AI chat.
    case model.ProjectStatus.generating:
      return 5; // Chat done → generate.
    case model.ProjectStatus.complete:
      return 6; // Finished → result.
    case model.ProjectStatus.failed:
      return 5; // Retry generation.
  }
}

/// Whether the project finished the whole flow.
bool isProjectComplete(model.ProjectModel project) =>
    project.status == model.ProjectStatus.complete;

/// Short human-readable stage label, e.g. "Step 3/7 · Floor Plan".
String stageLabelFor(model.ProjectModel project) {
  if (isProjectComplete(project)) return 'Complete';
  final step =
      stepIndexForStatus(project.status).clamp(0, creationStages.length - 1);
  return 'Step ${step + 1}/${creationStages.length} · ${creationStages[step].title}';
}

// ---------------------------------------------------------------------------
// editor.FloorPlanData <-> model.FloorPlanModel mappers.
// The persisted model is a subset: outlets, door heights and sill heights
// are editor-only and fall back to defaults on restore.
// ---------------------------------------------------------------------------

model.DoorType _doorTypeFromSwing(editor.DoorSwing swing) {
  switch (swing) {
    case editor.DoorSwing.sliding:
      return model.DoorType.sliding;
    case editor.DoorSwing.left:
    case editor.DoorSwing.right:
    case editor.DoorSwing.double:
      return model.DoorType.hinged;
  }
}

editor.DoorSwing _swingFromDoorType(model.DoorType type) {
  switch (type) {
    case model.DoorType.sliding:
      return editor.DoorSwing.sliding;
    case model.DoorType.hinged:
      return editor.DoorSwing.right;
    case model.DoorType.pocket:
      return editor.DoorSwing.sliding;
    case model.DoorType.bifold:
      return editor.DoorSwing.double;
  }
}

model.WindowType _windowModelTypeFromData(editor.WindowType type) {
  switch (type) {
    case editor.WindowType.standard:
      return model.WindowType.casement;
    case editor.WindowType.bay:
      return model.WindowType.bay;
    case editor.WindowType.sliding:
      return model.WindowType.sliding;
    case editor.WindowType.floorToCeiling:
      return model.WindowType.fixed;
    case editor.WindowType.arched:
      return model.WindowType.casement;
  }
}

editor.WindowType _dataWindowTypeFromModel(model.WindowType type) {
  switch (type) {
    case model.WindowType.sliding:
      return editor.WindowType.sliding;
    case model.WindowType.bay:
      return editor.WindowType.bay;
    case model.WindowType.fixed:
      return editor.WindowType.floorToCeiling;
    case model.WindowType.casement:
    case model.WindowType.doubleHung:
      return editor.WindowType.standard;
  }
}

/// Editor state -> persistable model (call when leaving the floor-plan step).
model.FloorPlanModel floorPlanModelFromData(editor.FloorPlanData data) {
  final walls = <model.WallModel>[];
  for (var i = 0; i < data.walls.length; i++) {
    final w = data.walls[i];
    walls.add(model.WallModel(
      id: 'wall_$i',
      start: model.Point(x: w.start.dx, y: w.start.dy),
      end: model.Point(x: w.end.dx, y: w.end.dy),
      thickness: 0.15,
      isExternal: w.isExternal,
    ));
  }
  final doors = <model.DoorModel>[];
  for (var i = 0; i < data.doors.length; i++) {
    final d = data.doors[i];
    doors.add(model.DoorModel(
      id: 'door_$i',
      wallId: 'wall_${d.wallIndex}',
      position: d.positionAlongWall,
      width: d.width,
      type: _doorTypeFromSwing(d.swing),
    ));
  }
  final windows = <model.WindowModel>[];
  for (var i = 0; i < data.windows.length; i++) {
    final w = data.windows[i];
    windows.add(model.WindowModel(
      id: 'window_$i',
      wallId: 'wall_${w.wallIndex}',
      position: w.positionAlongWall,
      width: w.width,
      height: w.height,
      type: _windowModelTypeFromData(w.type),
    ));
  }
  return model.FloorPlanModel(
    walls: walls,
    doors: doors,
    windows: windows,
    dimensions: model.DimensionsModel(
      width: data.roomWidth,
      height: data.roomDepth,
      area: data.roomWidth * data.roomDepth,
    ),
    isUserEdited: true,
  );
}

int _wallIndexFromId(String wallId, int wallCount) {
  if (wallCount <= 0) return 0;
  final idx = int.tryParse(wallId.replaceFirst('wall_', '')) ?? 0;
  return idx.clamp(0, wallCount - 1);
}

/// Persisted model -> editor state (used when resuming an unfinished project).
editor.FloorPlanData floorPlanDataFromModel(model.FloorPlanModel plan) {
  final walls = plan.walls
      .map((w) => editor.WallSegment(
            start: Offset(w.start.x, w.start.y),
            end: Offset(w.end.x, w.end.y),
            isExternal: w.isExternal,
          ))
      .toList();
  final doors = plan.doors
      .map((d) => editor.Door(
            positionAlongWall: d.position.clamp(0.05, 0.95),
            width: d.width,
            height: 2.1,
            swing: _swingFromDoorType(d.type),
            wallIndex: _wallIndexFromId(d.wallId, walls.length),
          ))
      .toList();
  final windows = plan.windows
      .map((w) => editor.FloorWindow(
            positionAlongWall: w.position.clamp(0.05, 0.95),
            width: w.width,
            height: w.height,
            sillHeight: 0.9,
            type: _dataWindowTypeFromModel(w.type),
            wallIndex: _wallIndexFromId(w.wallId, walls.length),
          ))
      .toList();
  return editor.FloorPlanData(
    roomWidth: plan.dimensions.width.clamp(1.0, 50.0),
    roomDepth: plan.dimensions.height.clamp(1.0, 50.0),
    walls: walls,
    doors: doors,
    windows: windows,
  );
}
