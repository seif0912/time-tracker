import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LightBackgroundVariant { light, lightWhite }

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.readabilityOverlay = false,
    this.lightVariant = LightBackgroundVariant.light,
    this.backgroundScale = 1.8,
  });

  final Widget child;
  final bool readabilityOverlay;
  final LightBackgroundVariant lightVariant;
  final double backgroundScale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundAsset = isDark
        ? 'assets/backgrounds/background_dark.svg'
        : switch (lightVariant) {
            LightBackgroundVariant.light =>
              'assets/backgrounds/background_light.svg',
            LightBackgroundVariant.lightWhite =>
              'assets/backgrounds/background_light_white.svg',
          };

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),

        Transform.scale(
          scale: backgroundScale,
          child: SvgPicture.asset(backgroundAsset, fit: BoxFit.cover),
        ),

        if (readabilityOverlay)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.45),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.55),
                      ],
              ),
            ),
          ),

        child,
      ],
    );
  }
}
