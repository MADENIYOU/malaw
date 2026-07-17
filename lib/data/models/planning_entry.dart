import 'enums.dart';

/// Une case du calendrier = une entrée indépendante ancrée sur une date
/// précise. L'option de répétition (façon Google Agenda) vit dans le
/// formulaire de l'entrée elle-même, pas dans la sélection du calendrier.
class PlanningEntry {
  final String id;
  final String planningId;
  final DateTime date;
  final String adresseDepart;
  final String heureArrivee;
  final String destination;
  final Set<Weekday> repeatWeekdays;
  final bool actif;

  const PlanningEntry({
    required this.id,
    required this.planningId,
    required this.date,
    required this.adresseDepart,
    required this.heureArrivee,
    required this.destination,
    this.repeatWeekdays = const {},
    this.actif = true,
  });

  bool get seRepete => repeatWeekdays.isNotEmpty;

  Weekday get jourAncre => Weekday.values[date.weekday - 1];

  PlanningEntry copyWith({
    String? adresseDepart,
    String? heureArrivee,
    String? destination,
    Set<Weekday>? repeatWeekdays,
    bool? actif,
  }) => PlanningEntry(
    id: id,
    planningId: planningId,
    date: date,
    adresseDepart: adresseDepart ?? this.adresseDepart,
    heureArrivee: heureArrivee ?? this.heureArrivee,
    destination: destination ?? this.destination,
    repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
    actif: actif ?? this.actif,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'planning_id': planningId,
    'date': date.toIso8601String(),
    'adresse_depart': adresseDepart,
    'heure_arrivee': heureArrivee,
    'destination': destination,
    'repeat_weekdays': repeatWeekdays.map((w) => w.name).join(','),
    'actif': actif ? 1 : 0,
  };

  factory PlanningEntry.fromMap(Map<String, Object?> map) => PlanningEntry(
    id: map['id'] as String,
    planningId: map['planning_id'] as String,
    date: DateTime.parse(map['date'] as String),
    adresseDepart: map['adresse_depart'] as String,
    heureArrivee: map['heure_arrivee'] as String,
    destination: map['destination'] as String,
    repeatWeekdays: ((map['repeat_weekdays'] as String?) ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => Weekday.values.byName(s))
        .toSet(),
    actif: (map['actif'] as int) == 1,
  );
}
