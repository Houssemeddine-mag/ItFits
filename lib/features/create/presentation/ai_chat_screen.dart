import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itfits/core/models/floor_plan_data.dart';
import 'package:itfits/core/services/ai_proxy_service.dart';
import 'package:itfits/core/services/providers.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imageUrl;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageUrl,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);
final isChatLoadingProvider = StateProvider<bool>((ref) => false);

class AiChatScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const AiChatScreen({super.key, required this.onComplete});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final messages = ref.read(chatMessagesProvider);
    if (messages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendWelcomeMessage();
      });
    }
  }

  void _sendWelcomeMessage() {
    final floorPlan = ref.read(floorPlanDataProvider);
    final styleName = ref.read(selectedStyleNameProvider);

    String welcomeText;
    if (floorPlan != null) {
      welcomeText = "Hello! I'm your personal interior designer.\n\n"
          "I can see your ${floorPlan.roomWidth.toStringAsFixed(1)}m × ${floorPlan.roomDepth.toStringAsFixed(1)}m room "
          "with ${floorPlan.windows.length} window(s) and ${floorPlan.doors.length} door(s).\n\n"
          "${styleName.isNotEmpty ? "I see you've chosen $styleName style. " : ""}"
          "I can help you with:\n"
          "• Furniture placement suggestions\n"
          "• Color palette recommendations\n"
          "• Lighting design ideas\n"
          "• Space optimization tips\n"
          "• Step-by-step redesign instructions\n\n"
          "What would you like to explore?";
    } else {
      welcomeText = "Hello! I'm your personal interior designer. "
          "Tell me about your room and I'll help you redesign it!";
    }

    ref.read(chatMessagesProvider.notifier).state = [
      ChatMessage(text: welcomeText, isUser: false),
    ];
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      ref.read(chatMessagesProvider.notifier).state = [
        ...ref.read(chatMessagesProvider),
        ChatMessage(text: text, isUser: true),
      ];
    });

    final currentPrefs = List<String>.from(ref.read(aiPreferencesProvider));
    currentPrefs.add(text);
    ref.read(aiPreferencesProvider.notifier).state = currentPrefs;

    _scrollToBottom();
    _getAiResponse(text);
  }

  void _getAiResponse(String userMessage) async {
    ref.read(isChatLoadingProvider.notifier).state = true;

    try {
      final floorPlan = ref.read(floorPlanDataProvider);
      final styleName = ref.read(selectedStyleNameProvider);
      final roomType = ref.read(currentProjectProvider)?.roomType ?? 'Room';
      final palette = ref.read(selectedPaletteProvider2);
      final proxy = ref.read(aiProxyServiceProvider);

      final systemPrompt = 'You are an expert interior design agent with full access to the user\'s project. '
          'You can see their room type ($roomType), floor plan, style choice, and color palette. '
          '${styleName.isNotEmpty ? "Chosen style: $styleName. " : ""}'
          '${palette.isNotEmpty ? "Color palette includes ${palette.length} colors. " : ""}'
          '${floorPlan != null ? "Room: ${floorPlan.roomWidth.toStringAsFixed(1)}m × ${floorPlan.roomDepth.toStringAsFixed(1)}m, "
              "${floorPlan.windows.length} window(s), ${floorPlan.doors.length} door(s). "
              "${floorPlan.toPromptDescription()}" : ""}'
          '\nYour capabilities:\n'
          '- Advise on furniture placement with specific positions and dimensions\n'
          '- Recommend color palettes and material combinations\n'
          '- Suggest lighting design and fixture placement\n'
          '- Optimize space usage and traffic flow\n'
          '- Provide step-by-step redesign instructions\n'
          '- Recommend specific furniture pieces and decor items\n'
          '\nRules:\n'
          '- Always reference specific walls, dimensions, and positions from the floor plan\n'
          '- Give actionable advice the user can immediately apply\n'
          '- Be concise but thorough — use bullet points\n'
          '- When suggesting furniture, mention approximate dimensions that fit the space\n'
          '- Consider natural light from windows and traffic from doors\n';

      if (!proxy.isAvailable) {
        throw const AiProxyException('AI backend unavailable');
      }

      final messages = <Map<String, Object>>[
        {'role': 'system', 'content': systemPrompt},
      ];
      final chatHistory = ref.read(chatMessagesProvider);
      for (final msg in chatHistory.skip(max(0, chatHistory.length - 20))) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      final reply = await proxy.chat(messages);

      ref.read(chatMessagesProvider.notifier).state = [
        ...ref.read(chatMessagesProvider),
        ChatMessage(text: reply, isUser: false),
      ];
    } catch (e) {
      final floorPlan = ref.read(floorPlanDataProvider);
      final styleName = ref.read(selectedStyleNameProvider);
      final roomType = ref.read(currentProjectProvider)?.roomType ?? 'Room';
      ref.read(chatMessagesProvider.notifier).state = [
        ...ref.read(chatMessagesProvider),
        ChatMessage(text: _getFallbackResponse(userMessage, floorPlan, styleName, roomType), isUser: false),
      ];
    } finally {
      ref.read(isChatLoadingProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  String _getFallbackResponse(String userMessage, FloorPlanData? floorPlan, String styleName, String roomType) {
    final lower = userMessage.toLowerCase();

    if (lower.contains('furniture') || lower.contains('place') || lower.contains('put')) {
      if (floorPlan != null) return _getFurnitureAdvice(floorPlan, roomType);
      return "To give you the best furniture placement advice, "
          "please first create a floor plan with walls, doors, and windows.";
    }
    if (lower.contains('color') || lower.contains('palette') || lower.contains('paint')) {
      return _getColorAdvice(styleName, roomType);
    }
    if (lower.contains('light') || lower.contains('lamp')) {
      if (floorPlan != null && floorPlan.windows.isNotEmpty) {
        final windowDir = _getWindowDirection(floorPlan);
        return "Your room has natural light from the $windowDir wall.\n\n"
            "• Place seating/work areas near the $windowDir wall\n"
            "• Add ambient lighting on the opposite wall\n"
            "• Consider sheer curtains to diffuse harsh sunlight";
      }
      return "Lighting is crucial! Create a floor plan so I can see where your windows are.";
    }
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return "Hello! I'm ready to help you design your perfect $roomType. What would you like to focus on?";
    }
    return "I'd be happy to help! Could you tell me more about what you'd like advice on — "
        "furniture placement, colors, lighting, or something else?";
  }

  String _getFurnitureAdvice(FloorPlanData floorPlan, String roomType) {
    final buffer = StringBuffer();
    buffer.writeln("Here's my furniture placement advice for your $roomType:\n");

    if (floorPlan.windows.isNotEmpty) {
      final windowDir = _getWindowDirection(floorPlan);
      buffer.writeln("📍 Natural Light Zone ($windowDir wall):");
      buffer.writeln("Place your primary activity area here — "
          "a desk for office, bed facing away for bedroom, or seating for living room.\n");
    }

    if (floorPlan.doors.isNotEmpty) {
      final doorDir = _getDoorDirection(floorPlan);
      buffer.writeln("🚪 Traffic Flow (${doorDir} wall entrance):");
      buffer.writeln("Keep a clear path (min 0.8m) from the door. "
          "Don't block the swing radius of the door.\n");
    }

    if (floorPlan.outlets.isNotEmpty) {
      buffer.writeln("🔌 Electronics Zone (${_getOutletDirection(floorPlan)} wall):");
      buffer.writeln("Place your TV, desk, or appliances near the power outlets. "
          "Consider a power strip for flexibility.\n");
    }

    buffer.writeln("📐 Space Optimization:");
    buffer.writeln("• Room area: ${floorPlan.area.toStringAsFixed(1)} m²");
    if (floorPlan.area < 10) {
      buffer.writeln("• This is a compact space — use multi-functional furniture "
          "(storage ottoman, wall-mounted desk, Murphy bed)");
    } else if (floorPlan.area < 20) {
      buffer.writeln("• Good sized room — balance furniture with open space. "
          "Aim for 60% furniture, 40% open floor.");
    } else {
      buffer.writeln("• Spacious room — create distinct zones with furniture groupings "
          "and area rugs.");
    }

    return buffer.toString();
  }

  String _getColorAdvice(String styleName, String roomType) {
    final styles = {
      'Modern Minimalist': "For Modern Minimalist, stick to:\n"
          "• Base: White, light gray, or warm white walls\n"
          "• Accent: Black, charcoal, or one bold color\n"
          "• Wood: Light oak or walnut for warmth",
      'Scandinavian': "For Scandinavian style:\n"
          "• Base: Pure white walls with light wood floors\n"
          "• Accent: Soft blue, dusty rose, or sage green\n"
          "• Textiles: Cream, beige, natural linen",
      'Industrial': "For Industrial style:\n"
          "• Base: Exposed brick, concrete gray, or charcoal\n"
          "• Accent: Rust orange, deep green, or brass\n"
          "• Wood: Reclaimed or dark stained",
      'Bohemian': "For Bohemian style:\n"
          "• Base: Warm white or cream\n"
          "• Accent: Rich jewel tones — emerald, ruby, sapphire\n"
          "• Patterns: Mix Moroccan, ikat, and tribal prints",
      'Japandi': "For Japandi style:\n"
          "• Base: Warm white, soft beige\n"
          "• Accent: Muted sage, dusty blue, warm gray\n"
          "• Wood: Light ash, bamboo, or light walnut",
    };

    return styles[styleName] ??
        "For a cohesive look, I recommend:\n"
        "• Choose 3 main colors: 60% dominant, 30% secondary, 10% accent\n"
        "• Keep walls neutral and add color through furniture and decor\n"
        "• Use the 60-30-10 rule for a balanced palette";
  }

  String _getStepByStepInstructions(FloorPlanData floorPlan, String styleName, String roomType) {
    return "📋 Step-by-Step Redesign Plan for your $roomType:\n\n"
        "Step 1: Clear the Space\n"
        "• Remove all existing furniture and decor\n"
        "• Clean walls and floors thoroughly\n"
        "• Repair any damage\n\n"
        "Step 2: Paint & Walls\n"
        "• Paint walls in your $styleName base color\n"
        "• ${floorPlan.walls.length > 4 ? 'Consider accent wall on the longest wall' : 'Consider one accent wall'}\n\n"
        "Step 3: Flooring\n"
        "• Install or refinish flooring\n"
        "• Add area rug to define the main zone\n\n"
        "Step 4: Major Furniture\n"
        "• Place the largest piece first (${_getMajorFurniture(roomType)})\n"
        "• Position near ${floorPlan.windows.isNotEmpty ? 'the window for natural light' : 'the entrance for easy access'}\n\n"
        "Step 5: Secondary Furniture\n"
        "• Add complementary pieces\n"
        "• Ensure 0.8m walkways between furniture\n\n"
        "Step 6: Lighting\n"
        "• Install overhead lighting\n"
        "• Add task lighting (${floorPlan.outlets.isNotEmpty ? 'near outlets on ' + _getOutletDirection(floorPlan) + ' wall' : 'near activity areas'})\n"
        "• Add accent lighting for ambiance\n\n"
        "Step 7: Decor & Styling\n"
        "• Add artwork, plants, and decorative objects\n"
        "• Style shelves and surfaces\n"
        "• Add final textile layers (cushions, throws)";
  }

  String _getGeneralTips(FloorPlanData floorPlan, String styleName, String roomType) {
    final tips = <String>[];

    tips.add("💡 Pro Tips for your ${floorPlan.roomWidth.toStringAsFixed(1)}×${floorPlan.roomDepth.toStringAsFixed(1)}m $roomType:\n");

    if (floorPlan.area < 12) {
      tips.add("• Small space hack: Use furniture with visible legs — "
          "it creates visual space and makes the room feel larger");
      tips.add("• Mirrors opposite windows double the natural light");
      tips.add("• Wall-mounted storage frees up floor space");
    } else {
      tips.add("• Create conversation areas with furniture facing each other");
      tips.add("• Use area rugs to define different zones");
    }

    if (floorPlan.windows.length >= 2) {
      tips.add("• With ${floorPlan.windows.length} windows, you have great cross-ventilation — "
          "position seating to enjoy the breeze");
    }

    if (floorPlan.doors.isNotEmpty) {
      tips.add("• The entrance sets the first impression — "
          "add a statement piece near the door");
    }

    tips.add(        "• The $styleName style works best with consistent materials — "
        "limit yourself to 2-3 material types");
    tips.add("• Add life with plants — they improve air quality and mood");

    return tips.join('\n');
  }

  String _getWindowDirection(FloorPlanData floorPlan) {
    if (floorPlan.windows.isEmpty) return 'unknown';
    final w = floorPlan.windows.first;
    if (w.wallIndex < floorPlan.walls.length) {
      final angle = floorPlan.walls[w.wallIndex].angle;
      if (angle.abs() < 0.1) return 'south';
      if ((angle - pi / 2).abs() < 0.1) return 'west';
      if ((angle - pi).abs() < 0.1 || (angle + pi).abs() < 0.1) return 'north';
      if ((angle + pi / 2).abs() < 0.1) return 'east';
    }
    return 'side';
  }

  String _getDoorDirection(FloorPlanData floorPlan) {
    if (floorPlan.doors.isEmpty) return 'unknown';
    final d = floorPlan.doors.first;
    if (d.wallIndex < floorPlan.walls.length) {
      final angle = floorPlan.walls[d.wallIndex].angle;
      if (angle.abs() < 0.1) return 'south';
      if ((angle - pi / 2).abs() < 0.1) return 'west';
      if ((angle - pi).abs() < 0.1 || (angle + pi).abs() < 0.1) return 'north';
      if ((angle + pi / 2).abs() < 0.1) return 'east';
    }
    return 'side';
  }

  String _getOutletDirection(FloorPlanData floorPlan) {
    if (floorPlan.outlets.isEmpty) return 'unknown';
    final o = floorPlan.outlets.first;
    if (o.wallIndex < floorPlan.walls.length) {
      final angle = floorPlan.walls[o.wallIndex].angle;
      if (angle.abs() < 0.1) return 'south';
      if ((angle - pi / 2).abs() < 0.1) return 'west';
      if ((angle - pi).abs() < 0.1 || (angle + pi).abs() < 0.1) return 'north';
      if ((angle + pi / 2).abs() < 0.1) return 'east';
    }
    return 'side';
  }

  String _getMajorFurniture(String roomType) {
    switch (roomType) {
      case 'Bedroom':
        return 'the bed';
      case 'Living Room':
        return 'the sofa';
      case 'Kitchen':
        return 'the refrigerator';
      case 'Home Office':
        return 'the desk';
      case 'Dining Room':
        return 'the dining table';
      default:
        return 'the largest furniture piece';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(isChatLoadingProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme, theme),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return _buildTypingIndicator(colorScheme);
                  }
                  return _buildMessage(messages[index], colorScheme, theme);
                },
              ),
            ),
            _buildInputBar(colorScheme, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Interior Designer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Based on your floor plan',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg, ColorScheme colorScheme, ThemeData theme) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: widget.onComplete,
              icon: const Icon(Icons.auto_awesome_rounded, size: 20),
              label: const Text(
                'Generate My Design',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask about your design...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
