// lib/screens/photo_list_screen.dart
import 'package:flutter/material.dart';
import '../data/memo_dao.dart';
import '../data/memo.dart';
import 'photo_detail_screen.dart';
import 'dart:io';

class PhotoListScreen extends StatefulWidget {
  final int folderId; // コンストラクタで受け取る想定

  PhotoListScreen({required this.folderId}); // required

  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}


class _PhotoListScreenState extends State<PhotoListScreen> {
  final MemoDao _memoDao = MemoDao();
  List<Memo> _memoList = [];

  @override
  void initState() {
    super.initState();
    _loadMemosByFolder();
  }

  Future<void> _loadMemosByFolder() async {
    final memos = await _memoDao.getMemosByFolder(widget.folderId);
    setState(() {
      _memoList = memos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo List (folder: ${widget.folderId})'),
      ),
      body: GridView.builder(
        itemCount: _memoList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final memo = _memoList[index];
          return GestureDetector(
            onTap: () {
              // 写真をタップしたら詳細画面へ
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoDetailScreen(memo: memo),
                ),
              );
            },
            child: memo.imagePath != null
                ? Image.file(File(memo.imagePath!))
                : Container(color: Colors.grey),
          );
        },
      ),
    );
  }
}