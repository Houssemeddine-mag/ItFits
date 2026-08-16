import 'dart:convert';
import 'package:http/http.dart' as http;

import 'prompt_builder.dart';
import '../models/floor_plan_data.dart';

class GeneratedDesignResult {
  final String imageUrl;
  final String style;
  final String prompt;
  final DateTime createdAt;

  GeneratedDesignResult({
    required this.imageUrl,
    required this.style,
    required this.prompt,
    required this.createdAt,
  });
}

class AiDesignService {
  AiDesignService();

  static const String _negativePrompt =
      'worst quality, blurry, low resolution, pixelated, distorted, '
      'ugly, deformed, disfigured, poor lighting, overexposed, underexposed, '
      'cartoon, anime, sketch, drawing, illustration, text, watermark, logo, '
      'noise, grain, artifacts, jpeg artifacts, out of frame, cropped, '
      'bad proportions, malformed furniture, floating objects, unrealistic shadows, '
      'flat image, non-panoramic, standard aspect ratio';

  static const String _panoramicQualitySuffix =
      '360-degree equirectangular panoramic photograph of a complete room interior. '
      'The image must be a seamless 360° horizontal panorama showing ALL four walls, '
      'floor, and ceiling in a single continuous equirectangular projection. '
      'The left edge wraps seamlessly to the right edge. '
      'Masterpiece interior photography. '
      'Professional architectural photography with perfect exposure. '
      'Soft natural lighting with realistic shadows and ambient occlusion. '
      'Ray-traced global illumination, physically accurate materials. '
      'High dynamic range, rich color grading, film-like tonality. '
      '8K resolution detail, tack sharp focus, zero noise. '
      'Published in Architectural Digest magazine. '
      'Equirectangular projection format suitable for 360° spherical viewing.';

  Future<GeneratedDesignResult> generateDesign({
    required List<String> imageUrls,
    required String style,
    required String roomType,
    required List<int> palette,
    List<String>? preferences,
    FloorPlanData? floorPlan,
  }) async {
    final prompt = PromptBuilder.buildPanoramicDesignPrompt(
      floorPlan: floorPlan ?? FloorPlanData.defaultRoom(),
      style: style,
      roomType: roomType,
      palette: palette,
      preferences: preferences,
    );

    final fullPrompt = '$prompt $_panoramicQualitySuffix';

    final imageUrl = await _generatePanoramicImage(fullPrompt);

    return GeneratedDesignResult(
      imageUrl: imageUrl,
      style: style,
      prompt: prompt,
      createdAt: DateTime.now(),
    );
  }

  Future<String> generateChatImage({
    required FloorPlanData floorPlan,
    required String style,
    required String roomType,
    required String description,
  }) async {
    final prompt = PromptBuilder.buildPanoramicDesignPrompt(
      floorPlan: floorPlan,
      style: style,
      roomType: roomType,
    );

    final combinedPrompt = '$prompt $description $_panoramicQualitySuffix';

    return await _generatePanoramicImage(combinedPrompt);
  }

  Future<String> _generatePanoramicImage(String prompt) async {
    final encodedPrompt = Uri.encodeComponent(prompt);
    final encodedNegative = Uri.encodeComponent(_negativePrompt);

    // 2:1 equirectangular ratio for proper 360° panoramic images
    final pollinationsUrl =
        'https://image.pollinations.ai/prompt/$encodedPrompt'
        '?width=2048&height=1024'
        '&model=zimage'
        '&enhance=true'
        '&negative_prompt=$encodedNegative'
        '&nologo=true'
        '&nofeed=true'
        '&seed=-1';

    final response = await http.get(Uri.parse(pollinationsUrl));

    if (response.statusCode != 200) {
      throw Exception('AI generation failed: ${response.statusCode}');
    }

    return 'data:image/jpeg;base64,${base64Encode(response.bodyBytes)}';
  }
}
