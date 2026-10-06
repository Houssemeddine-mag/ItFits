import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

const int _maxInlineJpegBytes = 680 * 1024;

Future<Uint8List> fitImageForFirestore(Uint8List bytes) async {
  if (bytes.length <= _maxInlineJpegBytes) return bytes;
  return Isolate.run(() {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    var width = math.min(decoded.width, 2048);
    var quality = 85;
    while (true) {
      final resized = width < decoded.width
          ? img.copyResize(decoded,
              width: width, interpolation: img.Interpolation.average)
          : decoded;
      final out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      if (out.length <= _maxInlineJpegBytes || width <= 512) return out;
      width = (width * 0.8).round();
      quality = math.max(70, quality - 5);
    }
  });
}

Future<String> fitDataUrlForFirestore(String url) async {
  if (!url.startsWith('data:') || url.length <= _maxInlineJpegBytes) {
    return url;
  }
  final bytes = base64Decode(url.substring(url.indexOf(',') + 1));
  final fitted = await fitImageForFirestore(bytes);
  if (identical(fitted, bytes)) return url;
  return 'data:image/jpeg;base64,${base64Encode(fitted)}';
}

/// Small card thumbnail (~480px wide, quality 70, typically 30-60KB).
/// Stored inline on the project doc (`panoramaUrl` + `generatedDesigns`)
/// so History/Home cards render instantly without reading subcollections
/// or decoding multi-MB data URLs on the UI thread.
/// The full fitted image stays in the `designs` subcollection.
Future<String> fitDataUrlThumbnail(String url, {int maxWidth = 480}) async {
  if (!url.startsWith('data:image')) return url;
  try {
    final comma = url.indexOf(',');
    if (comma < 0) return url;
    final bytes = base64Decode(url.substring(comma + 1));
    if (bytes.length <= 60 * 1024) return url;
    final thumb = await Isolate.run(() {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final scale = maxWidth / decoded.width;
      final resized = scale < 1
          ? img.copyResize(decoded,
              width: maxWidth, interpolation: img.Interpolation.average)
          : decoded;
      return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
    });
    if (thumb == null || thumb.isEmpty) return url;
    return 'data:image/jpeg;base64,${base64Encode(thumb)}';
  } catch (_) {
    return url;
  }
}

class CapturedImageData {
  final String id;
  final String base64Data;
  final int order;
  final DateTime createdAt;

