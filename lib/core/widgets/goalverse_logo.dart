import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The GoalVerse brand mark — the real ball-and-orbital-ring artwork
/// (transparent PNG, works on any background).
class GoalVerseMark extends StatelessWidget {
  const GoalVerseMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/goalverse_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// The full GoalVerse logo lockup (the original artwork: mark + wordmark +
/// tagline). Best on its own line / large sizes. Transparent background.
class GoalVerseFull extends StatelessWidget {
  const GoalVerseFull({super.key, this.width = 220});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/goalverse_full.png',
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Mark + wordmark, used in app bars / headers. The wordmark colour adapts to
/// dark/light so it stays readable (the full-lockup artwork has dark wordmark
/// text, so we render the wordmark ourselves for header use).
class GoalVerseLogo extends StatelessWidget {
  const GoalVerseLogo({
    super.key,
    this.markSize = 40,
    this.fontSize = 24,
    this.onDark = true,
    this.showTagline = false,
  });

  final double markSize;
  final double fontSize;
  final bool onDark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final goalColor = onDark ? Colors.white : const Color(0xFF0E2A4A);
    final wordmark = RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          letterSpacing: -0.5,
          color: goalColor,
        ),
        children: [
          const TextSpan(text: 'Goal'),
          TextSpan(
            text: 'Verse',
            style: TextStyle(
              foreground: Paint()
                ..shader = const LinearGradient(colors: AppColors.brandGradient)
                    .createShader(const Rect.fromLTWH(0, 0, 200, 40)),
            ),
          ),
        ],
      ),
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (markSize > 0) ...[
          GoalVerseMark(size: markSize),
          SizedBox(width: markSize * 0.18),
        ],
        wordmark,
      ],
    );

    if (!showTagline) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        SizedBox(height: fontSize * 0.18),
        Text(
          'PLAY · PREDICT · COMPETE · WIN',
          style: TextStyle(
            fontSize: fontSize * 0.28,
            letterSpacing: fontSize * 0.10,
            fontWeight: FontWeight.w700,
            color: onDark
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFF274B73),
          ),
        ),
      ],
    );
  }
}
