import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/surfaces/app_glass_surface.dart';

class HomeAiInsights extends StatelessWidget {
  const HomeAiInsights({
    super.key,
    required this.onTap,
    this.title = 'Upgrade To Pro',
    this.description =
        'Unlock Projects, Detailed Reports, AI Insights And Much More.',
    this.buttonLabel = 'Upgrade',
  });

  final VoidCallback onTap;
  final String title;
  final String description;
  final String buttonLabel;

  static const _purpleGradient = LinearGradient(
    colors: [Color(0xFF4742C9), Color(0xFF7636E4)],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? AppColors.darkText : AppColors.lightText;
    final descriptionColor = isDark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AppGlassSurface(
          variant: AppSurfaceVariant.ai,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // AI icon
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: _purpleGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 19,
                  color: Color(0xFFF5F1E8),
                ),
              ),
              const SizedBox(width: 12),

              // Title and description
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.3,
                        color: descriptionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Gradient action button
              Container(
                height: 34,
                decoration: BoxDecoration(
                  gradient: _purpleGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
