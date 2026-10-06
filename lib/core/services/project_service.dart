import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/project_model.dart';
import 'firestore_image_service.dart' show fitDataUrlThumbnail;

class ProjectService {
  final FirebaseFirestore? _firestore;
  final Uuid _uuid = const Uuid();
  final bool _isDummy;

  final List<ProjectModel> _dummyProjects = [];
  late final StreamController<List<ProjectModel>> _dummyController;

  ProjectService(FirebaseFirestore firestore)
      : _firestore = firestore,
        _isDummy = false;

  ProjectService.dummy() : _firestore = null, _isDummy = true {
    _dummyController = StreamController<List<ProjectModel>>.broadcast(
      onListen: () => _emitDummy(),
    );
  }

  void _emitDummy() {
    if (!_dummyController.isClosed) {
      _dummyController.add(List<ProjectModel>.unmodifiable(_dummyProjects));
    }
  }

  List<ProjectModel> _dummyUserProjects(String userId) {
    final list = _dummyProjects.where((p) => p.userId == userId).toList();
    list.sort((a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  Future<ProjectModel> createProject({
    required String userId,
    required String name,
    required String roomType,
  }) async {
    if (_isDummy) {
      final project = _dummyProject(userId, name, roomType);
      _dummyProjects.insert(0, project);
      _emitDummy();
      return project;
    }
    final projectId = _uuid.v4();
    final project = _dummyProject(userId, name, roomType, id: projectId);

    try {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .set(project.toJson());
    } catch (e) {
      debugPrint('Project save failed, continuing locally: $e');
    }

    return project;
  }

  ProjectModel _dummyProject(String userId, String name, String roomType, {String? id}) {
    return ProjectModel(
      id: id ?? _uuid.v4(),
      userId: userId,
      name: name,
      roomType: roomType,
      style: '',
      primaryColor: 0xFF8B6B5A,
      secondaryColor: 0xFF6B8E8E,
      accentColor: 0xFFD4A574,
      backgroundColor: 0xFFFAF8F5,
      surfaceColor: 0xFFFFFFFF,
      status: ProjectStatus.scanning,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> updateProject(ProjectModel project) async {
    if (_isDummy) {
      final index = _dummyProjects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _dummyProjects[index] =
            project.copyWith(updatedAt: DateTime.now());
        _emitDummy();
      }
      return;
    }
    try {
      await _firestore!
          .collection('users')
          .doc(project.userId)
          .collection('projects')
          .doc(project.id)
          .update(project.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (_) {}
  }

  Future<void> updateProjectStatus(String userId, String projectId, ProjectStatus status) async {
    if (_isDummy) {
      final index = _dummyProjects
          .indexWhere((p) => p.id == projectId && p.userId == userId);
      if (index != -1) {
        _dummyProjects[index] = _dummyProjects[index]
            .copyWith(status: status, updatedAt: DateTime.now());
        _emitDummy();
      }
      return;
    }
    try {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update({
        'status': status.name,
        // ISO string (not serverTimestamp): ProjectModel parses both, but
        // mixing types breaks orderBy('updatedAt') and old readers.
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> updateFloorPlan(String userId, String projectId, FloorPlanModel floorPlan) async {
    if (_isDummy) {
      final index = _dummyProjects
          .indexWhere((p) => p.id == projectId && p.userId == userId);
      if (index != -1) {
        _dummyProjects[index] = _dummyProjects[index].copyWith(
          floorPlan: floorPlan,
          status: ProjectStatus.reviewingPlan,
          updatedAt: DateTime.now(),
        );
        _emitDummy();
      }
      return;
    }
    try {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update({
        'floorPlan': floorPlan.toJson(),
        'status': ProjectStatus.reviewingPlan.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> updateStyle(String userId, String projectId, String style,
      {required int primaryColor,
      required int secondaryColor,
      required int accentColor,
      required int backgroundColor,
      required int surfaceColor}) async {
    if (_isDummy) {
      final index = _dummyProjects
          .indexWhere((p) => p.id == projectId && p.userId == userId);
      if (index != -1) {
        _dummyProjects[index] = _dummyProjects[index].copyWith(
          style: style,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          accentColor: accentColor,
          backgroundColor: backgroundColor,
          surfaceColor: surfaceColor,
          status: ProjectStatus.styling,
          updatedAt: DateTime.now(),
        );
        _emitDummy();
      }
      return;
    }
    try {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update({
        'style': style,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'accentColor': accentColor,
        'backgroundColor': backgroundColor,
        'surfaceColor': surfaceColor,
        'status': ProjectStatus.styling.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Publishes a finished design so lists render instantly.
  ///
  /// The full-resolution image lives in the `designs` subcollection
  /// (written by the generation screen). Here we store only a small
  /// thumbnail inline + top-level `panoramaUrl` and flip status to
  /// complete — previously nothing updated the project doc, so History,
  /// Home and the detail hero kept showing placeholders forever.
  Future<void> addGeneratedDesign(String userId, String projectId, GeneratedDesignModel design) async {
    GeneratedDesignModel thumbDesign = design;
    try {
      final thumbUrl = await fitDataUrlThumbnail(design.panoramaUrl);
      thumbDesign = design.copyWith(panoramaUrl: thumbUrl);
    } catch (_) {}
    if (_isDummy) {
      final index = _dummyProjects
          .indexWhere((p) => p.id == projectId && p.userId == userId);
      if (index != -1) {
        final current = _dummyProjects[index];
        _dummyProjects[index] = current.copyWith(
          generatedDesigns: [...?current.generatedDesigns, thumbDesign],
          panoramaUrl: thumbDesign.panoramaUrl,
          status: ProjectStatus.complete,
          updatedAt: DateTime.now(),
        );
        _emitDummy();
      }
      return;
    }
    try {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update({
        'generatedDesigns': FieldValue.arrayUnion([thumbDesign.toJson()]),
        'panoramaUrl': thumbDesign.panoramaUrl,
        'status': ProjectStatus.complete.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Publish design failed (doc may exceed 1MB): $e');
    }
  }

  Future<void> deleteProject(String userId, String projectId) async {
    if (_isDummy) {
      _dummyProjects
          .removeWhere((p) => p.id == projectId && p.userId == userId);
      _emitDummy();
      return;
    }
    try {
      await deleteProjectTree(_firestore!, userId, projectId);
    } catch (_) {}
  }

  static const _projectSubcollections = ['images', 'designs'];

  static Future<void> deleteProjectTree(
      FirebaseFirestore db, String userId, String projectId) async {
    final project =
        db.collection('users').doc(userId).collection('projects').doc(projectId);
    for (final name in _projectSubcollections) {
      await _deleteCollection(project.collection(name));
    }
    await project.delete();
  }

  static Future<void> deleteUserTree(FirebaseFirestore db, String userId) async {
    final user = db.collection('users').doc(userId);
    final projects = await user.collection('projects').get();
    for (final p in projects.docs) {
      await deleteProjectTree(db, userId, p.id);
    }
    await user.delete();
  }

  static Future<void> _deleteCollection(CollectionReference col) async {
    while (true) {
      final page = await col.limit(400).get();
      if (page.docs.isEmpty) return;
      final batch = col.firestore.batch();
      for (final d in page.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Stream<ProjectModel?> watchProject(String userId, String projectId) {
    if (_isDummy) {
      return _dummyController.stream.map((projects) {
        for (final p in projects) {
          if (p.id == projectId && p.userId == userId) return p;
        }
        return null;
      });
    }
    return _firestore!
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      try {
        return ProjectModel.fromJson(doc.data()!);
      } catch (e) {
        debugPrint('Skipping unparsable project ${doc.id}: $e');
        return null;
      }
    }).handleError((_) => null);
  }

  Stream<List<ProjectModel>> watchUserProjects(String userId) {
    if (_isDummy) {
      return _dummyController.stream
          .map((_) => _dummyUserProjects(userId));
    }
    return _firestore!
        .collection('users')
        .doc(userId)
        .collection('projects')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final projects = <ProjectModel>[];
      for (final doc in snapshot.docs) {
        try {
          projects.add(ProjectModel.fromJson(doc.data()));
        } catch (e) {
          debugPrint('Skipping unparsable project ${doc.id}: $e');
        }
      }
      return projects;
    }).handleError((_) => <ProjectModel>[]);
  }

  Future<List<ProjectModel>> getUserProjects(String userId) async {
    if (_isDummy) return _dummyUserProjects(userId);
    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('projects')
          .orderBy('updatedAt', descending: true)
          .get();
      final projects = <ProjectModel>[];
      for (final doc in snapshot.docs) {
        try {
          projects.add(ProjectModel.fromJson(doc.data()));
        } catch (e) {
          debugPrint('Skipping unparsable project ${doc.id}: $e');
        }
      }
      return projects;
    } catch (_) {
      return [];
    }
  }
}
