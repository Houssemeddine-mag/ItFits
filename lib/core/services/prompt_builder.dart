import 'dart:math';

import '../models/floor_plan_data.dart';

class PromptBuilder {
  static const Map<String, String> _styleDescriptions = {
    'Modern':
        'clean straight lines, neutral monochrome palette, minimal furniture with negative space, '
        'sleek matte and polished surfaces, hidden storage, floor-to-ceiling windows, '
        'minimal ornamentation, geometric forms, white oak or concrete floors',
    'Modern Minimalist':
        'clean straight lines, neutral monochrome palette, minimal furniture with negative space, '
        'sleek matte and polished surfaces, hidden storage, floor-to-ceiling windows, '
        'minimal ornamentation, geometric forms, white oak or concrete floors',
    'Scandinavian':
        'light ash and birch wood, pure white walls, cozy knitted textiles, abundant natural light, '
        'hygge atmosphere, organic shapes, functional beauty, sheepskin throws, '
        'ceramic vases, potted plants, warm ambient glow',
    'Industrial':
        'exposed red brick walls, blackened steel fixtures, polished concrete floors, '
        'loft-style open ductwork, Edison bulb pendant lights, reclaimed wood accents, '
        'leather furnishings, raw metal shelving, factory-style windows',
    'Bohemian':
        'rich jewel-toned fabrics, layered Moroccan and kilim rugs, macramé wall hangings, '
        'eclectic mix of vintage and global pieces, abundant indoor plants, '
        'warm terracotta and amber tones, patterned tiles, rattan furniture',
    'Mid-Century':
        'retro tapered-leg furniture, organic curved shapes, warm walnut and teak wood, '
        'bold mustard and teal accent colors, iconic Eames and Noguchi pieces, '
        'sunburst clocks, geometric patterns, open floor plan feel',
    'Mid-Century Modern':
        'retro tapered-leg furniture, organic curved shapes, warm walnut and teak wood, '
        'bold mustard and teal accent colors, iconic Eames and Noguchi pieces, '
        'sunburst clocks, geometric patterns, open floor plan feel',
    'Coastal':
        'breezy ocean-inspired palette, whitewashed wood and driftwood textures, '
        'natural linen and jute fibers, rattan and wicker accents, '
        'soft blue and seafoam green tones, nautical-inspired decor, '
        'airy open spaces with natural light, shell and coral accents',
    'Japandi':
        'Japanese wabi-sabi minimalism fused with Scandinavian functional warmth, '
        'natural unfinished materials, low-profile furniture, shoji screen dividers, '
        'indoor zen gardens, muted earth tones, bamboo and linen textures, '
        'ikebana arrangements, clean negative space',
    'Classic':
        'timeless elegance with symmetrical layouts and refined details, '
        'rich mahogany and cherry wood furniture, ornate crown molding, '
        'crystal chandeliers, Persian rugs, tufted upholstery, '
        'antique brass hardware, wainscoting, and formal balanced arrangements',
  };

  static const Map<String, String> _roomTypeDescriptions = {
    'Living Room':
        'spacious comfortable seating arrangement with sofa and armchairs facing each other, '
        'entertainment center or media wall, coffee table as centerpiece, '
        'ambient and task lighting zones, bookshelves or display cabinets',
    'Bedroom':
        'plush queen or king bed as focal point with upholstered headboard, '
        'bedside tables with reading lamps, wardrobe or walk-in closet area, '
        'cozy reading nook by window, soft layered bedding textures',
    'Kitchen':
        'modern fitted kitchen with island or breakfast bar, stone countertops, '
        'stainless steel appliances, pendant-lit dining area, '
        'organized pantry storage, under-cabinet task lighting',
    'Bathroom':
        'spa-like sanctuary with freestanding soaking tub or walk-in rain shower, '
        'floating vanity with vessel sink, backlit mirror, '
        'natural stone tiles, heated towel rail, ambient mood lighting',
    'Dining Room':
        'elegant dining table seating six to eight, statement chandelier overhead, '
        'buffet or sideboard for serving, artwork on feature wall, '
        'cohesive place settings, warm intimate lighting',
    'Home Office':
        'ergonomic executive desk with task lamp, high-back chair, '
        'built-in bookshelves and filing, dual monitor setup, '
        'inspiration board, plants for productivity, focused lighting',
    'Entryway':
        'welcoming console table with decorative mirror above, '
        'coat hooks and umbrella stand, shoe storage bench, '
        'statement pendant light, fresh flowers, inviting first impression',
    'Garden':
        'lush landscaped outdoor living space with comfortable patio furniture, '
        'pergola or covered seating area, ambient string lights, '
        'raised planters with herbs and flowers, water feature, stone pathway',
    'Toilet':
        'compact efficient WC with wall-hung toilet, small floating vanity, '
        'space-saving storage, good ventilation, clean minimal fixtures',
  };

