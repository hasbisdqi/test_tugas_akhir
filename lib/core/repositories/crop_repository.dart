import '../database/database_helper.dart';
import '../../models/crop_model.dart';

class CropRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<CropModel>> getAllCrops({int? userId}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        'crops',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('crops', orderBy: 'created_at DESC');
    }
    return maps.map((e) => CropModel.fromMap(e)).toList();
  }

  Future<CropModel> createCrop(CropModel crop) async {
    final db = await _dbHelper.database;
    final id = await db.insert('crops', crop.toMap());
    return crop.copyWith(id: id);
  }

  Future<int> updateCrop(CropModel crop) async {
    final db = await _dbHelper.database;
    return await db.update(
      'crops',
      crop.toMap(),
      where: 'id = ?',
      whereArgs: [crop.id],
    );
  }

  Future<int> deleteCrop(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'crops',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CropModel>> searchCrops(String query, {int? userId, String? statusFilter}) async {
    final db = await _dbHelper.database;
    String whereClause = '(name LIKE ? OR variety LIKE ? OR notes LIKE ?)';
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%'];

    if (userId != null) {
      whereClause += ' AND user_id = ?';
      whereArgs.add(userId);
    }
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      whereClause += ' AND status = ?';
      whereArgs.add(statusFilter);
    }

    final maps = await db.query(
      'crops',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((e) => CropModel.fromMap(e)).toList();
  }
}
