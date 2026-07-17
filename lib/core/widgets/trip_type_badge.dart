import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../theme/app_colors.dart';

class TripTypeBadge extends StatelessWidget {
  final TripMode mode;

  const TripTypeBadge({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (mode) {
      TripMode.ponctuelle => (Icons.today_outlined, AppColors.primary),
      TripMode.mensuelle => (Icons.event_repeat_outlined, AppColors.brown),
      TripMode.interregions => (Icons.alt_route_outlined, AppColors.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            mode.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
