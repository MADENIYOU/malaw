import '../../data/models/enums.dart';

/// Brouillon en mémoire d'une entrée de planning (une case du calendrier),
/// avant persistance SQLite — vit le temps du flow créateur -> récap.
class MensuelleDraftEntry {
  final DateTime date;
  final String? adresseDepart;
  final String? heureArrivee;
  final String? destination;
  final Set<Weekday> repeatWeekdays;

  const MensuelleDraftEntry({
    required this.date,
    this.adresseDepart,
    this.heureArrivee,
    this.destination,
    this.repeatWeekdays = const {},
  });

  Weekday get jourAncre => Weekday.values[date.weekday - 1];

  bool get seRepete => repeatWeekdays.isNotEmpty;

  MensuelleDraftEntry copyWith({
    String? adresseDepart,
    String? heureArrivee,
    String? destination,
    Set<Weekday>? repeatWeekdays,
  }) => MensuelleDraftEntry(
    date: date,
    adresseDepart: adresseDepart ?? this.adresseDepart,
    heureArrivee: heureArrivee ?? this.heureArrivee,
    destination: destination ?? this.destination,
    repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
  );

  bool get isComplete =>
      adresseDepart != null && heureArrivee != null && destination != null;
}
