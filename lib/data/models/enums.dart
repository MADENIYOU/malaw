enum UserRole { passager, chauffeur }

enum TripMode { ponctuelle, mensuelle, interregions }

extension TripModeLabel on TripMode {
  String get label => switch (this) {
    TripMode.ponctuelle => 'Ponctuelle',
    TripMode.mensuelle => 'Mensuelle',
    TripMode.interregions => 'Inter-régions',
  };
}

/// Le seuil de 4 passagers n'est pas bloquant : "confirme" survient à
/// l'approche de l'heure de passage quel que soit le remplissage. Il n'y a
/// volontairement aucun statut "annulé faute de passagers".
enum TripStatus { enAttente, confirme, enRoute, termine }

extension TripStatusLabel on TripStatus {
  String get label => switch (this) {
    TripStatus.enAttente => 'En attente de remplissage',
    TripStatus.confirme => 'Confirmé',
    TripStatus.enRoute => 'En route',
    TripStatus.termine => 'Terminé',
  };
}

enum PlanningStatut { actif, pause }

enum Weekday { lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche }

extension WeekdayLabel on Weekday {
  String get shortLabel => switch (this) {
    Weekday.lundi => 'Lun',
    Weekday.mardi => 'Mar',
    Weekday.mercredi => 'Mer',
    Weekday.jeudi => 'Jeu',
    Weekday.vendredi => 'Ven',
    Weekday.samedi => 'Sam',
    Weekday.dimanche => 'Dim',
  };

  String get fullLabel => switch (this) {
    Weekday.lundi => 'Lundi',
    Weekday.mardi => 'Mardi',
    Weekday.mercredi => 'Mercredi',
    Weekday.jeudi => 'Jeudi',
    Weekday.vendredi => 'Vendredi',
    Weekday.samedi => 'Samedi',
    Weekday.dimanche => 'Dimanche',
  };
}
