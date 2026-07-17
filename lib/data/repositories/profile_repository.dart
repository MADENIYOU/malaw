import '../../core/utils/cache_service.dart';
import '../../core/utils/retry_util.dart';
import '../local/db_helper.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';

/// Cache in-memory des profils, invalidé explicitement à chaque écriture
/// (pas de TTL temporel : pas de staleness serveur possible en local-only).
class ProfileRepository {
  ProfileRepository({DbHelper? dbHelper}) : _dbHelper = dbHelper ?? DbHelper.instance;

  final DbHelper _dbHelper;
  static const _cacheKey = 'profiles_by_id';

  Future<UserProfile?> getProfileById(String id) async {
    final cached = CacheService.instance.read<Map<String, UserProfile>>(_cacheKey);
    if (cached != null && cached.containsKey(id)) return cached[id];

    final db = await _dbHelper.database;
    final profile = await withRetry(() async {
      final rows = await db.query('user_profile', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return UserProfile.fromMap(rows.first);
    });

    if (profile != null) {
      final map = Map<String, UserProfile>.from(cached ?? {});
      map[id] = profile;
      CacheService.instance.write(_cacheKey, map);
    }
    return profile;
  }

  Future<List<UserProfile>> getProfilesByRole(UserRole role) async {
    final db = await _dbHelper.database;
    return withRetry(() async {
      final rows = await db.query('user_profile', where: 'role = ?', whereArgs: [role.name]);
      return rows.map(UserProfile.fromMap).toList();
    });
  }

  Future<void> updateProfileRole(String id, UserRole role) async {
    final db = await _dbHelper.database;
    await withRetry(
      () => db.update('user_profile', {'role': role.name}, where: 'id = ?', whereArgs: [id]),
    );
    CacheService.instance.invalidate(_cacheKey);
  }
}
