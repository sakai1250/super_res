// lib/screens/photo_detail_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../data/memo.dart';
import '../data/memo_dao.dart';

class PhotoDetailScreen extends StatefulWidget {
  final Memo memo;

  PhotoDetailScreen({required this.memo});

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final MemoDao _memoDao = MemoDao();
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    // 初期値が null なら "未入力" をセット
    final initialText = widget.memo.textContent?.isNotEmpty == true
        ? widget.memo.textContent!
        : "未入力";
    _textController = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveMemo() async {
    // "未入力"のままだったらnullにしておくか、文字列のまま保存するかはお好みで
    final updatedText =
        _textController.text == "未入力" ? null : _textController.text;

    final updatedMemo = Memo(
      id: widget.memo.id,
      title: widget.memo.title,
      imagePath: widget.memo.imagePath,
      createdAt: widget.memo.createdAt,
      folderId: widget.memo.folderId,
      textContent: updatedText,
    );
    await _memoDao.updateMemo(updatedMemo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('メモを更新しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Detail'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveMemo,
          ),
        ],
      ),
      body: Column(
        children: [
          // 写真プレビュー
          widget.memo.imagePath != null
              ? Image.file(File(widget.memo.imagePath!))
              : Container(
                  color: Colors.grey,
                  height: 200,
                  child: Center(
                    child: Text('No Image'),
                  ),
                ),
          // メモ入力欄
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textController,
                maxLines: null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'メモを入力してください',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
