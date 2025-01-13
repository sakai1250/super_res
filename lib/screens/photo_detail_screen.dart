// photo_detail_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:super_res/data/memo.dart';
import 'super_resolution_screen.dart';
import '../data/memo.dart';
import '../data/memo_dao.dart';

class PhotoDetailScreen extends StatefulWidget {
  final String imagePath; // 表示する画像のパス
  final Memo memo; // メモ

  PhotoDetailScreen({required this.imagePath, required this.memo});

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final MemoDao _memoDao = MemoDao();
  late TextEditingController _textController;
  late File _displayedImage; // 表示する画像ファイル
  // final TextEditingController _noteController = TextEditingController(); // メモ入力用

  @override
  void initState() {
    super.initState();
    // 初期値が null なら "未入力" をセット
    final initialText = widget.memo.textContent?.isNotEmpty == true
        ? widget.memo.textContent!
        : "未入力";
    _textController = TextEditingController(text: initialText);
    _displayedImage = File(widget.imagePath); // 初期表示の画像をセット
  }

  void _updateImage(Uint8List upscaledImage) {
    setState(() {
      // Uint8List を一時ファイルに保存
      final tempDir = Directory.systemTemp;
      final updatedImage = File('${tempDir.path}/upscaled_image.png');
      updatedImage.writeAsBytesSync(upscaledImage);

      // 表示する画像を更新
      _displayedImage = updatedImage;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    // _noteController.dispose();
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // 現在の画像を表示
                    Expanded(
                      flex: 3,
                      child: InteractiveViewer(
                        child: Image.file(_displayedImage),
                      ),
                    ),
                    // メモ枠
                    Padding(
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
                    // 超解像ボタン
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SuperResolutionScreen(
                                originalImage: _displayedImage,
                                onSave: _updateImage, // 保存時の処理を渡す
                              ),
                            ),
                          );
                        },
                        child: Text('超解像'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}