import 'enums.dart';

/// Une occurrence de trajet, quel que soit son origine (réservation
/// ponctuelle, un jour d'un planning mensuel, ou inter-régions).
class Trip {
  final String id;
  final String passengerId;
  final TripMode mode;
  final String? adresseDepart;
  final String? destination;
  final String? villeDepart;
  final String? villeArrivee;
  final DateTime date;
  final String heureArriveeSouhaitee;
  final String heureRamassageEstimee;
  final TripStatus statut;
  final int placesRemplies;
  final int placesTotal;
  final String? driverId;
  final String? planningEntryId;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.passengerId,
    required this.mode,
    this.adresseDepart,
    this.destination,
    this.villeDepart,
    this.villeArrivee,
    required this.date,
    required this.heureArriveeSouhaitee,
    required this.heureRamassageEstimee,
    required this.statut,
    required this.placesRemplies,
    this.placesTotal = 4,
    this.driverId,
    this.planningEntryId,
    required this.createdAt,
  });

  bool get estComplet => placesRemplies >= placesTotal;

  Trip copyWith({TripStatus? statut, int? placesRemplies, String? driverId}) =>
      Trip(
        id: id,
        passengerId: passengerId,
        mode: mode,
        adresseDepart: adresseDepart,
        destination: destination,
        villeDepart: villeDepart,
        villeArrivee: villeArrivee,
        date: date,
        heureArriveeSouhaitee: heureArriveeSouhaitee,
        heureRamassageEstimee: heureRamassageEstimee,
        statut: statut ?? this.statut,
        placesRemplies: placesRemplies ?? this.placesRemplies,
        placesTotal: placesTotal,
        driverId: driverId ?? this.driverId,
        planningEntryId: planningEntryId,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
    'id': id,
    'passenger_id': passengerId,
    'mode': mode.name,
    'adresse_depart': adresseDepart,
    'destination': destination,
    'ville_depart': villeDepart,
    'ville_arrivee': villeArrivee,
    'date': date.toIso8601String(),
    'heure_arrivee_souhaitee': heureArriveeSouhaitee,
    'heure_ramassage_estimee': heureRamassageEstimee,
    'statut': statut.name,
    'places_remplies': placesRemplies,
    'places_total': placesTotal,
    'driver_id': driverId,
    'planning_entry_id': planningEntryId,
    'created_at': createdAt.toIso8601String(),
  };

  factory Trip.fromMap(Map<String, Object?> map) => Trip(
    id: map['id'] as String,
    passengerId: map['passenger_id'] as String,
    mode: TripMode.values.byName(map['mode'] as String),
    adresseDepart: map['adresse_depart'] as String?,
    destination: map['destination'] as String?,
    villeDepart: map['ville_depart'] as String?,
    villeArrivee: map['ville_arrivee'] as String?,
    date: DateTime.parse(map['date'] as String),
    heureArriveeSouhaitee: map['heure_arrivee_souhaitee'] as String,
    heureRamassageEstimee: map['heure_ramassage_estimee'] as String,
    statut: TripStatus.values.byName(map['statut'] as String),
    placesRemplies: map['places_remplies'] as int,
    placesTotal: map['places_total'] as int,
    driverId: map['driver_id'] as String?,
    planningEntryId: map['planning_entry_id'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
