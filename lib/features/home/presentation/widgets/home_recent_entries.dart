import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/surfaces/app_glass_surface.dart';

class RecentTimeEntryItem {
  const RecentTimeEntryItem({
    required this.taskId,
    required this.taskName,
    required this.categoryName,
    required this.icon,
    required this.totalDuration,
    this.onResume,
  });

  final int taskId;
  final String taskName;
  final String categoryName;
  final IconData icon;
  final String totalDuration;
  final VoidCallback? onResume;
}

class HomeRecentEntries extends StatelessWidget {
  const HomeRecentEntries({
    super.key,
    required this.entries,
    required this.onViewAll,
  });

  final List<RecentTimeEntryItem> entries;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor = isDark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;
    final mutedColor = isDark
        ? AppColors.darkMutedText
        : AppColors.lightMutedText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AppGlassSurface(
      variant: AppSurfaceVariant.standard,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header.
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recently Tracked Tasks',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: secondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No time entries yet',
                  style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                ),
              ),
            )
          else
            ...entries
                .take(3)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _RecentEntryRow(
                      entry: entry,
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      mutedColor: mutedColor,
                      borderColor: borderColor,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _RecentEntryRow extends StatelessWidget {
  const _RecentEntryRow({
    required this.entry,
    required this.textColor,
    required this.secondaryColor,
    required this.mutedColor,
    required this.borderColor,
  });

  final RecentTimeEntryItem entry;
  final Color textColor;
  final Color secondaryColor;
  final Color mutedColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Category icon.
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Icon(entry.icon, size: 17, color: textColor),
        ),

        const SizedBox(width: 8),

        // Task and category.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.taskName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                entry.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Duration and time range.
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.totalDuration,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Total tracked',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: mutedColor,
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),

        // Resume action.
        SizedBox(
          width: 25,
          height: 25,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: entry.onResume,
              child: Icon(
                Icons.play_circle_outline_rounded,
                size: 24,
                color: entry.onResume == null
                    ? mutedColor.withValues(alpha: 0.45)
                    : secondaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
