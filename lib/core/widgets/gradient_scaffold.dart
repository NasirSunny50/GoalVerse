import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Scaffold with an ambient, animated gradient backdrop and soft color blobs
/// that give every screen the premium "sports product" feel.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: extendBody,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.transparent,
                            AppColors.darkBg.withValues(alpha: 0.4),
                          ]
                        : [
                            Colors.transparent,
                            AppColors.lightBg.withValues(alpha: 0.2),
                          ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(bottom: false, child: body),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
      ),
      child: Stack(
        children: [
          _blob(const Alignment(-1.1, -1.0), AppColors.secondary,
              isDark ? 0.34 : 0.18, 320),
          _blob(const Alignment(1.2, -0.7), AppColors.primary,
              isDark ? 0.28 : 0.16, 300),
          _blob(const Alignment(0.9, 0.9), AppColors.tertiary,
              isDark ? 0.20 : 0.12, 340),
        ],
      ),
    );
  }

  Widget _blob(Alignment a, Color c, double opacity, double size) {
    return Align(
      alignment: a,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c.withValues(alpha: opacity), c.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
