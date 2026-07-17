import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../theme/app_colors.dart';

/// Stepper horizontal Confirmé / En route / Arrivé / Terminé, repris de la
/// planche de design pour le suivi de trajet.
class TripProgressStepper extends StatelessWidget {
  final TripStatus statut;

  const TripProgressStepper({super.key, required this.statut});

  int get _stepIndex => switch (statut) {
    TripStatus.enAttente => 0,
    TripStatus.confirme => 0,
    TripStatus.enRoute => 1,
    TripStatus.termine => 3,
  };

  static const _labels = ['Confirmé', 'En route', 'Arrivé', 'Terminé'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final done = i <= _stepIndex;
        final isLast = i == _labels.length - 1;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i == 0
                          ? Colors.transparent
                          : (i <= _stepIndex ? AppColors.primary : AppColors.divider),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < _stepIndex ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 11,
                  color: done ? AppColors.brown : AppColors.textSecondary,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
