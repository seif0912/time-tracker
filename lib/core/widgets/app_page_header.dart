import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    required this.onSettingsTap,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.isPro = false,
    this.onPlanTap,
  });

  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool isPro;
  final VoidCallback onSettingsTap;
  final VoidCallback? onPlanTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style:
                      titleStyle ??
                      theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        subtitleStyle ??
                        theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: subtitleColor,
                        ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Free / Pro badge
          InkWell(
            onTap: onPlanTap,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF29231D)
                    : const Color(0xFFF8E9DC),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF55483B)
                      : const Color(0xFFFFFFFF),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 17,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isPro ? 'Pro' : 'Free',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Settings button
          SizedBox(
            width: 42,
            height: 42,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSettingsTap,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isDark ? const Color(0xFF555555) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.tune_rounded, size: 22, color: titleColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
