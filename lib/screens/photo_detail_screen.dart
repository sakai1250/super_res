// photo_detail_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:super_res/data/memo.dart';
import 'super_resolution_screen.dart';

class PhotoDetailScreen extends StatefulWidget {
  final String imagePath; // 表示する画像のパス

  PhotoDetailScreen({required this.imagePath, required Memo memo});

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late File _displayedImage; // 表示する画像ファイル
  final TextEditingController _noteController = TextEditingController(); // メモ入力用

  @override
  void initState() {
    super.initState();
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
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Detail'),
      ),
      body: Column(
        children: [
          // 現在の画像を表示
          Expanded(
            child: Image.file(_displayedImage),
          ),
          // メモ枠
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // 超解像ボタン
          ElevatedButton(
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
        ],
      ),
    );
  }
}
