import 'package:sqflite/sqflite.dart';

import '../../core/utils/pickup_time_calculator.dart';
import '../../core/utils/retry_util.dart';
import '../local/db_helper.dart';
import '../models/enums.dart';
import '../models/trip.dart';

/// Chaque requête est scopée par passenger_id/driver_id (isolation) — un
/// passager ne voit jamais les trajets d'un autre, un chauffeur ne voit que
/// les siens. Important aussi pour que le switch de rôle démo reste cohérent.
class TripRepository {
  TripRepository({DbHelper? dbHelper}) : _dbHelper = dbHelper ?? DbHelper.instance;

  final DbHelper _dbHelper;

  Future<List<Trip>> getTripsForPassenger(String passengerId, {int limit = 50}) async {
    final db = await _dbHelper.database;
    return withRetry(() async {
      final rows = await db.query(
        'trip',
        where: 'passenger_id = ?',
        whereArgs: [passengerId],
        orderBy: 'date DESC, heure_arrivee_souhaitee DESC',
        limit: limit,
      );
      return rows.map(Trip.fromMap).toList();
    });
  }

  Future<List<Trip>> getTripsForDriver(String driverId, {DateTime? date}) async {
    final db = await _dbHelper.database;
    return withRetry(() async {
      final where = date != null ? 'driver_id = ? AND date = ?' : 'driver_id = ?';
      final args = date != null
          ? [driverId, DateTime(date.year, date.month, date.day).toIso8601String()]
          : [driverId];
      final rows = await db.query(
        'trip',
        where: where,
        whereArgs: args,
        orderBy: 'heure_ramassage_estimee ASC',
      );
      return rows.map(Trip.fromMap).toList();
    });
  }

  /// Demandes en attente pas encore assignées à un chauffeur — dashboard chauffeur.
  Future<List<Trip>> getUnassignedTrips({DateTime? date, int limit = 30}) async {
    final db = await _dbHelper.database;
    return withRetry(() async {
      final where = date != null ? 'driver_id IS NULL AND date = ?' : 'driver_id IS NULL';
      final args = date != null
          ? [DateTime(date.year, date.month, date.day).toIso8601String()]
          : <Object?>[];
      final rows = await db.query(
        'trip',
        where: where,
        whereArgs: args,
        orderBy: 'heure_ramassage_estimee ASC',
        limit: limit,
      );
      return rows.map(Trip.fromMap).toList();
    });
  }

  Future<Trip?> getTripById(String id) async {
    final db = await _dbHelper.database;
    return withRetry(() async {
      final rows = await db.query('trip', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return Trip.fromMap(rows.first);
    });
  }

  /// Prochaine occurrence à venir d'une entrée de planning (peut avoir
  /// plusieurs Trip liés si l'entrée se répète sur plusieurs jours).
  Future<Trip?> getNextTripForPlanningEntry(String planningEntryId) async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    return withRetry(() async {
      final rows = await db.query(
        'trip',
        where: 'planning_entry_id = ? AND date >= ?',
        whereArgs: [planningEntryId, todayNormalized.toIso8601String()],
        orderBy: 'date ASC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return Trip.fromMap(rows.first);
    });
  }

  Future<void> insertTrip(Trip trip) async {
    final db = await _dbHelper.database;
    await withRetry(
      () => db.insert('trip', trip.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore),
    );
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await _dbHelper.database;
    await withRetry(
      () => db.update('trip', trip.toMap(), where: 'id = ?', whereArgs: [trip.id]),
    );
  }

  /// Un passager rejoint un trajet déjà proposé (résultats disponibles).
  Future<void> joinTrip(String tripId) async {
    final trip = await getTripById(tripId);
    if (trip == null) {
      throw NonRetryableException("Ce trajet n'existe plus.");
    }
    if (trip.estComplet) {
      throw NonRetryableException('Ce trajet est déjà complet.');
    }
    await updateTrip(trip.copyWith(placesRemplies: trip.placesRemplies + 1));
  }

  Future<void> assignDriverAndConfirm(String tripId, String driverId) async {
    final trip = await getTripById(tripId);
    if (trip == null) {
      throw NonRetryableException("Ce trajet n'existe plus.");
    }
    await updateTrip(trip.copyWith(statut: TripStatus.confirme, driverId: driverId));
  }

  Future<void> updateStatus(String tripId, TripStatus statut) async {
    final trip = await getTripById(tripId);
    if (trip == null) {
      throw NonRetryableException("Ce trajet n'existe plus.");
    }
    await updateTrip(trip.copyWith(statut: statut));
  }

  /// Recherche un trajet en attente déjà ouvert sur le même trajet (mock de
  /// matching), ou en crée un nouveau sinon. Permet de voir la jauge évoluer
  /// en live pendant la démo (ex: rejoindre le trajet Ouakam->Plateau du seed).
  Future<Trip> findOrCreateMatch({
    required String passengerId,
    required TripMode mode,
    String? adresseDepart,
    String? destination,
    String? villeDepart,
    String? villeArrivee,
    required String heureArriveeSouhaitee,
    required DateTime date,
  }) async {
    final db = await _dbHelper.database;
    final normalizedDate = DateTime(date.year, date.month, date.day).toIso8601String();

    return withRetry(() async {
      final where = mode == TripMode.interregions
          ? 'mode = ? AND ville_depart = ? AND ville_arrivee = ? AND date = ? AND statut = ?'
          : 'mode = ? AND adresse_depart = ? AND destination = ? AND date = ? AND statut = ?';
      final args = mode == TripMode.interregions
          ? [mode.name, villeDepart, villeArrivee, normalizedDate, TripStatus.enAttente.name]
          : [mode.name, adresseDepart, destination, normalizedDate, TripStatus.enAttente.name];

      final rows = await db.query('trip', where: where, whereArgs: args, limit: 1);
      if (rows.isNotEmpty) {
        final existing = Trip.fromMap(rows.first);
        if (!existing.estComplet) return existing;
      }

      final bufferMinutes = mode == TripMode.interregions
          ? PickupTimeCalculator.interRegionBufferMinutes
          : PickupTimeCalculator.intraCityBufferMinutes;
      final pickup = PickupTimeCalculator.estimatePickupTime(
        heureArriveeSouhaitee,
        bufferMinutes: bufferMinutes,
      );

      final trip = Trip(
        id: 'trip_${DateTime.now().microsecondsSinceEpoch}',
        passengerId: passengerId,
        mode: mode,
        adresseDepart: adresseDepart,
        destination: destination,
        villeDepart: villeDepart,
        villeArrivee: villeArrivee,
        date: date,
        heureArriveeSouhaitee: heureArriveeSouhaitee,
        heureRamassageEstimee: pickup,
        statut: TripStatus.enAttente,
        placesRemplies: 0,
        createdAt: DateTime.now(),
      );
      await db.insert('trip', trip.toMap());
      return trip;
    });
  }
}
