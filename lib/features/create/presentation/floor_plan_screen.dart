import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itfits/core/services/ai_proxy_service.dart';
import 'package:itfits/core/services/firestore_image_service.dart' show fitDataUrlForFirestore;

import 'package:itfits/core/models/floor_plan_data.dart';
import 'package:itfits/core/services/providers.dart';

class FloorPlanScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;
  const FloorPlanScreen({super.key, required this.onComplete, this.onBack});

  @override
  ConsumerState<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

String wallName(FloorPlanData plan, int i, {bool short = false}) {
  if (i < 0 || i >= plan.walls.length) return 'Wall ${i + 1}';
  final dir = plan.wallDirection(i);
  final same = [
    for (var k = 0; k < plan.walls.length; k++)
      if (plan.wallDirection(k) == dir) k,
  ];
  final base = short ? (dir == 'Interior' ? 'Int' : dir[0]) : dir;
  return same.length > 1 ? '$base ${same.indexOf(i) + 1}' : base;
}

enum _Mode { none, door, window, outlet, split, addWall, deleteWall }

enum _DragTarget { none, corner, element }

class _FloorPlanScreenState extends ConsumerState<FloorPlanScreen> {
  late FloorPlanData _plan;
  _Mode _mode = _Mode.none;
  bool _isAnalyzing = false;

  int? _selectedWall;
  String _selectedType = '';
  int? _selectedIdx;

  _DragTarget _dragTarget = _DragTarget.none;
  int _dragCornerWall = -1;
  bool _dragCornerIsStart = true;
  String _dragElementType = '';
  int _dragElementIdx = -1;

  Offset? _addWallCorner1;
  bool _corner1FromSplit = false;

  FloorPlanData? _originalPlan;

  Offset _origin = Offset.zero;
  double _ppm = 80;

