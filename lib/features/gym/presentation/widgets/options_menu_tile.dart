import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One row of an exercise options bottom sheet: icon badge, title, subtitle
/// and a chevron. Shared by the exercise list and the day detail screen.
class OptionsMenuTile extends StatelessWidget {
  const OptionsMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.borderRadius,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.chip(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.inkSoft(context), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.border(context)),
            ],
          ),
        ),
      ),
    );
  }
}
