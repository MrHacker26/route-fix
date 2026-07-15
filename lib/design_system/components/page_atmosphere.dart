import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Page backdrop with an almost-invisible radial ambience glow.
class PageAtmosphere extends StatelessWidget {
  const PageAtmosphere({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.atmosphere,
                AppColors.background,
                AppColors.background,
              ],
              stops: [0.0, 0.32, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -160,
          left: 0,
          right: 0,
          height: 480,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 0.95,
                  colors: [
                    AppColors.ambience.withValues(alpha: 0.07),
                    AppColors.ambience.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
