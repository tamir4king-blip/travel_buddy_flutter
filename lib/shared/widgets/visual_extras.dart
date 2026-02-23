import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';

// ── GradientOrb ─────────────────────────────────────────────────────────────
/// A floating decorative orb with radial gradient, used for background depth.
class GradientOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  const GradientOrb({
    super.key,
    required this.color,
    this.size = 200,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: 12, duration: 3500.ms, curve: Curves.easeInOut),
      ),
    );
  }
}

// ── AnimatedBackground ──────────────────────────────────────────────────────
/// A stack with 2-3 floating gradient orbs. Wrap screen content with this.
class AnimatedBackground extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GradientOrb(
          color: accentColor,
          size: 260,
          top: -80,
          right: -60,
        ),
        GradientOrb(
          color: accentColor.withValues(alpha: 0.7),
          size: 180,
          bottom: 120,
          left: -50,
        ),
        GradientOrb(
          color: AppColors.purple,
          size: 140,
          top: 300,
          right: -30,
        ),
        child,
      ],
    );
  }
}

// ── ShimmerOverlay ──────────────────────────────────────────────────────────
/// Wraps any widget with a subtle shimmer sweep effect.
class ShimmerOverlay extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerOverlay({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.white.withValues(alpha: 0.05),
      highlightColor: highlightColor ?? Colors.white.withValues(alpha: 0.15),
      period: const Duration(milliseconds: 2000),
      child: child,
    );
  }
}

// ── GlowContainer ───────────────────────────────────────────────────────────
/// Container with a colored glow shadow that pulses.
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool pulse;

  const GlowContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.borderRadius = 16,
    this.padding,
    this.pulse = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: child,
    );

    if (pulse) {
      container = container
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .custom(
            duration: 2000.ms,
            builder: (context, value, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.15 + (value * 0.2)),
                      blurRadius: 16 + (value * 8),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: child,
              );
            },
          );
    }

    return container;
  }
}

// ── ScaleTap ────────────────────────────────────────────────────────────────
/// Wraps a widget with scale-down on press feedback.
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ── AnimatedCounter ─────────────────────────────────────────────────────────
/// Counts up from 0 (or a start value) to a target integer.
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text(
          '$prefix${val.round()}$suffix',
          style: style,
        );
      },
    );
  }
}

// ── GradientText ────────────────────────────────────────────────────────────
/// Renders text with a gradient fill via ShaderMask.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText({
    super.key,
    required this.text,
    this.style,
    this.gradient = AppGradients.gradientWarm,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}
