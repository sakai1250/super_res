// lib/screens/folder_list_screen.dart
import 'package:flutter/material.dart';
import '../data/folder_dao.dart';
import '../data/folder.dart';

class FolderListScreen extends StatefulWidget {
  @override
  _FolderListScreenState createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  final FolderDao _folderDao = FolderDao();
  List<Folder> _folderList = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await _folderDao.getAllFolders();
    setState(() {
      _folderList = folders;
    });
  }

Future<void> _addFolder() async {
  TextEditingController controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Add Folder'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Folder Name'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                // FolderDaoを使ってDBにフォルダを追加
                final folderDao = FolderDao();
                await folderDao.insertFolder(Folder(folderName: name));
                // 追加できたら画面を更新
                await _loadFolders(); 
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folders'),
      ),
      body: ListView.builder(
        itemCount: _folderList.length,
        itemBuilder: (context, index) {
          final folder = _folderList[index];
          return ListTile(
            title: Text(folder.folderName),
            onTap: () {
              // 遷移時にフォルダIDを引数として渡す
              Navigator.pushNamed(
                context,
                '/photoList',
                arguments: folder.folderId,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        child: Icon(Icons.add),
      ),
    );
  }
}