  CapturedImageData({
    required this.id,
    required this.base64Data,
    required this.order,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'base64Data': base64Data,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CapturedImageData.fromMap(Map<String, dynamic> map) =>
      CapturedImageData(
        id: map['id'] as String? ?? '',
        base64Data: map['base64Data'] as String? ?? '',
        order: (map['order'] as num?)?.toInt() ?? 0,
        createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      );
}

class GeneratedDesignData {
  final String id;
  final String imageUrl;
  final String style;
  final String prompt;
  final DateTime createdAt;

  GeneratedDesignData({
    required this.id,
    required this.imageUrl,
    required this.style,
    required this.prompt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'imageUrl': imageUrl,
        'style': style,
        'prompt': prompt,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GeneratedDesignData.fromMap(Map<String, dynamic> map) =>
      GeneratedDesignData(
        id: map['id'] as String? ?? '',
        imageUrl: map['imageUrl'] as String? ?? '',
        style: map['style'] as String? ?? '',
        prompt: map['prompt'] as String? ?? '',
        createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      );
}

/// Accepts ISO strings (current), Firestore Timestamps (serverTimestamp
/// writes), DateTime and epoch millis — never throws.
DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  if (value is num) {
    final ms = value.toInt();
    return DateTime.fromMillisecondsSinceEpoch(ms < 100000000000 ? ms * 1000 : ms);
  }
  try {
    final dynamic dyn = value;
    return dyn.toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}

class FirestoreImageService {
  final FirebaseFirestore? _firestore;
  final Uuid _uuid = const Uuid();
  final bool _isDummy;

  FirestoreImageService(FirebaseFirestore firestore)
      : _firestore = firestore,
        _isDummy = false;

  FirestoreImageService.dummy()
      : _firestore = null,
        _isDummy = true;

  String _imagesCollection(String userId, String projectId) =>
      'users/$userId/projects/$projectId/images';

  String _designsCollection(String userId, String projectId) =>
      'users/$userId/projects/$projectId/designs';

  Future<CapturedImageData> saveCapturedImage({
    required String userId,
    required String projectId,
    required List<int> imageBytes,
    required int order,
  }) async {
    if (_isDummy) {
      return CapturedImageData(
        id: _uuid.v4(),
        base64Data: base64Encode(imageBytes),
        order: order,
        createdAt: DateTime.now(),
      );
    }
    final id = _uuid.v4();
    final base64Data = base64Encode(
        await fitImageForFirestore(Uint8List.fromList(imageBytes)));
    final data = CapturedImageData(
      id: id,
      base64Data: base64Data,
      order: order,
      createdAt: DateTime.now(),
    );

    await _firestore!
        .collection(_imagesCollection(userId, projectId))
        .doc(id)
        .set(data.toMap());

    return data;
  }

  Future<List<CapturedImageData>> saveCapturedImages({
    required String userId,
    required String projectId,
    required List<List<int>> imageBytesList,
  }) async {
    if (_isDummy) {
      return List.generate(
        imageBytesList.length,
        (i) => CapturedImageData(
          id: _uuid.v4(),
          base64Data: base64Encode(imageBytesList[i]),
          order: i,
          createdAt: DateTime.now(),
        ),
      );
    }
    final results = <CapturedImageData>[];
    for (int i = 0; i < imageBytesList.length; i++) {
      results.add(await saveCapturedImage(
        userId: userId,
        projectId: projectId,
        imageBytes: imageBytesList[i],
        order: i,
      ));
    }
    return results;
  }

  Future<List<CapturedImageData>> getCapturedImages({
    required String userId,
    required String projectId,
  }) async {
    if (_isDummy) return [];
    final snapshot = await _firestore!
        .collection(_imagesCollection(userId, projectId))
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => CapturedImageData.fromMap(doc.data()))
        .toList();
  }

  Stream<List<CapturedImageData>> watchCapturedImages({
    required String userId,
    required String projectId,
  }) {
    if (_isDummy) return Stream.value(const <CapturedImageData>[]);
    return _firestore!
        .collection(_imagesCollection(userId, projectId))
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CapturedImageData.fromMap(doc.data()))
            .toList());
  }

  Future<GeneratedDesignData> saveGeneratedDesign({
    required String userId,
    required String projectId,
    required String imageUrl,
    required String style,
    required String prompt,
  }) async {
    if (_isDummy) {
      return GeneratedDesignData(
        id: _uuid.v4(),
        imageUrl: imageUrl,
        style: style,
        prompt: prompt,
        createdAt: DateTime.now(),
      );
    }
    final id = _uuid.v4();
    final data = GeneratedDesignData(
      id: id,
      imageUrl: await fitDataUrlForFirestore(imageUrl),
      style: style,
      prompt: prompt,
      createdAt: DateTime.now(),
    );

    await _firestore!
        .collection(_designsCollection(userId, projectId))
        .doc(id)
        .set(data.toMap());

    return data;
  }

  Future<List<GeneratedDesignData>> getGeneratedDesigns({
    required String userId,
    required String projectId,
  }) async {
    if (_isDummy) return [];
    final snapshot = await _firestore!
        .collection(_designsCollection(userId, projectId))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => GeneratedDesignData.fromMap(doc.data()))
        .toList();
  }

  Stream<List<GeneratedDesignData>> watchGeneratedDesigns({
    required String userId,
    required String projectId,
  }) {
    if (_isDummy) return Stream.value(const <GeneratedDesignData>[]);
    return _firestore!
        .collection(_designsCollection(userId, projectId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GeneratedDesignData.fromMap(doc.data()))
            .toList());
  }

  Future<void> deleteCapturedImages({
    required String userId,
    required String projectId,
  }) async {
    if (_isDummy) return;
    final batch = _firestore!.batch();
    final snapshot =
        await _firestore!.collection(_imagesCollection(userId, projectId)).get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteGeneratedDesigns({
    required String userId,
    required String projectId,
  }) async {
    if (_isDummy) return;
    final batch = _firestore!.batch();
    final snapshot =
        await _firestore!.collection(_designsCollection(userId, projectId)).get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
