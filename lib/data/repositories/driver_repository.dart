import '../../core/utils/retry_util.dart';
import '../local/db_helper.dart';
import '../models/driver.dart';

class DriverRepository {
  DriverRepository({DbHelper? dbHelper}) : _dbHelper = dbHelper ?? DbHelper.instance;

  final DbHelper _dbHelper;

  Future<List<Driver>> getAllDrivers() async {
    final db = await _dbHelper.database;
    return withRetry(() async {
      final rows = await db.query('driver', orderBy: 'note DESC');
      return rows.map(Driver.fromMap).toList();
    });
  }

  Future<Driver?> getDriverById(String id) async {
    final db = await _dbHelper.database;
    return withRetry(() async {
      final rows = await db.query('driver', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return Driver.fromMap(rows.first);
    });
  }
}
