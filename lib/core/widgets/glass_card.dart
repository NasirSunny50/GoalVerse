import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A frosted glassmorphism container used across the app.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.blur = 18,
    this.onTap,
    this.gradient,
    this.border = true,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool border;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = context.semantic.card;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: gradient == null
                      ? base.withValues(alpha: isDark ? 0.72 : 0.92)
                      : null,
                  borderRadius: BorderRadius.circular(radius),
                  border: border
                      ? Border.all(color: context.semantic.border, width: 1)
                      : null,
                ),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
