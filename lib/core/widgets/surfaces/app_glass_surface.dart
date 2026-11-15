import 'dart:ui';

import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import '../../theme/app_dimensions.dart';

enum AppSurfaceVariant { standard, action, inactiveTimer, activeTimer, ai }

class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.variant = AppSurfaceVariant.standard,
    this.padding,
    this.radius = AppRadius.lg,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 350),
    this.blur = 8.3,
  });

  final Widget child;
  final AppSurfaceVariant variant;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _surfaceStyle(isDark);

    final surface = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: style.backgroundColor,
            gradient: style.gradient,
            borderRadius: BorderRadius.circular(radius),
            border: style.borderColor == null
                ? null
                : Border.all(
                    color: style.borderColor!,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
            boxShadow: style.shadows,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: surface,
      ),
    );
  }

  _SurfaceStyle _surfaceStyle(bool isDark) {
    switch (variant) {
      case AppSurfaceVariant.standard:
        return isDark
            ? _SurfaceStyle(
                backgroundColor: Colors.black.withValues(alpha: 0.40),
                borderColor: const Color(0xFF222222),
                shadows: [
                  _innerShadow(
                    color: const Color(0xFF6D6D6D).withValues(alpha: 0.12),
                    blur: 22.3,
                    spread: 10,
                  ),
                ],
              )
            : _SurfaceStyle(
                backgroundColor: Colors.white.withValues(alpha: 0.43),
                borderColor: Colors.white,
                shadows: [
                  _innerShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blur: 22.3,
                    spread: -4,
                  ),
                ],
              );

      case AppSurfaceVariant.action:
        return isDark
            ? _SurfaceStyle(
                backgroundColor: Colors.black.withValues(alpha: 0.20),
                borderColor: const Color(0xFF222222),
                shadows: [
                  _innerShadow(
                    color: const Color(0xFF6D6D6D).withValues(alpha: 0.12),
                    blur: 22.3,
                    spread: 10,
                  ),
                ],
              )
            : _SurfaceStyle(
                backgroundColor: Colors.white.withValues(alpha: 0.13),
                borderColor: Colors.white,
                shadows: [
                  _innerShadow(color: Colors.white, blur: 22.3, spread: -4),
                ],
              );

      case AppSurfaceVariant.inactiveTimer:
        return isDark
            ? _SurfaceStyle(
                backgroundColor: Colors.black.withValues(alpha: 0.20),
                borderColor: const Color(0xFF3A3A3A),
                shadows: [
                  _innerShadow(
                    color: Colors.white.withValues(alpha: 0.12),
                    blur: 22.3,
                    spread: -4,
                  ),
                ],
              )
            : _SurfaceStyle(
                backgroundColor: Colors.white.withValues(alpha: 0.40),
                borderColor: Colors.white,
                shadows: [
                  _innerShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blur: 22.3,
                    spread: -4,
                  ),
                ],
              );

      case AppSurfaceVariant.activeTimer:
        return isDark
            ? _SurfaceStyle(
                backgroundColor: const Color(
                  0xFFDDDDDD,
                ).withValues(alpha: 0.20),
                borderColor: const Color(0xFF878787),
                shadows: [
                  _innerShadow(
                    color: Colors.white.withValues(alpha: 0.12),
                    blur: 30,
                    spread: 9,
                  ),
                ],
              )
            : _SurfaceStyle(
                backgroundColor: const Color(
                  0xFF212124,
                ).withValues(alpha: 0.98),
                borderColor: const Color(0xFF24211D),
                shadows: [
                  _innerShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blur: 22.3,
                    spread: -4,
                  ),
                ],
              );

      case AppSurfaceVariant.ai:
        return _SurfaceStyle(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark
                ? const [Color(0xFF2F2E3B), Color(0xFF161416)]
                : const [Color(0xFFCFCCFF), Color(0xFFFEEFFF)],
            stops: const [0.75, 1.0],
          ),
          shadows: [
            _innerShadow(
              color: (isDark ? const Color(0xFF929292) : Colors.black)
                  .withValues(alpha: 0.12),
              blur: 0,
              spread: 0,
            ),
          ],
        );
    }
  }

  BoxShadow _innerShadow({
    required Color color,
    required double blur,
    double spread = 0,
  }) {
    return BoxShadow(
      color: color,
      offset: Offset.zero,
      blurRadius: blur,
      spreadRadius: spread,
      inset: true,
    );
  }
}

class _SurfaceStyle {
  const _SurfaceStyle({
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.shadows = const [],
  });

  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow> shadows;
}
