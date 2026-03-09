import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AnimatedSweetspotLogo extends StatefulWidget {
  const AnimatedSweetspotLogo(
      {super.key, this.size = 140, this.fadeProgress = 0.0});

  final double size;
  final double fadeProgress; // 0.0 = no fade, 1.0 = fully faded

  @override
  State<AnimatedSweetspotLogo> createState() => _AnimatedSweetspotLogoState();
}

class _AnimatedSweetspotLogoState extends State<AnimatedSweetspotLogo>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _AnimatedSweetspotLogoPainter(
                _controller.value, widget.fadeProgress),
          );
        },
      ),
    );
  }
}

class _AnimatedSweetspotLogoPainter extends CustomPainter {
  final double progress;
  final double fadeProgress;

  _AnimatedSweetspotLogoPainter(this.progress, this.fadeProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.42;

    // Waveform circle animation
    _drawWaveform(canvas, center, baseRadius * 0.85, progress);

    // Outer ring animation
    _drawOuterRing(canvas, center, baseRadius, progress);

    // Speakers pop after 50% of progress
    if (progress > 0.5) {
      final speakerProgress = (progress - 0.5) * 2;
      _drawSpeaker(canvas, center, baseRadius, speakerProgress);
    }

    // Sweet spot pulse after 60%
    if (progress > 0.6) {
      final pulseProgress = (progress - 0.6) / 0.4;
      _drawSweetSpot(canvas, center, pulseProgress.clamp(0.0, 1.0));
    }
  }

  void _drawWaveform(
      Canvas canvas, Offset center, double radius, double progress) {
    final path = Path();
    const segments = 120;
    const waveAmplitude = 6.0;
    const waveFrequency = 8;

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final wave = math.sin(angle * waveFrequency) * waveAmplitude;
      final r = radius + wave;

      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final metric = path.computeMetrics().first;

    // Draw in, then self-fade during the tail of the logo animation.
    final normalizedProgress = progress.clamp(0.0, 1.0);
    final selfFade = normalizedProgress <= 0.8
        ? (normalizedProgress / 0.8)
        : ((1.0 - normalizedProgress) / 0.2);
    final effectiveProgress =
        (selfFade.clamp(0.0, 1.0) * (1.0 - fadeProgress)).clamp(0.0, 1.0);
    if (effectiveProgress <= 0.001) {
      return;
    }

    final drawPath = metric.extractPath(0, metric.length * effectiveProgress);

    final paint = Paint()
      ..color = AppTheme.accent.withAlpha((255 * effectiveProgress).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(drawPath, paint);
  }

  void _drawOuterRing(
      Canvas canvas, Offset center, double radius, double progress) {
    final ringProgress = progress.clamp(0.2, 1.0);
    final fadeFactor = 1.0 - fadeProgress;
    final alpha =
        (((ringProgress - 0.2) / 0.8 * 180) * fadeFactor).toInt().clamp(0, 180);

    // Outer subtle glow
    final glowPaint = Paint()
      ..color = AppTheme.accent.withAlpha((20 * fadeFactor).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius, glowPaint);

    // Main ring
    final ringPaint = Paint()
      ..color = AppTheme.accent.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, ringPaint);

    // Inner accent ring
    final innerPaint = Paint()
      ..color = AppTheme.accent.withAlpha((alpha * 0.33).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 8, innerPaint);
  }

  void _drawSpeaker(
      Canvas canvas, Offset center, double radius, double progress) {
    final speakerProgress = progress.clamp(0.0, 1.0);

    // Left speaker
    const leftAngle = math.pi * 0.75;
    final leftPos = Offset(
      center.dx + (radius + 18) * math.cos(leftAngle),
      center.dy + (radius + 18) * math.sin(leftAngle),
    );
    _drawSingleSpeaker(
      canvas,
      leftPos,
      'L',
      AppTheme.leftSpeaker,
      speakerProgress,
    );

    // Right speaker
    const rightAngle = math.pi * 0.25;
    final rightPos = Offset(
      center.dx + (radius + 18) * math.cos(rightAngle),
      center.dy + (radius + 18) * math.sin(rightAngle),
    );
    _drawSingleSpeaker(
      canvas,
      rightPos,
      'R',
      AppTheme.rightSpeaker,
      speakerProgress,
    );
  }

  void _drawSingleSpeaker(
      Canvas canvas, Offset pos, String label, Color color, double progress) {
    final fadeFactor = 1.0 - fadeProgress;
    final combinedProgress = (progress * fadeFactor).clamp(0.0, 1.0);
    final animatedAlpha = (30 + 190 * combinedProgress).toInt().clamp(0, 255);
    const radius = 11.0;

    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha((30 * combinedProgress).toInt())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(pos, 16 * combinedProgress, glowPaint);

    // Speaker circle
    final speakerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withAlpha((255 * fadeFactor).toInt()),
          color.withAlpha((220 * combinedProgress).toInt()),
        ],
        stops: const [0.4, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: radius));
    canvas.drawCircle(pos, radius * combinedProgress, speakerPaint);

    // Border
    final borderPaint = Paint()
      ..color = color.withAlpha(animatedAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, radius * combinedProgress, borderPaint);

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withAlpha((255 * combinedProgress).toInt()),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1.0,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );
  }

  void _drawSweetSpot(Canvas canvas, Offset center, double progress) {
    final fadeFactor = 1.0 - fadeProgress;
    final combinedProgress = (progress * fadeFactor).clamp(0.0, 1.0);
    final pulse = 1 + math.sin(progress * math.pi * 4) * 0.05;

    // Outer glow
    final glowPaint = Paint()
      ..color = AppTheme.listeningPos.withAlpha((40 * combinedProgress).toInt())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, 20 * combinedProgress, glowPaint);

    // Main center circle
    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.listeningPos.withAlpha((255 * fadeFactor).toInt()),
          AppTheme.listeningPos.withAlpha((200 * combinedProgress).toInt()),
        ],
        stops: const [0.5, 1.0],
      ).createShader(
          Rect.fromCircle(center: center, radius: 12 * combinedProgress));
    canvas.drawCircle(center, 12 * pulse * combinedProgress, centerPaint);

    // Border
    final borderPaint = Paint()
      ..color =
          AppTheme.listeningPos.withAlpha((255 * combinedProgress).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 12 * pulse * combinedProgress, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedSweetspotLogoPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.fadeProgress != fadeProgress;
}

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _logoAnimationDuration = Duration(milliseconds: 2400);
  static const _holdDuration = Duration(milliseconds: 800);

  late AnimationController _fadeController;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInCubic),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    // Wait for logo animation to complete.
    await Future.delayed(_logoAnimationDuration);
    if (!mounted) return;

    // Hold for a moment.
    await Future.delayed(_holdDuration);
    if (!mounted) return;

    // Fade out.
    await _fadeController.forward();
    if (!mounted) return;

    widget.onComplete();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeOut.value,
          child: Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSweetspotLogo(
                    size: 140,
                    fadeProgress: 1.0 - _fadeOut.value,
                  ),
                  const SizedBox(height: 48),
                  Column(
                    children: [
                      const Text(
                        'Sweetspot',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Audio Room Optimizer',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withAlpha(200),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
