import 'package:sqflite/sqflite.dart';

import 'retry_util.dart';

/// Convertit toute exception interne en message lisible pour l'utilisateur.
/// Règle produit : jamais d'erreur brute affichée à l'écran.
String friendlyError(Object error) {
  if (error is NonRetryableException) {
    return error.message;
  }
  if (error is DatabaseException) {
    if (error.isUniqueConstraintError()) {
      return 'Cet élément existe déjà.';
    }
    if (error.isNoSuchTableError() || error.isDatabaseClosedError()) {
      return 'Erreur de données locales. Redémarrez l\'application.';
    }
    return 'Un problème est survenu avec les données locales. Réessayez.';
  }
  if (error is FormatException) {
    return 'Certaines informations saisies sont invalides.';
  }
  return 'Une erreur inattendue est survenue. Réessayez.';
}
