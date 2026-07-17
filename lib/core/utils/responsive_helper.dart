import 'package:flutter/widgets.dart';

/// Pas de navigateur à supporter (app native) : la contrainte de
/// "compatibilité" est traduite ici en support responsive multi-tailles
/// d'écran mobile (petit téléphone -> grand téléphone/tablette).
class ResponsiveHelper {
  ResponsiveHelper._();

  static const double compactMaxWidth = 380;
  static const double expandedMinWidth = 600;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= compactMaxWidth;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedMinWidth;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expandedMinWidth) return 32;
    if (width <= compactMaxWidth) return 16;
    return 20;
  }

  static double scaledFont(BuildContext context, double base) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= compactMaxWidth) return base - 1;
    if (width >= expandedMinWidth) return base + 1;
    return base;
  }
}
