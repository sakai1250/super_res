// lib/data/folder_dao.dart
import 'db_provider.dart';
import 'folder.dart';

class FolderDao {
  Future<int> insertFolder(Folder folder) async {
    final db = await DBProvider.instance.database;
    return await db.insert('Folder', folder.toMap());
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await DBProvider.instance.database;
    final res = await db.query('Folder', orderBy: 'folderId DESC');
    return res.isNotEmpty
        ? res.map((f) => Folder.fromMap(f)).toList()
        : [];
  }

  Future<Folder?> getFolderById(int folderId) async {
    final db = await DBProvider.instance.database;
    final res = await db.query(
      'Folder',
      where: 'folderId = ?',
      whereArgs: [folderId],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return Folder.fromMap(res.first);
  }

  Future<int> deleteFolder(int folderId) async {
    final db = await DBProvider.instance.database;
    return await db.delete('Folder', where: 'folderId = ?', whereArgs: [folderId]);
  }
}
