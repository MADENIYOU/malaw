import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../../core/utils/retry_util.dart';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';

/// Initialise et seed la base SQLite locale. Le fichier vit dans le dossier
/// de bases de données de l'app (persistant, jamais vidé comme un cache),
/// donc tout ce qui est saisi en live pendant la démo survit aux redémarrages.
class DbHelper {
  DbHelper._internal();

  static final DbHelper instance = DbHelper._internal();

  Database? _db;
  Future<Database>? _opening;

  /// Les appels concurrents (plusieurs repositories interrogés en parallèle
  /// au chargement d'un écran) doivent attendre la MÊME ouverture en cours
  /// plutôt que d'en déclencher une deuxième — sqflite natif tolère ce genre
  /// de course, mais l'implémentation web (IndexedDB) se retrouve verrouillée
  /// pendant plusieurs secondes si deux `openDatabase` se chevauchent.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _opening ??= _open();
    _db = await _opening;
    return _db!;
  }

  Future<Database> _open() async {
    // Sur le web, sqflite natif n'existe pas : on bascule sur l'implémentation
    // WASM/IndexedDB, transparente pour le reste du code (même API).
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    final databasesDir = await getDatabasesPath();
    final dbPath = p.join(databasesDir, 'covoiturage_app.db');

    return withRetry(
      () => openDatabase(
        dbPath,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Prototype pré-lancement : une montée de version repart d'un schéma
  /// propre plutôt que de migrer des données de démo.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (final table in [
      'trip',
      'planning_entry',
      'planning_jour',
      'planning_mensuel',
      'driver',
      'user_profile',
    ]) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
    await _onCreate(db, newVersion);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        telephone TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE driver (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        vehicule TEXT NOT NULL,
        note REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE planning_mensuel (
        id TEXT PRIMARY KEY,
        passenger_id TEXT NOT NULL,
        statut_global TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Chaque case du calendrier est une entrée indépendante ancrée sur une
    // date précise ; repeat_weekdays (liste de jours séparés par des
    // virgules, vide = pas de répétition) est l'option "façon Google Agenda"
    // choisie dans le formulaire de l'entrée, pas dans le calendrier lui-même.
    await db.execute('''
      CREATE TABLE planning_entry (
        id TEXT PRIMARY KEY,
        planning_id TEXT NOT NULL,
        date TEXT NOT NULL,
        adresse_depart TEXT NOT NULL,
        heure_arrivee TEXT NOT NULL,
        destination TEXT NOT NULL,
        repeat_weekdays TEXT NOT NULL DEFAULT '',
        actif INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (planning_id) REFERENCES planning_mensuel (id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_planning_entry_planning_id ON planning_entry (planning_id)',
    );

    await db.execute('''
      CREATE TABLE trip (
        id TEXT PRIMARY KEY,
        passenger_id TEXT NOT NULL,
        mode TEXT NOT NULL,
        adresse_depart TEXT,
        destination TEXT,
        ville_depart TEXT,
        ville_arrivee TEXT,
        date TEXT NOT NULL,
        heure_arrivee_souhaitee TEXT NOT NULL,
        heure_ramassage_estimee TEXT NOT NULL,
        statut TEXT NOT NULL,
        places_remplies INTEGER NOT NULL DEFAULT 0,
        places_total INTEGER NOT NULL DEFAULT 4,
        driver_id TEXT,
        planning_entry_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    // Index sur les colonnes les plus filtrées (règle scalabilité).
    await db.execute('CREATE INDEX idx_trip_passenger_id ON trip (passenger_id)');
    await db.execute('CREATE INDEX idx_trip_driver_id ON trip (driver_id)');
    await db.execute('CREATE INDEX idx_trip_statut ON trip (statut)');
    await db.execute('CREATE INDEX idx_trip_date ON trip (date)');

    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    const passengerId = 'passager_demo';
    const driverAId = 'chauffeur_1';
    const driverBId = 'chauffeur_2';

    await db.insert(
      'user_profile',
      const UserProfile(
        id: passengerId,
        nom: 'Fatima Sall',
        telephone: '+221 77 123 45 67',
        role: UserRole.passager,
      ).toMap(),
    );
    await db.insert(
      'user_profile',
      const UserProfile(
        id: driverAId,
        nom: 'Moussa Fall',
        telephone: '+221 78 234 56 78',
        role: UserRole.chauffeur,
      ).toMap(),
    );

    await db.insert(
      'driver',
      const Driver(
        id: driverAId,
        nom: 'Moussa Fall',
        vehicule: 'Toyota Sienna · DK-2456-AA',
        note: 4.8,
      ).toMap(),
    );
    await db.insert(
      'driver',
      const Driver(
        id: driverBId,
        nom: 'Fatou Sarr',
        vehicule: 'Hyundai H1 · DK-7788-AB',
        note: 4.6,
      ).toMap(),
    );

    final now = DateTime.now();
    final demain = DateTime(now.year, now.month, now.day + 1);

    final tripsSeed = [
      Trip(
        id: 'trip_seed_1',
        passengerId: passengerId,
        mode: TripMode.ponctuelle,
        adresseDepart: 'Ouakam',
        destination: 'Plateau',
        date: demain,
        heureArriveeSouhaitee: '08:00',
        heureRamassageEstimee: '07:25',
        statut: TripStatus.enAttente,
        placesRemplies: 2,
        createdAt: now,
      ),
      Trip(
        id: 'trip_seed_2',
        passengerId: passengerId,
        mode: TripMode.ponctuelle,
        adresseDepart: 'Almadies',
        destination: 'Point E',
        date: demain,
        heureArriveeSouhaitee: '08:30',
        heureRamassageEstimee: '07:45',
        statut: TripStatus.confirme,
        placesRemplies: 4,
        driverId: driverAId,
        createdAt: now,
      ),
      Trip(
        id: 'trip_seed_3',
        passengerId: passengerId,
        mode: TripMode.interregions,
        villeDepart: 'Dakar',
        villeArrivee: 'Thiès',
        date: demain,
        heureArriveeSouhaitee: '10:00',
        heureRamassageEstimee: '08:30',
        statut: TripStatus.enAttente,
        placesRemplies: 1,
        createdAt: now,
      ),
    ];

    for (final trip in tripsSeed) {
      await db.insert('trip', trip.toMap());
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
      _opening = null;
    }
  }
}