  static String buildPrompt({
    required String style,
    required String roomType,
    String? paletteDescription,
    List<String>? preferences,
    FloorPlanData? floorPlan,
  }) {
    final styleDesc = _styleDescriptions[style] ?? style;
    final roomDesc = _roomTypeDescriptions[roomType] ?? roomType;

    final parts = <String>[];

    parts.add(
      'A stunning $style interior design photograph of a beautifully designed $roomType. '
      'The space features $styleDesc. '
      '$roomDesc.',
    );

    if (floorPlan != null) {
      parts.add(_buildSpatialDescription(floorPlan, roomType));
    }

    if (paletteDescription != null && paletteDescription.isNotEmpty) {
      parts.add(
        'Cohesive color palette featuring $paletteDescription tones '
        'harmoniously blended throughout the space.',
      );
    }

    if (preferences != null && preferences.isNotEmpty) {
      final uniquePrefs = preferences.toSet().toList();
      parts.add('Special design requirements: ${uniquePrefs.join("; ")}.');
    }

    if (floorPlan != null && floorPlan.windows.isNotEmpty) {
      final windowDir = _getWindowDirection(floorPlan);
      parts.add(
        'Abundant natural light streaming in from the $windowDir through large windows, '
        'casting soft directional shadows across the floor and furniture. '
        'Warm golden hour sunlight creates depth and dimension. '
        'Realistic light bounce and ambient fill light in shadow areas.',
      );
    } else {
      parts.add(
        'Beautifully balanced lighting with warm overhead ambient light '
        'complemented by accent and task lighting. '
        'Soft shadows add depth and realism to every surface.',
      );
    }

    parts.add(
      'Every surface displays photorealistic material quality: '
      'wood grain visible on furniture, fabric weave texture on upholstery, '
      'subtle reflections on glass and polished surfaces, '
      'matte finish on painted walls with slight texture, '
      'stone veining on countertops, metal patina on fixtures.',
    );

    parts.add(
      'Professional interior photography composition with leading lines, '
      'rule of thirds, and depth layering from foreground to background. '
      'Inviting lived-in atmosphere with curated decorative objects, '
      'fresh flowers, stacked books, and subtle personal touches. '
      'The room feels real, warm, and aspirational.',
    );

    return parts.join(' ');
  }

  static String _buildSpatialDescription(FloorPlanData floorPlan, String roomType) {
    final buffer = StringBuffer();

    buffer.writeln(
      'Room dimensions: ${floorPlan.roomWidth.toStringAsFixed(1)} meters wide by '
      '${floorPlan.roomDepth.toStringAsFixed(1)} meters deep '
      '(${floorPlan.area.toStringAsFixed(1)} square meters total).',
    );

    if (floorPlan.walls.isNotEmpty) {
      buffer.writeln(
        'The room has ${floorPlan.walls.length} walls defining the space.',
      );
    }

    if (floorPlan.windows.isNotEmpty) {
      for (final window in floorPlan.windows) {
        final dir = _getWindowDirectionForWall(floorPlan, window.wallIndex);
        final windowTypeName = _windowTypeName(window.type);
        buffer.writeln(
          'A $windowTypeName on the $dir wall at position '
          '${(window.positionAlongWall * 100).round()}% along the wall length, '
          'allowing natural light to illuminate the space from the $dir.',
        );
      }
    }

    if (floorPlan.doors.isNotEmpty) {
      for (final door in floorPlan.doors) {
        final dir = _getWindowDirectionForWall(floorPlan, door.wallIndex);
        final swingName = _doorSwingName(door.swing);
        buffer.writeln(
          'A door on the $dir wall swinging $swingName, '
          'with clear walking path from the entrance.',
        );
      }
    }

    if (floorPlan.outlets.isNotEmpty) {
      final firstOutlet = floorPlan.outlets.first;
      final outletDir = _getWindowDirectionForWall(floorPlan, firstOutlet.wallIndex);
      buffer.writeln(
        'Power outlets on the $outletDir wall — ideal for placing electronics, '
        'entertainment systems, or workstations in that zone.',
      );
    }

    buffer.writeln(floorPlan.toFurnitureGuidance(roomType));

    return buffer.toString();
  }

