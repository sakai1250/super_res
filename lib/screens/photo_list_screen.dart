import 'package:flutter/material.dart';
import '../data/memo_dao.dart';
import '../data/memo.dart';
import 'photo_detail_screen.dart';
import 'dart:io';

class PhotoListScreen extends StatefulWidget {
  final int folderId;

  PhotoListScreen({required this.folderId});

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
      body: _memoList.isEmpty
          ? Center(child: Text('No photos available'))
          : GridView.builder(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoDetailScreen(
                          memo: memo,
                          imagePath: memo.imagePath!,
                        ),
                      ),
                    );
                  },
                  child: memo.imagePath != null
                      ? Hero(
                          tag: 'photo_${memo.id}', // 各画像に一意のタグを設定
                          child: Image.file(
                            File(memo.imagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          color: Colors.grey,
                          child: Icon(Icons.broken_image),
                        ),
                );
              },
            ),
    );
  }
}
