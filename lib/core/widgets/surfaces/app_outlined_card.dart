import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

class AppOutlinedCard extends StatelessWidget {
  const AppOutlinedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = AppRadius.lg,
    this.borderWidth = AppSizes.borderWidth,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;
  final double borderWidth;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.025)
                : Colors.white.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? (isDark ? AppColors.darkBorder : Colors.white),
          width: borderWidth,
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}
