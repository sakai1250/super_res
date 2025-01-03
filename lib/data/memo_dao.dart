// lib/data/memo_dao.dart
import 'db_provider.dart';
import 'memo.dart';

class MemoDao {
  Future<int> insertMemo(Memo memo) async {
    final db = await DBProvider.instance.database;
    return await db.insert('Memo', memo.toMap());
  }

  // フォルダIDを指定してメモ一覧を取得する例
  Future<List<Memo>> getMemosByFolder(int folderId) async {
    final db = await DBProvider.instance.database;
    final res = await db.query(
      'Memo',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
    return res.map((e) => Memo.fromMap(e)).toList();
  }
  // すべてのメモを取得
  Future<List<Memo>> getAllMemos() async {
    final db = await DBProvider.instance.database;
    final res = await db.query('Memo');
    return res.isNotEmpty
      ? res.map((e) => Memo.fromMap(e)).toList()
      : [];
  }
  Future<int> updateMemo(Memo memo) async {
    final db = await DBProvider.instance.database;
    return await db.update(
      'Memo',
      memo.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }
  Future<List<Memo>> searchMemos(String query) async {
    final db = await DBProvider.instance.database;
    if (query.isEmpty) {
      // 全件取得
      final res = await db.query('Memo');
      return res.map((e) => Memo.fromMap(e)).toList();
    } else {
      final res = await db.query(
        'Memo',
        where: 'title LIKE ? OR textContent LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
      return res.map((e) => Memo.fromMap(e)).toList();
    }
  }
}