  static const double _cornerSnapPx = 24;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(floorPlanDataProvider);
    _plan = existing != null
        ? FloorPlanData.fromJson(existing.toJson())
        : FloorPlanData.defaultRoom();
    _originalPlan = FloorPlanData.fromJson(_plan.toJson());
    if (existing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(floorPlanDataProvider.notifier).state = _plan;
        final images = ref.read(capturedImagesProvider);
        if (images.isNotEmpty) _autoDetect();
      });
    }
  }

  void _save() => ref.read(floorPlanDataProvider.notifier).state = _plan;

  Offset _worldToScreen(Offset w) => _origin + w * _ppm;
  Offset _screenToWorld(Offset s) => (s - _origin) / _ppm;

  bool _samePoint(Offset a, Offset b) => FloorPlanData.samePoint(a, b);

  Offset? _cornerNear(Offset screenPos) {
    Offset? best;
    var bestDist = _cornerSnapPx;
    for (final w in _plan.walls) {
      for (final p in [w.start, w.end]) {
        final d = (_worldToScreen(p) - screenPos).distance;
        if (d < bestDist) {
          bestDist = d;
          best = p;
        }
      }
    }
    return best;
  }

  double _pointToSegDist(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2;
    return (p - a + ab * (-t.clamp(0.0, 1.0))).distance;
  }

  String? _hitTest(Offset screenPos) {
    double bestCornerDist = 20;
    int bestCornerWall = -1;
    bool bestCornerIsStart = true;
    for (int i = 0; i < _plan.walls.length; i++) {
      final w = _plan.walls[i];
      for (final (isStart, pt) in [(true, w.start), (false, w.end)]) {
        final sp = _worldToScreen(pt);
        final d = (screenPos - sp).distance;
        if (d < bestCornerDist) {
          bestCornerDist = d;
          bestCornerWall = i;
          bestCornerIsStart = isStart;
        }
      }
    }
    if (bestCornerWall >= 0) {
      _dragCornerWall = bestCornerWall;
      _dragCornerIsStart = bestCornerIsStart;
      return 'corner';
    }

    for (int i = 0; i < _plan.doors.length; i++) {
      final d = _plan.doors[i];
      if (d.wallIndex < _plan.walls.length) {
        final pos = _worldToScreen(_plan.walls[d.wallIndex].getPointAtPosition(d.positionAlongWall));
        if ((screenPos - pos).distance < 30) {
          _dragElementType = 'door';
          _dragElementIdx = i;
          return 'element';
        }
      }
    }
    for (int i = 0; i < _plan.windows.length; i++) {
      final w = _plan.windows[i];
      if (w.wallIndex < _plan.walls.length) {
        final pos = _worldToScreen(_plan.walls[w.wallIndex].getPointAtPosition(w.positionAlongWall));
        if ((screenPos - pos).distance < 30) {
          _dragElementType = 'window';
          _dragElementIdx = i;
          return 'element';
        }
      }
    }
    for (int i = 0; i < _plan.outlets.length; i++) {
      final o = _plan.outlets[i];
      if (o.wallIndex < _plan.walls.length) {
        final pos = _worldToScreen(_plan.walls[o.wallIndex].getPointAtPosition(o.positionAlongWall));
        if ((screenPos - pos).distance < 25) {
          _dragElementType = 'outlet';
          _dragElementIdx = i;
          return 'element';
        }
      }
    }

    int bestWall = -1;
    double bestWallDist = 20;
    for (int i = 0; i < _plan.walls.length; i++) {
      final w = _plan.walls[i];
      final d = _pointToSegDist(screenPos, _worldToScreen(w.start), _worldToScreen(w.end));
      if (d < bestWallDist) {
        bestWallDist = d;
        bestWall = i;
      }
    }
    if (bestWall >= 0) {
      _selectedWall = bestWall;
      return 'wall';
    }

    return null;
  }

  void _onTapUp(TapUpDetails details) {
    if (_mode == _Mode.addWall) {
      _handleAddWallTap(details.localPosition);
      return;
    }

    if (_mode != _Mode.none) {
      final wall = _findWallAtPoint(details.localPosition);
      if (wall == null) return;
      switch (_mode) {
        case _Mode.deleteWall:
          _deleteWall(wall);
        case _Mode.split:
          _splitWall(wall);
        case _Mode.door:
          _placeElement('door', wall);
        case _Mode.window:
          _placeElement('window', wall);
        case _Mode.outlet:
          _placeElement('outlet', wall);
        case _Mode.none:
        case _Mode.addWall:
          break;
      }
      return;
    }

    final hit = _hitTest(details.localPosition);
    setState(() {
      _selectedType = '';
      _selectedIdx = null;

      if (hit == 'element') {
        _selectedType = _dragElementType;
        _selectedIdx = _dragElementIdx;
      } else if (hit == 'wall') {
      } else {
        _selectedWall = null;
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_mode != _Mode.none) return;
    final hit = _hitTest(details.localPosition);
    if (hit == 'corner') {
      setState(() => _dragTarget = _DragTarget.corner);
    } else if (hit == 'element') {
      setState(() => _dragTarget = _DragTarget.element);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragTarget == _DragTarget.corner && _dragCornerWall >= 0) {
      final world = _screenToWorld(details.localPosition);
      _moveCorner(world);
    } else if (_dragTarget == _DragTarget.element) {
      _dragElement(details.localPosition);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final wasCornerDrag = _dragTarget == _DragTarget.corner && _dragCornerWall >= 0;
    final cornerPos = wasCornerDrag
        ? (_dragCornerIsStart
            ? _plan.walls[_dragCornerWall].start
            : _plan.walls[_dragCornerWall].end)
        : null;

    setState(() {
      _dragTarget = _DragTarget.none;
      _dragCornerWall = -1;
      _dragElementIdx = -1;
    });

    if (wasCornerDrag && cornerPos != null) {
      setState(() {
        _dropCornerOntoWall(cornerPos);
        _plan.mergeAt(cornerPos);
        _plan.updateBounds();
      });
    }

    _save();
  }

  void _dropCornerOntoWall(Offset cornerPos) {
    for (int i = 0; i < _plan.walls.length; i++) {
      final w = _plan.walls[i];
      if (_samePoint(w.start, cornerPos) || _samePoint(w.end, cornerPos)) continue;
      if (_pointToSegDist(cornerPos, w.start, w.end) >= 0.1) continue;
      final t = _projectOnWall(cornerPos, w);
      if (t <= 0.02 || t >= 0.98) continue;
      _plan.moveCorner(cornerPos, w.getPointAtPosition(t));
      _plan.splitWall(i, t);
      HapticFeedback.lightImpact();
      return;
    }
  }

  void _moveCorner(Offset newWorldPos) {
    final wall = _plan.walls[_dragCornerWall];
    final oldCorner = _dragCornerIsStart ? wall.start : wall.end;
    setState(() {
      _plan.moveCorner(oldCorner, newWorldPos);
      _plan.updateBounds();
    });
  }

  void _dragElement(Offset screenPos) {
    final world = _screenToWorld(screenPos);

    if (_dragElementType == 'door' && _dragElementIdx < _plan.doors.length) {
      final door = _plan.doors[_dragElementIdx];
      if (door.wallIndex < _plan.walls.length) {
        final t = _projectOnWall(world, _plan.walls[door.wallIndex]);
        setState(() => _plan.doors[_dragElementIdx] = door.copyWith(
            positionAlongWall: _plan.clampPosition(door.wallIndex, t, door.width)));
      }
    } else if (_dragElementType == 'window' && _dragElementIdx < _plan.windows.length) {
      final win = _plan.windows[_dragElementIdx];
      if (win.wallIndex < _plan.walls.length) {
        final t = _projectOnWall(world, _plan.walls[win.wallIndex]);
        setState(() => _plan.windows[_dragElementIdx] = win.copyWith(
            positionAlongWall: _plan.clampPosition(win.wallIndex, t, win.width)));
      }
    } else if (_dragElementType == 'outlet' && _dragElementIdx < _plan.outlets.length) {
      final out = _plan.outlets[_dragElementIdx];
      if (out.wallIndex < _plan.walls.length) {
        final t = _projectOnWall(world, _plan.walls[out.wallIndex]);
        setState(() => _plan.outlets[_dragElementIdx] = out.copyWith(
            positionAlongWall: _plan.clampPosition(out.wallIndex, t, 0.1)));
      }
    }
  }

  double _projectOnWall(Offset world, WallSegment wall) {
    final wallVec = wall.end - wall.start;
    final len2 = wallVec.dx * wallVec.dx + wallVec.dy * wallVec.dy;
    if (len2 == 0) return 0.5;
    final t = ((world - wall.start).dx * wallVec.dx + (world - wall.start).dy * wallVec.dy) / len2;
    return t.clamp(0.0, 1.0);
  }

  void _placeElement(String type, int wallIdx) {
    HapticFeedback.mediumImpact();
    setState(() {
      switch (type) {
        case 'door':
          _plan.doors.add(Door(
              positionAlongWall: _plan.clampPosition(wallIdx, 0.5, 0.9),
              wallIndex: wallIdx));
          _selectedType = 'door';
          _selectedIdx = _plan.doors.length - 1;
          break;
        case 'window':
          _plan.windows.add(FloorWindow(
              positionAlongWall: _plan.clampPosition(wallIdx, 0.5, 1.2),
              wallIndex: wallIdx));
          _selectedType = 'window';
          _selectedIdx = _plan.windows.length - 1;
          break;
        case 'outlet':
          _plan.outlets.add(Outlet(positionAlongWall: 0.5, wallIndex: wallIdx));
          _selectedType = 'outlet';
          _selectedIdx = _plan.outlets.length - 1;
          break;
      }
      _mode = _Mode.none;
    });
    _save();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Placed ${type} on ${_wallName(wallIdx)} wall — drag to reposition'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  void _splitWall(int wallIdx) {
    HapticFeedback.mediumImpact();
    setState(() {
      _plan.splitWall(wallIdx, 0.5);
      _mode = _Mode.none;
    });
    _save();
  }

  void _handleAddWallTap(Offset screenPos) {
    final corner = _cornerNear(screenPos);
    final wallIdx = corner == null ? _findWallAtPoint(screenPos) : null;
    if (corner == null && wallIdx == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_addWallCorner1 == null
            ? 'Tap on an existing wall or corner to start the new wall'
            : 'Tap on a wall or an existing corner to finish'),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    final point = corner ??
        _plan.walls[wallIdx!].getPointAtPosition(
            _projectOnWall(_screenToWorld(screenPos), _plan.walls[wallIdx]));

    if (_addWallCorner1 != null && (point - _addWallCorner1!).distance < 0.05) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Wall too short — tap further away'),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    var split = false;
    setState(() {
      if (corner == null) {
        _plan.splitWall(wallIdx!, _projectOnWall(point, _plan.walls[wallIdx]));
        split = true;
      }
      if (_addWallCorner1 == null) {
        _addWallCorner1 = point;
        _corner1FromSplit = split;
      } else {
        _plan.walls.add(WallSegment(start: _addWallCorner1!, end: point, isExternal: false));
        _plan.updateBounds();
        _addWallCorner1 = null;
        _corner1FromSplit = false;
        _mode = _Mode.none;
      }
    });
    HapticFeedback.lightImpact();
    _save();
  }

  void _cancelPendingWall() {
    final corner = _addWallCorner1;
    if (corner == null) return;
    if (_corner1FromSplit) _plan.mergeAt(corner);
    _addWallCorner1 = null;
    _corner1FromSplit = false;
    _save();
  }

  int? _findWallAtPoint(Offset screenPos) {
    double bestDist = 25;
    int? best;
    for (int i = 0; i < _plan.walls.length; i++) {
      final w = _plan.walls[i];
      final d = _pointToSegDist(screenPos, _worldToScreen(w.start), _worldToScreen(w.end));
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  void _deleteWall(int wallIdx) {
    HapticFeedback.mediumImpact();
    setState(() {
      _plan.deleteWall(wallIdx);
      _mode = _Mode.none;
      _selectedWall = null;
      _selectedType = '';
      _selectedIdx = null;
    });
    _save();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Wall deleted'),
      duration: Duration(seconds: 2),
    ));
  }

  void _resetPlan() {
    if (_originalPlan == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Floor Plan'),
        content: const Text('This will undo all changes and restore the original floor plan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              setState(() {
                _plan = FloorPlanData.fromJson(_originalPlan!.toJson());
                _addWallCorner1 = null;
                _corner1FromSplit = false;
                _selectedWall = null;
                _selectedType = '';
                _selectedIdx = null;
                _mode = _Mode.none;
              });
              _save();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Floor plan reset'),
                duration: Duration(seconds: 2),
              ));
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _deleteElement(String type, int idx) {
    setState(() {
      switch (type) {
        case 'door': _plan.doors.removeAt(idx); break;
        case 'window': _plan.windows.removeAt(idx); break;
        case 'outlet': _plan.outlets.removeAt(idx); break;
      }
      _selectedType = '';
      _selectedIdx = null;
    });
    _save();
  }

  double _posLo(int wall, double width) => _plan.clampPosition(wall, 0, width);

  double _posHi(int wall, double width) =>
      max(_plan.clampPosition(wall, 1, width), _posLo(wall, width) + 0.001);

  void _updateDoor(int idx, {double? pos, double? width, double? height, DoorSwing? swing, int? wall}) {
    final d = _plan.doors[idx];
    final wallIdx = wall ?? d.wallIndex;
    final newWidth = width ?? d.width;
    setState(() {
      _plan.doors[idx] = Door(
        positionAlongWall: _plan.clampPosition(wallIdx, pos ?? d.positionAlongWall, newWidth),
        width: newWidth,
        height: height ?? d.height,
        swing: swing ?? d.swing,
        wallIndex: wallIdx,
      );
    });
    _save();
  }

  void _updateWindow(int idx, {double? pos, double? width, double? height, double? sill, WindowType? type, int? wall}) {
    final w = _plan.windows[idx];
    final wallIdx = wall ?? w.wallIndex;
    final newWidth = width ?? w.width;
    setState(() {
      _plan.windows[idx] = FloorWindow(
        positionAlongWall: _plan.clampPosition(wallIdx, pos ?? w.positionAlongWall, newWidth),
        width: newWidth,
        height: height ?? w.height,
        sillHeight: sill ?? w.sillHeight,
        type: type ?? w.type,
        wallIndex: wallIdx,
      );
    });
    _save();
  }

  void _updateOutlet(int idx, {double? pos, OutletType? type, double? height, int? wall}) {
    final o = _plan.outlets[idx];
    final wallIdx = wall ?? o.wallIndex;
    setState(() {
      _plan.outlets[idx] = Outlet(
        positionAlongWall: _plan.clampPosition(wallIdx, pos ?? o.positionAlongWall, 0.1),
        type: type ?? o.type,
        heightFromFloor: height ?? o.heightFromFloor,
        wallIndex: wallIdx,
      );
    });
    _save();
  }

  String _wallName(int i) => wallName(_plan, i);

  Future<void> _autoDetect() async {
    final images = ref.read(capturedImagesProvider);
    if (images.isEmpty) return;
    final proxy = ref.read(aiProxyServiceProvider);
    if (!proxy.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to use AI auto-detect'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      final imageData = images.first;
      final dataUrl = await fitDataUrlForFirestore(imageData.startsWith('data:') ? imageData : 'data:image/jpeg;base64,$imageData');
      final content = await proxy.chat([
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _detectionPrompt()},
            {'type': 'image_url', 'image_url': {'url': dataUrl}},
          ],
        },
      ]);
      _parseDetection(content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is AiProxyException
              ? 'Auto-detect failed: ${e.message}'
              : 'Auto-detect failed. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
    if (mounted) setState(() => _isAnalyzing = false);
  }

  String _detectionPrompt() => 'Analyze this room photo and extract the floor plan as JSON. '
      'Reply ONLY with valid JSON, no markdown fences.\n'
      '{"width":number,"depth":number,"ceilingHeight":number,'
      '"windows":[{"wall":"south","position":0.5,"width":1.2,"height":1.2,"sillHeight":0.9,"type":"standard"}],'
      '"doors":[{"wall":"east","position":0.3,"width":0.9,"height":2.1,"swing":"right"}],'
      '"outlets":[{"wall":"north","position":0.7,"type":"power","heightFromFloor":0.3}]}\n'
      'Wall directions: south=bottom, north=top, east=right, west=left. '
      'Position 0.0-1.0 along wall.';

  void _parseDetection(String content) {
    try {
      var s = content.trim();
      if (s.contains('```')) {
        final m = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(s);
        if (m != null) s = m.group(1)!.trim();
      }
      final jm = RegExp(r'\{[\s\S]*\}').firstMatch(s);
      if (jm == null) return;
      final data = jsonDecode(jm.group(0)!) as Map<String, dynamic>;

      setState(() {
        _plan.roomWidth = ((data['width'] as num?)?.toDouble() ?? 4.0).clamp(2.0, 15.0);
        _plan.roomDepth = ((data['depth'] as num?)?.toDouble() ?? 3.5).clamp(2.0, 15.0);
        _plan.ceilingHeight = ((data['ceilingHeight'] as num?)?.toDouble() ?? 2.7).clamp(2.0, 5.0);
        _rebuildWalls();

        for (final w in (data['windows'] as List? ?? [])) {
          final wi = _wallIdx((w['wall'] ?? 'south') as String);
          final tn = (w['type'] ?? 'standard').toString().toLowerCase();
          WindowType wt = WindowType.standard;
          if (tn == 'bay') wt = WindowType.bay;
          else if (tn == 'sliding') wt = WindowType.sliding;
          else if (tn == 'floortoceiling') wt = WindowType.floorToCeiling;
          else if (tn == 'arched') wt = WindowType.arched;
          _plan.windows.add(FloorWindow(
            positionAlongWall: ((w['position'] as num?)?.toDouble() ?? 0.5).clamp(0.05, 0.95),
            width: ((w['width'] as num?)?.toDouble() ?? 1.2).clamp(0.3, 4.0),
            height: ((w['height'] as num?)?.toDouble() ?? 1.2).clamp(0.3, 3.0),
            sillHeight: ((w['sillHeight'] as num?)?.toDouble() ?? 0.9).clamp(0.0, 2.0),
            type: wt, wallIndex: wi,
          ));
        }
        for (final d in (data['doors'] as List? ?? [])) {
          final di = _wallIdx((d['wall'] ?? 'east') as String);
          final sn = (d['swing'] ?? 'right').toString().toLowerCase();
          DoorSwing ds = DoorSwing.right;
          if (sn == 'left') ds = DoorSwing.left;
          else if (sn == 'double') ds = DoorSwing.double;
          else if (sn == 'sliding') ds = DoorSwing.sliding;
          _plan.doors.add(Door(
            positionAlongWall: ((d['position'] as num?)?.toDouble() ?? 0.5).clamp(0.05, 0.95),
            width: ((d['width'] as num?)?.toDouble() ?? 0.9).clamp(0.5, 2.0),
            height: ((d['height'] as num?)?.toDouble() ?? 2.1).clamp(1.5, 3.0),
            swing: ds, wallIndex: di,
          ));
        }
        for (final o in (data['outlets'] as List? ?? [])) {
          final oi = _wallIdx((o['wall'] ?? 'south') as String);
          final tn = (o['type'] ?? 'power').toString().toLowerCase();
          OutletType ot = OutletType.power;
          if (tn == 'data') ot = OutletType.data;
          else if (tn == 'coax') ot = OutletType.coax;
          else if (tn == 'usb') ot = OutletType.usb;
          else if (tn == 'hdmi') ot = OutletType.hdmi;
          _plan.outlets.add(Outlet(
            positionAlongWall: ((o['position'] as num?)?.toDouble() ?? 0.5).clamp(0.05, 0.95),
            type: ot,
            heightFromFloor: ((o['heightFromFloor'] as num?)?.toDouble() ?? 0.3).clamp(0.1, 1.5),
            wallIndex: oi,
          ));
        }
      });
      _save();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Detected: ${_plan.roomWidth.toStringAsFixed(1)}m × ${_plan.roomDepth.toStringAsFixed(1)}m'),
        backgroundColor: Colors.green.shade700,
      ));
    } catch (_) {}
  }

  int _wallIdx(String name) => _plan.wallIndexForDirection(name) ?? 0;

  void _rebuildWalls() {
    final w = _plan.roomWidth;
    final d = _plan.roomDepth;
    _plan.walls.clear();
    _plan.walls.addAll([
      WallSegment(start: Offset(0, 0), end: Offset(w, 0)),
      WallSegment(start: Offset(w, 0), end: Offset(w, d)),
      WallSegment(start: Offset(w, d), end: Offset(0, d)),
      WallSegment(start: Offset(0, d), end: Offset(0, 0)),
    ]);
    _plan.doors.clear();
    _plan.windows.clear();
    _plan.outlets.clear();
  }

  void _showDimensionsDialog() {
    final wc = TextEditingController(text: _plan.roomWidth.toStringAsFixed(1));
    final dc = TextEditingController(text: _plan.roomDepth.toStringAsFixed(1));
    final hc = TextEditingController(text: _plan.ceilingHeight.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Room Dimensions'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: wc, decoration: const InputDecoration(labelText: 'Width (m)'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: dc, decoration: const InputDecoration(labelText: 'Depth (m)'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: hc, decoration: const InputDecoration(labelText: 'Ceiling (m)'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final w = double.tryParse(wc.text);
            final d = double.tryParse(dc.text);
            final h = double.tryParse(hc.text);
            if (w != null && d != null && w > 0 && d > 0) {
              setState(() {
                _cancelPendingWall();
                _plan.resizeTo(w, d);
                if (h != null && h > 0) _plan.ceilingHeight = h;
              });
              _save();
            }
            Navigator.pop(ctx);
          }, child: const Text('Update')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final modeLabel = switch (_mode) {
      _Mode.door => 'Tap a wall to place door',
      _Mode.window => 'Tap a wall to place window',
      _Mode.outlet => 'Tap a wall to place outlet',
      _Mode.split => 'Tap a wall to split it',
      _Mode.addWall => _addWallCorner1 == null ? 'Tap a wall for the start corner' : 'Tap a wall or corner for the end',
      _Mode.deleteWall => 'Tap a wall to delete it',
      _Mode.none => null,
    };

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    onPressed: () => widget.onBack != null ? widget.onBack!() : Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Floor Plan', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        if (modeLabel != null)
                          Text(modeLabel, style: TextStyle(fontSize: 10, color: cs.primary))
                        else
                          Text('Tap wall to edit · Drag corners freely', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (_isAnalyzing)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else ...[
                    IconButton(
                      icon: const Icon(Icons.restart_alt, size: 18),
                      onPressed: _resetPlan,
                      tooltip: 'Reset floor plan',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _autoDetect,
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: const Text('Auto-detect', style: TextStyle(fontSize: 11)),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), visualDensity: VisualDensity.compact),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  _chip('Door', Icons.door_sliding_outlined, _mode == _Mode.door, cs, () => _toggleMode(_Mode.door)),
                  const SizedBox(width: 4),
                  _chip('Window', Icons.curtains_outlined, _mode == _Mode.window, cs, () => _toggleMode(_Mode.window)),
                  const SizedBox(width: 4),
                  _chip('Outlet', Icons.electrical_services_outlined, _mode == _Mode.outlet, cs, () => _toggleMode(_Mode.outlet)),
                  const SizedBox(width: 4),
                  _chip('Split', Icons.content_cut, _mode == _Mode.split, cs, () => _toggleMode(_Mode.split)),
                  const SizedBox(width: 4),
                  _chip('Wall', Icons.add_home_outlined, _mode == _Mode.addWall, cs, () => _toggleMode(_Mode.addWall)),
                  const SizedBox(width: 4),
                  _chip('Delete', Icons.delete_sweep_outlined, _mode == _Mode.deleteWall, cs, () => _toggleMode(_Mode.deleteWall), color: cs.error),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_dragTarget == _DragTarget.none) {
                      final b = _plan.bounds;
                      _ppm = min(
                        (constraints.maxWidth - 60) / max(b.width, 0.5),
                        (constraints.maxHeight - 60) / max(b.height, 0.5),
                      );
                      _origin = Offset(
                        constraints.maxWidth / 2 - b.center.dx * _ppm,
                        constraints.maxHeight / 2 - b.center.dy * _ppm,
                      );
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: _onTapUp,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: _FloorPlanPainter(
                          plan: _plan,
                          origin: _origin,
                          ppm: _ppm,
                          selectedWall: _selectedWall,
                          selectedType: _selectedType,
                          selectedIdx: _selectedIdx,
                          mode: _mode,
                          cs: cs,
                          addWallStart: _addWallCorner1,
                        ),
                        size: constraints.biggest,
                      ),
                    );
                  },
                ),
              ),
            ),

            if (_selectedIdx != null) _buildPropertyPanel(cs),
            if (_selectedWall != null && _selectedIdx == null) _buildWallPanel(cs),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showDimensionsDialog,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Room Size', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onComplete,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('3D Preview', style: TextStyle(fontSize: 13)),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMode(_Mode m) {
    setState(() {
      _cancelPendingWall();
      _mode = _mode == m ? _Mode.none : m;
      _selectedWall = null;
      _selectedType = '';
      _selectedIdx = null;
    });
  }

  Widget _chip(String label, IconData icon, bool active, ColorScheme cs, VoidCallback onTap, {Color? color}) {
    final activeColor = color ?? cs.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.15) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? activeColor : cs.outlineVariant, width: active ? 2 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? activeColor : cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? activeColor : cs.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _buildPropertyPanel(ColorScheme cs) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_selectedType == 'door' && _selectedIdx! < _plan.doors.length) _buildDoorProps(cs),
          if (_selectedType == 'window' && _selectedIdx! < _plan.windows.length) _buildWindowProps(cs),
          if (_selectedType == 'outlet' && _selectedIdx! < _plan.outlets.length) _buildOutletProps(cs),
        ]),
      ),
    );
  }

  Widget _buildWallPanel(ColorScheme cs) {
    final idx = _selectedWall!;
    if (idx >= _plan.walls.length) return const SizedBox.shrink();
    final wall = _plan.walls[idx];
    final len = wall.length;
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Icon(Icons.border_style, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(
            '${_wallName(idx)} · ${len.toStringAsFixed(1)}m',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          )),
          IconButton(
            onPressed: () { _deleteWall(idx); },
            icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ]),
    );
  }

  Widget _buildDoorProps(ColorScheme cs) {
    final d = _plan.doors[_selectedIdx!];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Icon(Icons.door_sliding_outlined, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Expanded(child: Text('Door · ${_wallName(d.wallIndex)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        IconButton(onPressed: () => _deleteElement('door', _selectedIdx!), icon: Icon(Icons.delete_outline, size: 18, color: cs.error), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
      _slider('Position', '${(d.positionAlongWall * 100).round()}%', d.positionAlongWall, _posLo(d.wallIndex, d.width), _posHi(d.wallIndex, d.width), (v) => _updateDoor(_selectedIdx!, pos: v)),
      _slider('Width', '${d.width.toStringAsFixed(2)}m', d.width, 0.5, 2.0, (v) => _updateDoor(_selectedIdx!, width: v)),
      _slider('Height', '${d.height.toStringAsFixed(2)}m', d.height, 1.5, 3.0, (v) => _updateDoor(_selectedIdx!, height: v)),
      Row(children: [
        const Text('Swing: ', style: TextStyle(fontSize: 10)),
        ...DoorSwing.values.map((s) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: ChoiceChip(
            label: Text(s.name, style: const TextStyle(fontSize: 9)),
            selected: d.swing == s,
            onSelected: (_) => _updateDoor(_selectedIdx!, swing: s),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )),
      ]),
      _wallPicker(d.wallIndex, (i) => _updateDoor(_selectedIdx!, wall: i)),
    ]);
  }

  Widget _buildWindowProps(ColorScheme cs) {
    final w = _plan.windows[_selectedIdx!];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Icon(Icons.curtains_outlined, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 6),
        Expanded(child: Text('Window · ${_wallName(w.wallIndex)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        IconButton(onPressed: () => _deleteElement('window', _selectedIdx!), icon: Icon(Icons.delete_outline, size: 18, color: cs.error), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
      _slider('Position', '${(w.positionAlongWall * 100).round()}%', w.positionAlongWall, _posLo(w.wallIndex, w.width), _posHi(w.wallIndex, w.width), (v) => _updateWindow(_selectedIdx!, pos: v)),
      _slider('Width', '${w.width.toStringAsFixed(2)}m', w.width, 0.3, 4.0, (v) => _updateWindow(_selectedIdx!, width: v)),
      _slider('Height', '${w.height.toStringAsFixed(2)}m', w.height, 0.3, 3.0, (v) => _updateWindow(_selectedIdx!, height: v)),
      Row(children: [
        const Text('Type: ', style: TextStyle(fontSize: 10)),
        ...WindowType.values.map((t) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: ChoiceChip(
            label: Text(t.name, style: const TextStyle(fontSize: 9)),
            selected: w.type == t,
            onSelected: (_) => _updateWindow(_selectedIdx!, type: t),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )),
      ]),
      _wallPicker(w.wallIndex, (i) => _updateWindow(_selectedIdx!, wall: i)),
    ]);
  }

  Widget _buildOutletProps(ColorScheme cs) {
    final o = _plan.outlets[_selectedIdx!];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Icon(Icons.electrical_services_outlined, size: 16, color: Colors.orange.shade700),
        const SizedBox(width: 6),
        Expanded(child: Text('Outlet · ${_wallName(o.wallIndex)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        IconButton(onPressed: () => _deleteElement('outlet', _selectedIdx!), icon: Icon(Icons.delete_outline, size: 18, color: cs.error), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
      _slider('Position', '${(o.positionAlongWall * 100).round()}%', o.positionAlongWall, _posLo(o.wallIndex, 0.1), _posHi(o.wallIndex, 0.1), (v) => _updateOutlet(_selectedIdx!, pos: v)),
      Row(children: [
        const Text('Type: ', style: TextStyle(fontSize: 10)),
        ...OutletType.values.map((t) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: ChoiceChip(
            label: Text(t.name, style: const TextStyle(fontSize: 9)),
            selected: o.type == t,
            onSelected: (_) => _updateOutlet(_selectedIdx!, type: t),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )),
      ]),
      _wallPicker(o.wallIndex, (i) => _updateOutlet(_selectedIdx!, wall: i)),
    ]);
  }

  Widget _slider(String label, String val, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        SizedBox(width: 56, child: Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Expanded(child: SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
          child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        )),
        SizedBox(width: 40, child: Text(val, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _wallPicker(int current, ValueChanged<int> onSelected) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(children: [
        const Text('Wall: ', style: TextStyle(fontSize: 10)),
        ...List.generate(_plan.walls.length, (i) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: ChoiceChip(
            label: Text(_wallName(i), style: const TextStyle(fontSize: 9)),
            selected: current == i,
            onSelected: (_) => onSelected(i),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )),
      ]),
    );
  }
}

class _FloorPlanPainter extends CustomPainter {
  final FloorPlanData plan;
  final Offset origin;
  final double ppm;
  final int? selectedWall;
  final String selectedType;
  final int? selectedIdx;
  final _Mode mode;
  final ColorScheme cs;
  final Offset? addWallStart;

  _FloorPlanPainter({
    required this.plan,
    required this.origin,
    required this.ppm,
    required this.selectedWall,
    required this.selectedType,
    required this.selectedIdx,
    required this.mode,
    required this.cs,
    this.addWallStart,
  });

  Offset w2s(Offset w) => origin + w * ppm;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    if (plan.walls.isNotEmpty) {
      final path = Path();
      path.addPolygon(plan.outline.map(w2s).toList(), true);
      final floorPaint = Paint()..color = cs.primary.withValues(alpha: 0.04);
      canvas.drawPath(path, floorPaint);
    }

    for (int i = 0; i < plan.walls.length; i++) {
      final wall = plan.walls[i];
      final s = w2s(wall.start);
      final e = w2s(wall.end);
      final isSelected = selectedWall == i;
      final isDeleteMode = mode == _Mode.deleteWall;
      final isInteractiveMode = mode != _Mode.none;

      Color wallColor;
      double strokeWidth;
      if (isDeleteMode && isSelected) {
        wallColor = Colors.red;
        strokeWidth = 5;
      } else if (isDeleteMode) {
        wallColor = cs.error.withValues(alpha: 0.25);
        strokeWidth = 3;
      } else if (isInteractiveMode && isSelected) {
        wallColor = Colors.green.shade400;
        strokeWidth = 5;
      } else if (isInteractiveMode) {
        wallColor = cs.primary.withValues(alpha: 0.4);
        strokeWidth = 3.5;
      } else if (isSelected) {
        wallColor = cs.error;
        strokeWidth = 5;
      } else {
        wallColor = cs.primary;
        strokeWidth = 3.5;
      }

      final paint = Paint()
        ..color = wallColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(s, e, paint);

      final mid = (s + e) / 2;
      final wallLen = (wall.end - wall.start).distance;
      final tp = TextPainter(text: TextSpan(
        text: '${_wallLabel(i)}  ${wallLen.toStringAsFixed(1)}m',
        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
      ), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - 14));
    }

    if (plan.walls.isNotEmpty) {
      final b = plan.bounds;
      final topLeft = w2s(b.topLeft);
      final rpW = b.width * ppm;
      final rpH = b.height * ppm;
      final wTp = TextPainter(text: TextSpan(
        text: '${b.width.toStringAsFixed(1)}m',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
      ), textDirection: TextDirection.ltr)..layout();
      wTp.paint(canvas, Offset(topLeft.dx + rpW / 2 - wTp.width / 2, topLeft.dy - 30));

      final dTp = TextPainter(text: TextSpan(
        text: '${b.height.toStringAsFixed(1)}m',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
      ), textDirection: TextDirection.ltr)..layout();
      canvas.save();
      canvas.translate(topLeft.dx - 30, topLeft.dy + rpH / 2);
      canvas.rotate(-pi / 2);
      dTp.paint(canvas, Offset(-dTp.width / 2, 0));
      canvas.restore();
    }

    for (int i = 0; i < plan.doors.length; i++) {
      final d = plan.doors[i];
      if (d.wallIndex >= plan.walls.length) continue;
      final wall = plan.walls[d.wallIndex];
      final pos = w2s(wall.getPointAtPosition(d.positionAlongWall));
      final isSel = selectedType == 'door' && selectedIdx == i;
      _drawDoor(canvas, pos, d, wall, isSel);
      if (isSel) _drawRuler(canvas, pos, d.positionAlongWall, wall);
    }

    for (int i = 0; i < plan.windows.length; i++) {
      final w = plan.windows[i];
      if (w.wallIndex >= plan.walls.length) continue;
      final wall = plan.walls[w.wallIndex];
      final pos = w2s(wall.getPointAtPosition(w.positionAlongWall));
      final isSel = selectedType == 'window' && selectedIdx == i;
      _drawWindow(canvas, pos, w, wall, isSel);
      if (isSel) _drawRuler(canvas, pos, w.positionAlongWall, wall);
    }

    for (int i = 0; i < plan.outlets.length; i++) {
      final o = plan.outlets[i];
      if (o.wallIndex >= plan.walls.length) continue;
      final wall = plan.walls[o.wallIndex];
      final pos = w2s(wall.getPointAtPosition(o.positionAlongWall));
      final isSel = selectedType == 'outlet' && selectedIdx == i;
      _drawOutlet(canvas, pos, o, wall, isSel);
      if (isSel) _drawRuler(canvas, pos, o.positionAlongWall, wall);
    }

    if (addWallStart != null && mode == _Mode.addWall) {
      final sp = w2s(addWallStart!);
      canvas.drawCircle(sp, 8, Paint()..color = Colors.green.shade400.withValues(alpha: 0.3));
      canvas.drawCircle(sp, 8, Paint()..color = Colors.green.shade400..style = PaintingStyle.stroke..strokeWidth = 2);
      final hint = TextPainter(
        text: TextSpan(text: 'Corner set — tap end point', style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
        textDirection: TextDirection.ltr,
      )..layout();
      hint.paint(canvas, Offset(sp.dx - hint.width / 2, sp.dy + 14));
    }

    final seen = <String>{};
    for (final wall in plan.walls) {
      for (final pt in [wall.start, wall.end]) {
        final key = '${pt.dx.toStringAsFixed(4)},${pt.dy.toStringAsFixed(4)}';
        if (!seen.add(key)) continue;
        final sp = w2s(pt);
        canvas.drawCircle(sp, 5, Paint()..color = cs.primary);
        canvas.drawCircle(sp, 5, Paint()..color = cs.onSurface..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }
  }

  void _drawDoor(Canvas canvas, Offset pos, Door door, WallSegment wall, bool selected) {
    final wallAngle = (wall.end - wall.start).direction;
    final doorWidthPx = door.width * ppm;
    final color = selected ? Colors.red.shade700 : const Color(0xFF5B3A29);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(wallAngle);

    final leafPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final isRight = door.swing == DoorSwing.right || door.swing == DoorSwing.sliding;
    final sign = isRight ? 1.0 : -1.0;
    if (door.swing == DoorSwing.left || door.swing == DoorSwing.right) {
      canvas.translate(-sign * doorWidthPx / 2, 0);
    }

    if (door.swing == DoorSwing.sliding) {
      canvas.drawLine(Offset(-doorWidthPx / 2, -2), Offset(doorWidthPx / 2, -2), leafPaint);
      canvas.drawLine(Offset(-doorWidthPx / 2 + 4, 2), Offset(doorWidthPx / 2 + 4, 2), leafPaint..strokeWidth = 1.5);
    } else if (door.swing == DoorSwing.double) {
      canvas.drawLine(Offset(-doorWidthPx / 2, 0), Offset(0, 0), leafPaint);
      canvas.drawLine(Offset(doorWidthPx / 2, 0), Offset(0, 0), leafPaint);
      final arcPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final r = doorWidthPx / 2;
      final rect = Rect.fromCircle(center: Offset(-doorWidthPx / 4, 0), radius: r / 2);
      canvas.drawArc(rect, -pi / 2, -pi / 2, false, arcPaint);
      final rect2 = Rect.fromCircle(center: Offset(doorWidthPx / 4, 0), radius: r / 2);
      canvas.drawArc(rect2, -pi / 2, pi / 2, false, arcPaint);
    } else {
      canvas.drawLine(Offset.zero, Offset(sign * doorWidthPx, 0), leafPaint);

      final arcPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final r = doorWidthPx;
      final rect = Rect.fromCircle(center: Offset.zero, radius: r);
      final startAngle = isRight ? -pi / 2 : pi / 2;
      canvas.drawArc(rect, startAngle, sign * (-pi / 2), false, arcPaint);
    }

    canvas.restore();

    if (selected) {
      canvas.drawCircle(pos, doorWidthPx / 2 + 6, Paint()
        ..color = Colors.red.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill);
    }
  }

  void _drawWindow(Canvas canvas, Offset pos, FloorWindow win, WallSegment wall, bool selected) {
    final wallAngle = (wall.end - wall.start).direction;
    final winWidthPx = win.width * ppm;
    final color = selected ? Colors.blue.shade700 : const Color(0xFF2E6B7A);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(wallAngle);

    final halfW = winWidthPx / 2;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2;

    canvas.drawLine(Offset(-halfW, -3), Offset(halfW, -3), linePaint);
    canvas.drawLine(Offset(-halfW, 3), Offset(halfW, 3), linePaint);

    final capPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(-halfW, -3), Offset(-halfW, 3), capPaint);
    canvas.drawLine(Offset(halfW, -3), Offset(halfW, 3), capPaint);

    if (winWidthPx > 30) {
      final centerPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(0, -3), Offset(0, 3), centerPaint);
    }

    canvas.restore();

    if (selected) {
      canvas.drawCircle(pos, winWidthPx / 2 + 6, Paint()
        ..color = Colors.blue.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill);
    }
  }

  void _drawOutlet(Canvas canvas, Offset pos, Outlet outlet, WallSegment wall, bool selected) {
    final wallAngle = (wall.end - wall.start).direction;
    final color = selected ? Colors.orange.shade700 : const Color(0xFFB8860B);
    final r = selected ? 10.0 : 8.0;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(wallAngle);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromCircle(center: Offset(0, 0), radius: r);
    canvas.drawArc(rect, -pi, pi, false, arcPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(Offset(-r, 0), Offset(r, 0), linePaint);

    if (outlet.type == OutletType.power) {
      final prongPaint = Paint()
        ..color = color
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(-3, 0), Offset(-3, -r - 2), prongPaint);
      canvas.drawLine(Offset(3, 0), Offset(3, -r - 2), prongPaint);
    } else {
      canvas.drawCircle(Offset(0, -r / 2), 2, Paint()..color = color);
    }

    canvas.restore();

    if (selected) {
      canvas.drawCircle(pos, r + 6, Paint()
        ..color = Colors.orange.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill);
    }
  }

  void _drawRuler(Canvas canvas, Offset elementPos, double positionAlongWall, WallSegment wall) {
    final wallLen = wall.length;
    final distToStart = positionAlongWall * wallLen;
    final distToEnd = (1.0 - positionAlongWall) * wallLen;
    final wallAngle = (wall.end - wall.start).direction;
    final normal = wall.normal;
    final offset = normal * 18;

    final linePaint = Paint()
      ..color = cs.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = cs.primary;

    final startScreen = w2s(wall.start);
    final endScreen = w2s(wall.end);

    final rStart1 = elementPos + offset;
    final rEnd1 = startScreen + offset;
    canvas.drawLine(rStart1, rEnd1, linePaint);
    canvas.drawCircle(rStart1, 2, dotPaint);
    canvas.drawCircle(rEnd1, 2, dotPaint);
    final label1 = TextPainter(
      text: TextSpan(
        text: '${distToStart.toStringAsFixed(1)}m',
        style: TextStyle(fontSize: 9, color: cs.primary, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final mid1 = (rStart1 + rEnd1) / 2;
    canvas.save();
    canvas.translate(mid1.dx, mid1.dy);
    canvas.rotate(wallAngle);
    label1.paint(canvas, Offset(-label1.width / 2, -label1.height - 2));
    canvas.restore();

    final rStart2 = elementPos - offset;
    final rEnd2 = endScreen - offset;
    canvas.drawLine(rStart2, rEnd2, linePaint);
    canvas.drawCircle(rStart2, 2, dotPaint);
    canvas.drawCircle(rEnd2, 2, dotPaint);
    final label2 = TextPainter(
      text: TextSpan(
        text: '${distToEnd.toStringAsFixed(1)}m',
        style: TextStyle(fontSize: 9, color: cs.primary, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final mid2 = (rStart2 + rEnd2) / 2;
    canvas.save();
    canvas.translate(mid2.dx, mid2.dy);
    canvas.rotate(wallAngle);
    label2.paint(canvas, Offset(-label2.width / 2, 3));
    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final step = ppm * 0.5;
    if (step < 4) return;
    final paint = Paint()..color = cs.outlineVariant.withValues(alpha: 0.15)..strokeWidth = 0.5;
    final startX = origin.dx % step;
    final startY = origin.dy % step;
    for (double x = startX; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = startY; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  String _wallLabel(int i) => wallName(plan, i, short: true);

  @override
  bool shouldRepaint(covariant _FloorPlanPainter old) => true;
}
