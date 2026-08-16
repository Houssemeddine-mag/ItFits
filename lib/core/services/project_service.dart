import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/project_model.dart';

class ProjectService {
  late final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();
  final bool _isDummy;

  ProjectService(FirebaseFirestore firestore)
      : _firestore = firestore,
        _isDummy = false;

  ProjectService.dummy() : _isDummy = true;

  Future<ProjectModel> createProject({
    required String userId,
    required String name,
    required String roomType,
  }) async {
    if (_isDummy) {
      return _dummyProject(userId, name, roomType);
    }
    final projectId = _uuid.v4();
    final project = _dummyProject(userId, name, roomType, id: projectId);

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .set(project.toJson());
    } catch (e) {
      // Return project locally even if Firestore write fails
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
    if (_isDummy) return;
    try {
      await _firestore
          .collection('users')
          .doc(project.userId)
          .collection('projects')
          .doc(project.id)
          .update(project.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (_) {}
  }

  Future<void> updateProjectStatus(String userId, String projectId, ProjectStatus status) async {
    if (_isDummy) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> updateFloorPlan(String userId, String projectId, FloorPlanModel floorPlan) async {
    if (_isDummy) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update({
        'floorPlan': floorPlan.toJson(),
        'status': ProjectStatus.reviewingPlan.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> updateStyle(String userId, String projectId, String style,
      {required int primaryColor,
      required int secondaryColor,
      required int accentColor,
      required int backgroundColor,
      required int surfaceColor}) async {
    if (_isDummy) return;
    try {
      await _firestore
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
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> addGeneratedDesign(String userId, String projectId, GeneratedDesignModel design) async {
    if (_isDummy) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update({
        'generatedDesigns': FieldValue.arrayUnion([design.toJson()]),
        'status': ProjectStatus.complete.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> deleteProject(String userId, String projectId) async {
    if (_isDummy) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .delete();
    } catch (_) {}
  }

  Stream<ProjectModel?> watchProject(String userId, String projectId) {
    if (_isDummy) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ProjectModel.fromJson(doc.data()!);
    }).handleError((_) => null);
  }

  Stream<List<ProjectModel>> watchUserProjects(String userId) {
    if (_isDummy) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProjectModel.fromJson(doc.data())).toList();
    }).handleError((_) => <ProjectModel>[]);
  }

  Future<List<ProjectModel>> getUserProjects(String userId) async {
    if (_isDummy) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => ProjectModel.fromJson(doc.data())).toList();
    } catch (_) {
      return [];
    }
  }
}
