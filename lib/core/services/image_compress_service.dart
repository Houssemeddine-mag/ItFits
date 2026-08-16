import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCompressService {
  static const int _maxLongestEdge = 1200;
  static const int _jpegQuality = 80;

  static Future<File> compressImage(File imageFile) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      targetPath,
      minWidth: _maxLongestEdge,
      minHeight: _maxLongestEdge,
      quality: _jpegQuality,
      format: CompressFormat.jpeg,
    );

    if (result == null) throw Exception('Image compression failed');
    return File(result.path);
  }

  static Future<List<File>> compressImages(List<File> images) async {
    final results = <File>[];
    for (final image in images) {
      results.add(await compressImage(image));
    }
    return results;
  }

  static Future<List<int>> compressToBytes(File imageFile) async {
    final compressed = await compressImage(imageFile);
    return compressed.readAsBytes();
  }
}
