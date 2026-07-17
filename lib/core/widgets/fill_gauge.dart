import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Jauge X/4 réutilisée passager + chauffeur. Le seuil de 4 n'est pas un
/// verrou : la jauge est purement informative, la couleur bascule vers le
/// vert olive une fois pleine ou confirmée.
class FillGaugeWidget extends StatelessWidget {
  final int placesRemplies;
  final int placesTotal;
  final bool confirme;

  const FillGaugeWidget({
    super.key,
    required this.placesRemplies,
    required this.placesTotal,
    this.confirme = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = placesTotal == 0
        ? 0.0
        : (placesRemplies / placesTotal).clamp(0.0, 1.0);
    final isFull = placesRemplies >= placesTotal;
    final color = confirme || isFull ? AppColors.success : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              confirme ? 'Confirmé' : 'En attente de remplissage',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
            ),
            Text(
              '$placesRemplies/$placesTotal',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
