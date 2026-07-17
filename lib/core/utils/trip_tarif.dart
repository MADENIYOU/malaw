import '../../data/models/enums.dart';

/// Tarif mocké par place occupée, selon le mode de trajet (pas de vrai
/// système de paiement dans ce prototype). Le gain n'est jamais compté sur
/// les places vides, cohérent avec la règle du seuil de 4 non bloquant.
class TripTarif {
  TripTarif._();

  static const Map<TripMode, int> parPlace = {
    TripMode.ponctuelle: 1500,
    TripMode.mensuelle: 1200,
    TripMode.interregions: 5000,
  };

  static int gain(TripMode mode, int placesRemplies) =>
      (parPlace[mode] ?? 0) * placesRemplies;
}
