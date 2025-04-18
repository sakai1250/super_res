import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'memo_list_screen.dart';
import 'folder_list_screen.dart';
import '../data/memo_dao.dart';
import '../data/memo.dart';
import '../data/folder.dart';
import '../data/folder_dao.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MemoDao _memoDao = MemoDao();
  final FolderDao _folderDao = FolderDao();
  List<Folder> _folderList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await _folderDao.getAllFolders();
    if (mounted) {
      setState(() {
        _folderList = folders;
      });
    }
  }

  Future<void> _onFolderAction() async {
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
                  await _folderDao.insertFolder(Folder(folderName: name));
                  await _loadFolders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Folder "$name" created')),
                  );
                }
                if (context.mounted) Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

    final folderId = await _showFolderSelectionDialog();
    if (folderId == null) return;

    final newMemo = Memo(
      title: "Gallery Memo",
      imagePath: savedImage.path,
      createdAt: DateTime.now().toString(),
      folderId: folderId,
    );
    await _memoDao.insertMemo(newMemo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ギャラリーからの写真をフォルダID=$folderId に保存しました')),
    );
  }

  Future<void> _onCameraPressed() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

    final folderId = await _showFolderSelectionDialog();
    if (folderId == null) return;

    final newMemo = Memo(
      title: "Camera Memo",
      imagePath: savedImage.path,
      createdAt: DateTime.now().toString(),
      folderId: folderId,
    );
    await _memoDao.insertMemo(newMemo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('写真をフォルダID=$folderId に保存しました')),
    );
  }

  Future<int?> _showFolderSelectionDialog() async {
    final allFolders = await _folderDao.getAllFolders();
    if (allFolders.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('No Folders Found'),
          content: Text('Please create a folder before adding a memo.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return null;
    }

    int? selectedFolderId;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Select Folder'),
          content: SingleChildScrollView(
            child: Column(
              children: allFolders.map((folder) {
                return ListTile(
                  title: Text(folder.folderName),
                  onTap: () {
                    selectedFolderId = folder.folderId;
                    Navigator.of(ctx).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                selectedFolderId = null;
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );

    return selectedFolderId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Memo'),
            Tab(text: 'Folder'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add),
            onSelected: (value) async {
              if (value == 'gallery') await _pickFromGallery();
              else if (value == 'camera') await _onCameraPressed();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'gallery', child: Text('フォルダから選択')),
              PopupMenuItem(value: 'camera', child: Text('写真を撮影')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MemoListScreen(),
          FolderListScreen(folderList: _folderList), // ← これが超重要！
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.create_new_folder),
        onPressed: _onFolderAction,
      ),
    );
  }
}
