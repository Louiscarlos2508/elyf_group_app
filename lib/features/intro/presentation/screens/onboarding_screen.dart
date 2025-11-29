import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    OnboardingSlideData(
      title: 'Entreprises connectées',
      description:
          'Gérez chaque entité Elyf depuis une seule application, avec un '
          'design cohérent et premium.',
      animationType: OnboardingAnimationType.connected,
    ),
    OnboardingSlideData(
      title: 'Offline-first',
      description:
          'Isar garde vos données critiques disponibles et se synchronise '
          'automatiquement avec Firestore.',
      animationType: OnboardingAnimationType.sync,
    ),
    OnboardingSlideData(
      title: 'Impression Sunmi V3',
      description:
          'Imprimez vos tickets et reçus thermiques directement depuis les '
          'modules métiers.',
      animationType: OnboardingAnimationType.print,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _page = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return OnboardingSlide(
                    slide: slide,
                    isActive: index == _page,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _DotsIndicator(total: _slides.length, index: _page),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (_page < _slides.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Text(
                      _page < _slides.length - 1 ? 'Continuer' : 'Commencer',
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide extends StatefulWidget {
  const OnboardingSlide({
    super.key,
    required this.slide,
    required this.isActive,
  });

  final OnboardingSlideData slide;
  final bool isActive;

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(OnboardingSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: _buildAnimation(colors),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            widget.slide.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.slide.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimation(ColorScheme colors) {
    switch (widget.slide.animationType) {
      case OnboardingAnimationType.connected:
        return _ConnectedAnimation(
          animation: _animation,
          colors: colors,
        );
      case OnboardingAnimationType.sync:
        return _SyncAnimation(
          animation: _animation,
          colors: colors,
        );
      case OnboardingAnimationType.print:
        return _PrintAnimation(
          animation: _animation,
          colors: colors,
        );
    }
  }
}

class _ConnectedAnimation extends StatelessWidget {
  const _ConnectedAnimation({
    required this.animation,
    required this.colors,
  });

  final Animation<double> animation;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Central hub
              Transform.scale(
                scale: 0.8 + (animation.value * 0.2),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.layers,
                    size: 50,
                    color: colors.onPrimary,
                  ),
                ),
              ),
              // Rotating connected nodes
              ...List.generate(4, (index) {
                final angle = (index * 90 + animation.value * 360) * math.pi / 180;
                final radius = 100.0;
                final progress = animation.value * 0.5 + 0.5;
                final x = radius * progress * math.cos(angle);
                final y = radius * progress * math.sin(angle);

                return Positioned(
                  left: 140 + x,
                  top: 140 + y,
                  child: Transform.scale(
                    scale: 0.6 + (animation.value * 0.4),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.secondary.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getNodeIcon(index),
                        size: 30,
                        color: colors.onSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  IconData _getNodeIcon(int index) {
    switch (index) {
      case 0:
        return Icons.water_drop;
      case 1:
        return Icons.local_fire_department;
      case 2:
        return Icons.home;
      case 3:
        return Icons.store;
      default:
        return Icons.circle;
    }
  }
}

class _SyncAnimation extends StatelessWidget {
  const _SyncAnimation({
    required this.animation,
    required this.colors,
  });

  final Animation<double> animation;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cloud icon (Firestore)
              Positioned(
                top: 40,
                child: Transform.scale(
                  scale: 0.8 + (animation.value * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud,
                      size: 60,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              // Device icon (Isar/Offline)
              Positioned(
                bottom: 40,
                child: Transform.scale(
                  scale: 0.8 + ((1 - animation.value) * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: 60,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
              // Sync arrows
              ...List.generate(3, (index) {
                final progress = (animation.value + index * 0.33) % 1.0;
                final y = 140 - (progress * 100);
                final opacity = progress < 0.5 ? progress * 2 : (1 - progress) * 2;

                return Positioned(
                  left: 120,
                  top: y,
                  child: Opacity(
                    opacity: opacity,
                    child: Icon(
                      Icons.sync,
                      size: 30,
                      color: colors.primary,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _PrintAnimation extends StatelessWidget {
  const _PrintAnimation({
    required this.animation,
    required this.colors,
  });

  final Animation<double> animation;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Printer base
              Container(
                width: 200,
                height: 120,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.print,
                  size: 60,
                  color: colors.primary,
                ),
              ),
              // Paper coming out
              Positioned(
                top: 20 - (animation.value * 80),
                child: Transform.rotate(
                  angle: animation.value * 0.1,
                  child: Container(
                    width: 180,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.receipt,
                        size: 40,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              // Print waves
              ...List.generate(3, (index) {
                final delay = index * 0.2;
                final waveProgress = ((animation.value + delay) % 1.0);
                final scale = 0.5 + (waveProgress * 0.5);
                final opacity = 1.0 - waveProgress;

                return Positioned(
                  top: 100,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary.withValues(alpha: 0),
                              colors.primary.withValues(alpha: opacity),
                              colors.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.total, required this.index});

  final int total;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (dotIndex) {
        final selected = dotIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: selected ? 32 : 8,
          decoration: BoxDecoration(
            color: selected
                ? colors.primary
                : colors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.title,
    required this.description,
    required this.animationType,
  });

  final String title;
  final String description;
  final OnboardingAnimationType animationType;
}

enum OnboardingAnimationType {
  connected,
  sync,
  print,
}
