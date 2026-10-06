import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_proxy_service.dart';
import 'firestore_image_service.dart' show fitDataUrlForFirestore;
import 'openrouter_service.dart';
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
  final AiProxyService _proxy;
  final OpenRouterService _openRouter;

  AiDesignService(this._proxy, this._openRouter);

  static const _pollinationsTimeout = Duration(seconds: 120);

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

    String? imageUrl;
    // 1) User's own OpenRouter key: full quality, reference-aware.
    if (_openRouter.isReady) {
      try {
        final photo =
            imageUrls.where((u) => u.startsWith('data:image/')).firstOrNull;
        imageUrl = await _openRouter.generateImage(
          prompt: fullPrompt,
          referenceDataUrl:
              photo != null ? await fitDataUrlForFirestore(photo) : null,
        );
      } on OpenRouterException catch (e) {
        debugPrint('OpenRouter image unavailable, falling back: $e');
      }
    }
    // 2) Server backend (photo-based edit).
    if (imageUrl == null) {
      final photo =
          imageUrls.where((u) => u.startsWith('data:image/')).firstOrNull;
      if (photo != null && _proxy.isAvailable) {
        try {
          imageUrl = await _proxy.generateDesign(
            imageDataUrl: await fitDataUrlForFirestore(photo),
            prompt: prompt,
            style: style,
            roomType: roomType,
          );
        } on AiProxyException catch (e) {
          debugPrint('Photo-based generation unavailable, using text-only: $e');
        }
      }
    }
    // 3) Free text-only fallback.
    imageUrl ??= await _generatePanoramicImage(fullPrompt);

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

    if (_openRouter.isReady) {
      try {
        return await _openRouter.generateImage(prompt: combinedPrompt);
      } on OpenRouterException catch (e) {
        debugPrint('OpenRouter chat-image unavailable, falling back: $e');
      }
    }
    return await _generatePanoramicImage(combinedPrompt);
  }

  Future<String> _generatePanoramicImage(String prompt) async {
    final encodedPrompt = Uri.encodeComponent(prompt);
    final encodedNegative = Uri.encodeComponent(_negativePrompt);

    final pollinationsUrl =
        'https://image.pollinations.ai/prompt/$encodedPrompt'
        '?width=2048&height=1024'
        '&model=zimage'
        '&enhance=true'
        '&negative_prompt=$encodedNegative'
        '&nologo=true'
        '&nofeed=true'
        '&seed=-1';

    final http.Response response;
    try {
      response = await http
          .get(Uri.parse(pollinationsUrl))
          .timeout(_pollinationsTimeout);
    } on TimeoutException {
      throw Exception('Image generation timed out. Please try again.');
    }

    if (response.statusCode != 200) {
      throw Exception('Image generation failed (${response.statusCode}).');
    }

    return 'data:image/jpeg;base64,${base64Encode(response.bodyBytes)}';
  }
}
