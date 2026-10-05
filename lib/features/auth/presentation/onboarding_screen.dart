import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Scan Your Space',
      description: 'Use your camera to capture your room. Our AI analyzes dimensions, lighting, and layout automatically.',
      imageUrl: 'https://picsum.photos/seed/scan/400/300',
      color: Color(0xFF8B6B5A),
      useLocalAsset: true,
    ),
    OnboardingPage(
      title: 'Pick Your Style',
      description: 'Choose from 8+ designer styles - Modern, Scandinavian, Industrial, Mid-Century, Bohemian, Coastal, Japandi, Classic.',
      imageUrl: 'https://picsum.photos/seed/style/400/300',
      color: Color(0xFF6B8E8E),
    ),
    OnboardingPage(
      title: 'AI Generates Designs',
      description: 'Watch as AI creates photorealistic redesigns matching your style. Get multiple variations in seconds.',
      imageUrl: 'https://picsum.photos/seed/ai/400/300',
      color: Color(0xFFD4A574),
    ),
    OnboardingPage(
      title: 'Save & Share',
      description: 'Save your favorite designs, share with friends or contractors, and bring your vision to life.',
      imageUrl: 'https://picsum.photos/seed/share/400/300',
      color: Color(0xFF4A7C8A),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/auth'),
                child: Text('Skip', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
              ).animate().fadeIn(delay: 200.ms),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPageContent(page: page, index: index);
                },
              ),
            ),
            _buildBottomSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    child: const Text('Back'),
                  ),
                )
              else
                const SizedBox(width: 80),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                      );
                    } else {
                      context.go('/auth');
                    }
                  },
                  child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageContent extends StatelessWidget {
  final OnboardingPage page;
  final int index;

  const _OnboardingPageContent({required this.page, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: page.color.withOpacity(0.1),
              ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: page.useLocalAsset
                  ? Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_rounded, size: 80, color: page.color),
                    )
                  : Image.network(
                      page.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(child: CircularProgressIndicator(color: page.color));
                      },
                      errorBuilder: (_, __, ___) => Icon(Icons.image_rounded, size: 80, color: page.color),
                    ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(delay: 200.ms),
          const SizedBox(height: 24),
          Text(
            page.title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imageUrl;
  final Color color;
  final bool useLocalAsset;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.color,
    this.useLocalAsset = false,
  });
}