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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// カメラを起動してメモを作成
  Future<void> _onCameraPressed() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    // 画像をアプリ専用ディレクトリに保存
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

    // フォルダを選択するダイアログを表示し、ユーザーが選んだfolderIdを受け取る
    final folderId = await _showFolderSelectionDialog();
    if (folderId == null) {
      // ユーザーがキャンセルした場合の処理（必要なら）
      return;
    }

    // DBにMemoをINSERT
    final newMemo = Memo(
      title: "Camera Memo",
      imagePath: savedImage.path,
      createdAt: DateTime.now().toString(),
      folderId: folderId,
    );
    await _memoDao.insertMemo(newMemo);

    // ユーザーに成功メッセージなどを表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('写真をフォルダID=$folderId に保存しました')),
    );
  }

  // ギャラリーから選択する
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

    final folderId = await _showFolderSelectionDialog();
    if (folderId == null) {
      return; 
    }

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


  Future<int?> _showFolderSelectionDialog() async {
    final folderDao = FolderDao();
    final allFolders = await folderDao.getAllFolders();
    if (allFolders.isEmpty) {
      return showDialog(
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
      ).then((_) => null); // nullを返す
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
                    Navigator.of(ctx).pop(); // ダイアログを閉じる
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                selectedFolderId = null; // キャンセル
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );

    return selectedFolderId;
  }


  /// フォルダ作成の処理
  Future<void> _onFolderAction() async {
    final folderDao = FolderDao();
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
                final folderName = controller.text.trim();
                if (folderName.isNotEmpty) {
                  await folderDao.insertFolder(Folder(folderName: folderName));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Folder "$folderName" created')),
                  );
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
      // AppBar: タブとカメラアイコン
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
            if (value == 'gallery') {
              await _pickFromGallery();
            } else if (value == 'camera') {
              await _onCameraPressed();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'gallery',
              child: Text('フォルダから選択'),
            ),
            PopupMenuItem(
              value: 'camera',
              child: Text('写真を撮影'),
            ),
          ],
        ),
      ],
      ),
      // タブの中身
      body: TabBarView(
        controller: _tabController,
        children: [
          MemoListScreen(),
          FolderListScreen(),
        ],
      ),

      // 右下のFloatingActionButtonはフォルダ作成専用にする
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.create_new_folder),
        onPressed: _onFolderAction,
      ),
    );
  }
}