  static String buildDesignPrompt({
    required FloorPlanData floorPlan,
    required String style,
    required String roomType,
    List<int>? palette,
    List<String>? preferences,
  }) {
    final paletteDescription =
        palette != null ? getPaletteDescription(palette) : null;
    return buildPrompt(
      style: style,
      roomType: roomType,
      paletteDescription: paletteDescription,
      preferences: preferences,
      floorPlan: floorPlan,
    );
  }

  static String buildPanoramicDesignPrompt({
    required FloorPlanData floorPlan,
    required String style,
    required String roomType,
    List<int>? palette,
    List<String>? preferences,
  }) {
    final styleDesc = _styleDescriptions[style] ?? style;
    final roomDesc = _roomTypeDescriptions[roomType] ?? roomType;
    final paletteDesc = palette != null ? getPaletteDescription(palette) : '';

    final parts = <String>[];

    parts.add(
      'Equirectangular 360-degree panoramic interior photograph of a $roomType. '
      'This is a seamless spherical projection showing ALL walls simultaneously. '
      'The left edge of the image connects seamlessly to the right edge. '
      'The top is the ceiling, the bottom is the floor. '
      'The space features $styleDesc. $roomDesc.',
    );

    parts.add(_buildPanoramicSpatialDescription(floorPlan, roomType));

    if (paletteDesc.isNotEmpty) {
      parts.add(
        'Cohesive color palette featuring $paletteDesc tones '
        'harmoniously blended throughout the entire space.',
      );
    }

    if (preferences != null && preferences.isNotEmpty) {
      final uniquePrefs = preferences.toSet().toList();
      parts.add('Special design requirements: ${uniquePrefs.join("; ")}.');
    }

    if (floorPlan.windows.isNotEmpty) {
      final windowDir = _getWindowDirection(floorPlan);
      parts.add(
        'Natural light streaming from the $windowDir side through windows, '
        'balanced with warm ambient artificial lighting filling the rest of the room. '
        'Realistic shadows cast from multiple light sources. '
        'No area of the panorama should be overly dark or blown out.',
      );
    } else {
      parts.add(
        'Beautifully balanced omnidirectional lighting with warm overhead ambient light '
        'complemented by accent and task lighting evenly distributed around the room. '
        'Soft shadows add depth and realism to every surface.',
      );
    }

    parts.add(
      'Every surface displays photorealistic material quality: '
      'wood grain, fabric weave, glass reflections, stone veining, metal patina. '
      'The panoramic view should feel immersive and lifelike from every angle.',
    );

    parts.add(
      'Professional panoramic interior photography. '
      'The room feels real, warm, and aspirational when viewed in a 360° spherical viewer.',
    );

    return parts.join(' ');
  }

  static String _buildPanoramicSpatialDescription(FloorPlanData floorPlan, String roomType) {
    final buffer = StringBuffer();

    buffer.writeln(
      'Room dimensions: ${floorPlan.roomWidth.toStringAsFixed(1)}m wide × '
      '${floorPlan.roomDepth.toStringAsFixed(1)}m deep '
      '(${floorPlan.area.toStringAsFixed(1)}m²). '
      'Ceiling height: ${floorPlan.ceilingHeight.toStringAsFixed(1)}m.',
    );

    final wallNames = ['south (bottom of panorama)', 'east (right side)', 'north (top of panorama)', 'west (left side)'];

    for (int i = 0; i < 4; i++) {
      final wallName = wallNames[i];
      final wallElements = <String>[];

      for (final window in floorPlan.windows.where((w) => w.wallIndex == i)) {
        final pos = '${(window.positionAlongWall * 100).round()}%';
        wallElements.add(
          'A ${_windowTypeName(window.type)} ($pos along wall, '
          '${window.width.toStringAsFixed(1)}m wide × ${window.height.toStringAsFixed(1)}m tall)',
        );
      }

      for (final door in floorPlan.doors.where((d) => d.wallIndex == i)) {
        final pos = '${(door.positionAlongWall * 100).round()}%';
        wallElements.add(
          'A ${_doorSwingName(door.swing)} door ($pos along wall, '
          '${door.width.toStringAsFixed(1)}m wide)',
        );
      }

      if (wallElements.isNotEmpty) {
        buffer.writeln('The $wallName wall: ${wallElements.join(", ")}.');
      }
    }

    buffer.writeln(floorPlan.toFurnitureGuidance(roomType));

    return buffer.toString();
  }

