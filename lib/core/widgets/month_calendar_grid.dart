import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/date_fr.dart';

/// Vraie grille de mois façon calendrier. Chaque case (date précise) est
/// indépendante — un tap ouvre/ferme sa propre entrée ; la répétition
/// éventuelle se règle ensuite dans le formulaire de cette entrée, pas ici.
/// Les dates passées sont grisées et non sélectionnables.
class MonthCalendarGrid extends StatelessWidget {
  final DateTime month;
  final bool Function(DateTime date) isActive;
  final void Function(DateTime date) onDayTap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthCalendarGrid({
    super.key,
    required this.month,
    required this.isActive,
    required this.onDayTap,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstOfMonth.weekday - 1;

    final cells = <Widget>[
      for (var i = 0; i < leadingEmpty; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        Builder(
          builder: (context) {
            final date = DateTime(month.year, month.month, day);
            final past = date.isBefore(todayNormalized);
            return _DayCell(
              day: day,
              active: !past && isActive(date),
              disabled: past,
              onTap: past ? null : () => onDayTap(date),
            );
          },
        ),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPreviousMonth,
              color: AppColors.brown,
            ),
            Text(
              DateFr.monthYear(month),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextMonth,
              color: AppColors.brown,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: DateFr.joursCourtsHeader
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
          children: cells,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool active;
  final bool disabled;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.active,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : active
        ? Colors.white
        : AppColors.brown;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            color: textColor,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
