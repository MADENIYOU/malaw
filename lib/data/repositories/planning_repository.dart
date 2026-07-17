import 'package:sqflite/sqflite.dart';

import '../../core/utils/pickup_time_calculator.dart';
import '../../core/utils/retry_util.dart';
import '../local/db_helper.dart';
import '../models/enums.dart';
import '../models/planning_entry.dart';
import '../models/planning_mensuel.dart';
import '../models/trip.dart';
import 'trip_repository.dart';

class PlanningRepository {
  PlanningRepository({DbHelper? dbHelper, TripRepository? tripRepository})
    : _dbHelper = dbHelper ?? DbHelper.instance,
      _tripRepository = tripRepository ?? TripRepository();

  final DbHelper _dbHelper;
  final TripRepository _tripRepository;

  Future<PlanningMensuel?> getPlanningForPassenger(String passengerId) async {
    final db = await _dbHelper.database;
    return withRetry(() async {
      final rows = await db.query(
        'planning_mensuel',
        where: 'passenger_id = ?',
        whereArgs: [passengerId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return PlanningMensuel.fromMap(rows.first);
    });
  }

  Future<List<PlanningEntry>> getEntries(String planningId) async {
    final db = await _dbHelper.database;
    return withRetry(() async {
      final rows = await db.query(
        'planning_entry',
        where: 'planning_id = ?',
        whereArgs: [planningId],
        orderBy: 'date ASC',
      );
      return rows.map(PlanningEntry.fromMap).toList();
    });
  }

  Future<PlanningMensuel> createOrGetPlanning(String passengerId) async {
    final existing = await getPlanningForPassenger(passengerId);
    if (existing != null) return existing;

    final db = await _dbHelper.database;
    final planning = PlanningMensuel(
      id: 'planning_${DateTime.now().microsecondsSinceEpoch}',
      passengerId: passengerId,
      statutGlobal: PlanningStatut.actif,
      createdAt: DateTime.now(),
    );
    await withRetry(() => db.insert('planning_mensuel', planning.toMap()));
    return planning;
  }

  Future<void> saveEntry(PlanningEntry entry) async {
    if (entry.adresseDepart.trim().isEmpty || entry.destination.trim().isEmpty) {
      throw NonRetryableException('Adresse de départ et destination requises.');
    }
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(entry.heureArrivee)) {
      throw NonRetryableException("Heure d'arrivée invalide.");
    }
    final db = await _dbHelper.database;
    await withRetry(
      () => db.insert(
        'planning_entry',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    );
  }

  Future<void> setEntryActif(String entryId, bool actif) async {
    final db = await _dbHelper.database;
    await withRetry(
      () => db.update(
        'planning_entry',
        {'actif': actif ? 1 : 0},
        where: 'id = ?',
        whereArgs: [entryId],
      ),
    );
  }

  Future<void> deleteEntry(String entryId) async {
    final db = await _dbHelper.database;
    await withRetry(
      () => db.delete('planning_entry', where: 'id = ?', whereArgs: [entryId]),
    );
  }

  Future<void> setStatutGlobal(String planningId, PlanningStatut statut) async {
    final db = await _dbHelper.database;
    await withRetry(
      () => db.update(
        'planning_mensuel',
        {'statut_global': statut.name},
        where: 'id = ?',
        whereArgs: [planningId],
      ),
    );
  }

  /// Génère les occurrences (Trip) d'une entrée active : une seule sur sa
  /// date ancre si elle ne se répète pas, sinon une par jour de semaine coché
  /// (prochaine occurrence à venir de chacun). Même logique de jauge X/4 que
  /// le ponctuel (seuil non bloquant, décision déjà validée).
  Future<void> generateOccurrences(
    PlanningEntry entry,
    String passengerId,
  ) async {
    if (!entry.actif) return;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    final dates = entry.seRepete
        ? entry.repeatWeekdays.map(_nextDateForWeekday).toList()
        : [
            if (!entry.date.isBefore(todayNormalized)) entry.date,
          ];

    for (final date in dates) {
      final pickup = PickupTimeCalculator.estimatePickupTime(entry.heureArrivee);
      final trip = Trip(
        id: 'trip_${entry.id}_${date.toIso8601String().substring(0, 10)}',
        passengerId: passengerId,
        mode: TripMode.mensuelle,
        adresseDepart: entry.adresseDepart,
        destination: entry.destination,
        date: date,
        heureArriveeSouhaitee: entry.heureArrivee,
        heureRamassageEstimee: pickup,
        statut: TripStatus.enAttente,
        placesRemplies: 0,
        planningEntryId: entry.id,
        createdAt: DateTime.now(),
      );
      await _tripRepository.insertTrip(trip);
    }
  }

  DateTime _nextDateForWeekday(Weekday weekday) {
    final today = DateTime.now();
    final todayIndex = today.weekday; // 1=lundi..7=dimanche
    final targetIndex = weekday.index + 1;
    var diff = targetIndex - todayIndex;
    if (diff <= 0) diff += 7;
    return DateTime(today.year, today.month, today.day).add(Duration(days: diff));
  }
}
