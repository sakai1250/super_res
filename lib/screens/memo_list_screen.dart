// lib/screens/memo_list_screen.dart
import 'package:flutter/material.dart';
import '../data/memo_dao.dart';
import '../data/memo.dart';
import '../data/folder_dao.dart';
import '../data/db_provider.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MemoListScreen extends StatefulWidget {
  @override
  _MemoListScreenState createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  final MemoDao _memoDao = MemoDao();
  List<Memo> _memoList = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    final memos = await _memoDao.searchMemos(_searchQuery);
    setState(() {
      _memoList = memos;
    });
  }
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _loadMemos();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memo List'),
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search text',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _memoList.length,
        itemBuilder: (context, index) {
          final memo = _memoList[index];
          return GestureDetector(
            onTap: () {
              // ここで詳細画面などへ
            },
            child: ListTile(
              title: Text(memo.title),
              subtitle: memo.imagePath != null
                  ? Image.file(File(memo.imagePath!))
                  : Text('No Image'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onCameraPressed() async {
    // カメラ or ギャラリーから画像を取得して保存
    // 保存後にDBにinsertし、_loadMemosで再読み込み
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    // アプリ専用ディレクトリへの保存
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path)
        .copy('${appDir.path}/$fileName');

    // フォルダ一覧を取得してユーザーに選ばせる
    final folderDao = FolderDao();
    final allFolders = await folderDao.getAllFolders();

    // ダイアログでフォルダを選択
    int? selectedFolderId;
    await showDialog(
      context: context,
      builder: (ctx) {
      return AlertDialog(
        title: Text('Choose Folder'),
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
      );
    },
  );
    // フォルダが選ばれていないなら中断
    if (selectedFolderId == null) return;
    // DBへ登録
    final newMemo = Memo(
      title: "Sample Memo",
      imagePath: savedImage.path,
      createdAt: DateTime.now().toString(),
      folderId: selectedFolderId, // ★ フォルダIDをセット
    );
    await _memoDao.insertMemo(newMemo);
    _loadMemos();
  }
}



