import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itfits/core/services/providers.dart';

final aiMessagesProvider = StateProvider<List<_ChatMessage>>((ref) => []);

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _AiQuestion {
  final String question;
  final String followUp;
  final List<String> options;

  const _AiQuestion({
    required this.question,
    required this.followUp,
    required this.options,
  });
}

class AiConsultScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const AiConsultScreen({super.key, required this.onComplete});

  @override
  ConsumerState<AiConsultScreen> createState() => _AiConsultScreenState();
}

class _AiConsultScreenState extends ConsumerState<AiConsultScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  int _questionsAnswered = 0;
  late final List<_AiQuestion> _questions;

  @override
  void initState() {
    super.initState();
    final styleName = ref.read(selectedStyleNameProvider);
    _questions = [
      _AiQuestion(
        question:
            "I can see you've captured your room! Based on the ${styleName.isNotEmpty ? styleName : 'design'} style you chose, I have a few questions to personalize your design.",
        followUp: "What's the primary purpose of this room?",
        options: ['Relaxation', 'Entertainment', 'Work from home', 'Family gathering'],
      ),
      _AiQuestion(
        question: "Great choice! How much natural light does the room get?",
        followUp: "This helps me decide on color intensity and window treatments.",
        options: ['Lots of sunlight', 'Moderate light', 'Mostly dim', 'Varies by time'],
      ),
      _AiQuestion(
        question: "Any specific colors you want to avoid?",
        followUp: "Some people have strong preferences — I'll respect those.",
        options: ['No bright colors', 'No dark tones', 'No neon/vibrant', "I'm open to anything"],
      ),
      _AiQuestion(
        question: "Last question — what's your budget range for this redesign?",
        followUp: "This affects the materials and furniture I suggest.",
        options: ['Budget-friendly', 'Mid-range', 'No budget limit', 'Surprise me'],
      ),
    ];
    _startConversation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startConversation() async {
    final styleName = ref.read(selectedStyleNameProvider);
    final messages = [
      _ChatMessage(
        text: "Hello! I'm your AI interior design consultant. I'll help refine your ${styleName.isNotEmpty ? styleName : 'design'} vision.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    ref.read(aiMessagesProvider.notifier).state = messages;
    await Future.delayed(const Duration(milliseconds: 800));
    _askNextQuestion();
  }

  void _askNextQuestion() async {
    if (_questionsAnswered >= _questions.length) {
      _finishConsultation();
      return;
    }
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _isTyping = false);

    final question = _questions[_questionsAnswered];
    final messages = [
      ...ref.read(aiMessagesProvider),
      _ChatMessage(text: question.question, isUser: false, timestamp: DateTime.now()),
    ];
    ref.read(aiMessagesProvider.notifier).state = messages;
    _scrollToBottom();
  }

  void _answerQuestion(String answer) async {
    final messages = [
      ...ref.read(aiMessagesProvider),
      _ChatMessage(text: answer, isUser: true, timestamp: DateTime.now()),
    ];
    ref.read(aiMessagesProvider.notifier).state = messages;

    final currentPrefs = List<String>.from(ref.read(aiPreferencesProvider));
    currentPrefs.add(answer);
    ref.read(aiPreferencesProvider.notifier).state = currentPrefs;

    _scrollToBottom();

    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isTyping = false);

    const responses = [
      "Perfect! That tells me a lot about how to arrange the space.",
      "Understood — I'll factor that into the lighting and color choices.",
      "Noted! I'll keep the palette within your comfort zone.",
      "Great, that helps me select appropriate materials and finishes.",
    ];
    final responseIdx = _questionsAnswered.clamp(0, responses.length - 1);

    final updatedMessages = [
      ...ref.read(aiMessagesProvider),
      _ChatMessage(text: responses[responseIdx], isUser: false, timestamp: DateTime.now()),
    ];
    ref.read(aiMessagesProvider.notifier).state = updatedMessages;
    setState(() => _questionsAnswered++);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 600));
    _askNextQuestion();
  }

  void _sendCustomMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _answerQuestion(text);
  }

  void _finishConsultation() async {
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _isTyping = false);

    final styleName = ref.read(selectedStyleNameProvider);
    final updatedMessages = [
      ...ref.read(aiMessagesProvider),
      _ChatMessage(
        text: "I now have everything I need! Based on your ${styleName.isNotEmpty ? styleName : 'design'} preferences and room layout, I'm ready to generate your personalized design. Let's create something beautiful!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    ref.read(aiMessagesProvider.notifier).state = updatedMessages;
    _scrollToBottom();
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messages = ref.watch(aiMessagesProvider);
    final isFinished = _questionsAnswered >= _questions.length &&
        messages.isNotEmpty &&
        !messages.last.isUser;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme, theme),
            Expanded(child: _buildChatArea(messages, colorScheme, theme)),
            if (_isTyping) _buildTypingIndicator(colorScheme),
            if (isFinished)
              _buildGenerateButton(colorScheme, theme)
            else if (!_isTyping && _questionsAnswered < _questions.length)
              _buildOptionsBar(colorScheme, theme),
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
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.tertiary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: colorScheme.onPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Design Consultant', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text('$_questionsAnswered/${_questions.length} questions answered', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _questionsAnswered / _questions.length,
                  strokeWidth: 3,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
                Text('$_questionsAnswered', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(List<_ChatMessage> messages, ColorScheme colorScheme, ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildChatBubble(msg, colorScheme, theme).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildChatBubble(_ChatMessage msg, ColorScheme colorScheme, ThemeData theme) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: msg.isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: msg.isUser ? colorScheme.onPrimary : colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _typingDot(0),
                const SizedBox(width: 4),
                _typingDot(1),
                const SizedBox(width: 4),
                _typingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + index * 200),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.0, 1.0),
          duration: Duration(milliseconds: 400 + index * 200),
        );
  }

  Widget _buildOptionsBar(ColorScheme colorScheme, ThemeData theme) {
    final currentQuestion = _questions[_questionsAnswered];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentQuestion.followUp.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                currentQuestion.followUp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currentQuestion.options.map((option) {
              return ActionChip(
                label: Text(option, style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                onPressed: () => _answerQuestion(option),
                backgroundColor: colorScheme.surface,
                side: BorderSide(color: colorScheme.primary.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Or type your own answer...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendCustomMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendCustomMessage,
                icon: Icon(Icons.send_rounded, color: colorScheme.primary),
                style: IconButton.styleFrom(backgroundColor: colorScheme.primaryContainer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: widget.onComplete,
          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
          label: const Text('Generate My Design', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ),
    );
  }
}
