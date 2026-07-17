import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Sur navigateur large, contraint le contenu dans une colonne largeur
/// mobile centrée avec bordure/ombre (façon "carte téléphone"), au lieu de
/// laisser l'app s'étirer sur toute la largeur de l'écran. Sans effet sur
/// mobile natif (déjà plus étroit que la largeur max).
class WebPhoneShell extends StatelessWidget {
  final Widget child;

  const WebPhoneShell({super.key, required this.child});

  static const double _maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return ColoredBox(
      color: AppColors.brown,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
