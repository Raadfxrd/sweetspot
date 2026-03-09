import 'dart:async';

import 'package:flutter/material.dart';

/// A widget that draws an animated border around its child
/// The border "traces" around the edges with a drawing effect
class AnimatedBorderReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final bool enabled;

  const AnimatedBorderReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderRadius,
    this.enabled = true,
  });

  @override
  State<AnimatedBorderReveal> createState() => _AnimatedBorderRevealState();
}

class _AnimatedBorderRevealState extends State<AnimatedBorderReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scheduleReveal();
  }

  @override
  void didUpdateWidget(covariant AnimatedBorderReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.delay != widget.delay ||
        oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _scheduleReveal();
    }
  }

  void _scheduleReveal() {
    _delayTimer?.cancel();

    if (!widget.enabled) {
      _controller.stop();
      _controller.reset();
      return;
    }

    if (widget.delay == Duration.zero) {
      _startReveal();
      return;
    }

    _delayTimer = Timer(widget.delay, () {
      if (!mounted || !widget.enabled) return;
      _startReveal();
    });
  }

  void _startReveal() {
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _BorderRevealPainter(
            progress: _animation.value,
            color: widget.borderColor ?? Theme.of(context).colorScheme.primary,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _BorderRevealPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderWidth;
  final BorderRadius borderRadius;

  _BorderRevealPainter({
    required this.progress,
    required this.color,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 0.999) return;
    if (borderWidth <= 0 ||
        size.width <= borderWidth ||
        size.height <= borderWidth) {
      return;
    }

    final clampedProgress = progress.clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withAlpha((255 * (1 - clampedProgress * 0.5)).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );

    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    if (metrics.isEmpty) return;

    final pathMetric = metrics.first;
    final extractPath = pathMetric.extractPath(
      0,
      pathMetric.length * clampedProgress,
    );

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(_BorderRevealPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// A widget that fades in with optional border reveal animation
class AnimatedReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final bool slideUp;

  const AnimatedReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.slideUp = false,
  });

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _offset = Tween<Offset>(
      begin: widget.slideUp ? const Offset(0, 0.05) : Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
