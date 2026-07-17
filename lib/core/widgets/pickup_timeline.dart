import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PickupStop {
  final String label;
  final String heure;
  final bool recupere;
  final bool isCurrentUser;

  const PickupStop({
    required this.label,
    required this.heure,
    this.recupere = false,
    this.isCurrentUser = false,
  });
}

/// Timeline de ramassage ordonnée — utilisée côté suivi passager (lecture
/// seule) ET côté "trajet en cours" chauffeur (avec action de validation).
class PickupTimelineWidget extends StatelessWidget {
  final List<PickupStop> stops;
  final void Function(int index)? onMarkPickedUp;

  const PickupTimelineWidget({
    super.key,
    required this.stops,
    this.onMarkPickedUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stops.length, (i) {
        final stop = stops[i];
        final isLast = i == stops.length - 1;
        final dotColor = stop.recupere ? AppColors.success : AppColors.primary;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stop.recupere ? dotColor : Colors.white,
                      border: Border.all(color: dotColor, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: AppColors.divider)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.label,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: stop.isCurrentUser
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                            ),
                            Text(
                              stop.heure,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (onMarkPickedUp != null && !stop.recupere)
                        TextButton(
                          onPressed: () => onMarkPickedUp!(i),
                          child: const Text('Marquer récupéré'),
                        )
                      else if (stop.recupere)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