  static String buildChatPrompt({
    required FloorPlanData floorPlan,
    required String roomType,
    required String userMessage,
    String? currentStyle,
    List<int>? palette,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('You are an expert interior designer AI assistant.');
    buffer.writeln('The user has a $roomType with these dimensions:');
    buffer.writeln(floorPlan.toPromptDescription());
    buffer.writeln();
    buffer.writeln('Room layout guidance:');
    buffer.writeln(floorPlan.toFurnitureGuidance(roomType));
    buffer.writeln();
    if (currentStyle != null) {
      buffer.writeln('Current chosen style: $currentStyle');
    }
    if (palette != null && palette.isNotEmpty) {
      buffer.writeln('Color palette: ${getPaletteDescription(palette)}');
    }
    buffer.writeln();
    buffer.writeln('User message: $userMessage');
    buffer.writeln();
    buffer.writeln(
      'Respond as a helpful interior designer. '
      'Give specific, actionable advice based on the room layout. '
      'Mention specific wall positions, dimensions, and placement suggestions.',
    );

    return buffer.toString();
  }

  static String _getWindowDirection(FloorPlanData floorPlan) {
    if (floorPlan.windows.isEmpty) return 'unknown';
    return _getWindowDirectionForWall(floorPlan, floorPlan.windows.first.wallIndex);
  }

  static String _getWindowDirectionForWall(FloorPlanData floorPlan, int wallIndex) {
    if (wallIndex < floorPlan.walls.length) {
      final angle = floorPlan.walls[wallIndex].angle;
      if (angle.abs() < 0.1) return 'south';
      if ((angle - pi / 2).abs() < 0.1) return 'west';
      if ((angle - pi).abs() < 0.1 || (angle + pi).abs() < 0.1) return 'north';
      if ((angle + pi / 2).abs() < 0.1) return 'east';
    }
    return 'side';
  }

  static String _windowTypeName(WindowType type) {
    switch (type) {
      case WindowType.standard:
        return 'standard window';
      case WindowType.bay:
        return 'bay window';
      case WindowType.sliding:
        return 'sliding window';
      case WindowType.floorToCeiling:
        return 'floor-to-ceiling window';
      case WindowType.arched:
        return 'arched window';
    }
  }

  static String _doorSwingName(DoorSwing swing) {
    switch (swing) {
      case DoorSwing.left:
        return 'left';
      case DoorSwing.right:
        return 'right';
      case DoorSwing.double:
        return 'double';
      case DoorSwing.sliding:
        return 'sliding';
    }
  }

  static String getPaletteDescription(List<int> palette) {
    if (palette.isEmpty) return '';

    final colorNames = <String>[];
    for (final colorValue in palette) {
      final r = (colorValue >> 16) & 0xFF;
      final g = (colorValue >> 8) & 0xFF;
      final b = colorValue & 0xFF;
      colorNames.add(_getColorName(r, g, b));
    }

    if (colorNames.length == 1) {
      return '${colorNames[0]} accents';
    } else if (colorNames.length == 2) {
      return '${colorNames[0]} and ${colorNames[1]}';
    } else {
      final last = colorNames.removeLast();
      return '${colorNames.join(", ")} and $last';
    }
  }

  static String _getColorName(int r, int g, int b) {
    if (r > 200 && g > 200 && b > 200) return 'white';
    if (r < 50 && g < 50 && b < 50) return 'black';
    if (r > 180 && g < 100 && b < 100) return 'red';
    if (r < 100 && g > 180 && b < 100) return 'green';
    if (r < 100 && g < 100 && b > 180) return 'blue';
    if (r > 200 && g > 180 && b < 100) return 'warm yellow';
    if (r > 200 && g > 140 && b < 100) return 'terracotta';
    if (r > 180 && g > 140 && b > 100) return 'beige';
    if (r > 150 && g > 150 && b > 150) return 'gray';
    if (r > 100 && g > 140 && b > 180) return 'light blue';
    if (r > 140 && g > 100 && b > 100) return 'dusty rose';
    if (r > 100 && g > 140 && b > 100) return 'sage green';
    if (r > 180 && g > 120 && b > 80) return 'warm brown';
    if (r > 200 && g > 200 && b > 220) return 'cool white';
    if (r > 120 && g > 100 && b > 140) return 'lavender';
    return 'neutral';
  }
}
