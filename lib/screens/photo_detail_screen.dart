import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:super_res/data/memo.dart';
import 'super_resolution_screen.dart';
import '../data/memo_dao.dart';

class PhotoDetailScreen extends StatefulWidget {
  final String imagePath;
  final Memo memo;

  PhotoDetailScreen({required this.imagePath, required this.memo});

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final MemoDao _memoDao = MemoDao();
  late TextEditingController _textController;
  late File _displayedImage;

  @override
  void initState() {
    super.initState();
    final initialText = widget.memo.textContent?.isNotEmpty == true
        ? widget.memo.textContent!
        : "未入力";
    _textController = TextEditingController(text: initialText);
    _displayedImage = File(widget.imagePath);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateImage(Uint8List upscaledImage) {
    setState(() {
      final tempDir = Directory.systemTemp;
      final updatedImage = File('${tempDir.path}/upscaled_image.png');
      updatedImage.writeAsBytesSync(upscaledImage);
      _displayedImage = updatedImage;
    });
  }

  Future<void> _saveMemo() async {
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('保存完了'),
        content: Text('メモを保存しました'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('写真詳細'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveMemo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ズーム可能な画像
            // 👇この部分を置き換える
            SizedBox(
              width: double.infinity,
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 1.0,
                maxScale: 5.0,
                child: Image.file(
                  _displayedImage,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.contain,
                  frameBuilder: (context, child, frame, wasSync) {
                    if (wasSync) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: child,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            // メモ入力欄（下に配置）
            TextField(
              controller: _textController,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'メモを編集',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // 超解像ボタン
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SuperResolutionScreen(
                      originalImage: _displayedImage,
                      onSave: _updateImage,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                '超解像',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
