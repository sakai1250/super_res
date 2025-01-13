import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_super_resolution/flutter_super_resolution.dart';

class SuperResolutionScreen extends StatefulWidget {
  final File originalImage; // 受け取った画像
  final void Function(Uint8List upscaledImage) onSave; // 保存時のコールバック関数

  const SuperResolutionScreen({
    Key? key,
    required this.originalImage,
    required this.onSave,
  }) : super(key: key);

  @override
  _SuperResolutionScreenState createState() => _SuperResolutionScreenState();
}

class _SuperResolutionScreenState extends State<SuperResolutionScreen> {
  Uint8List? _resizedImage; // 超解像後の画像データ
  final FlutterUpscaler _upscaler = FlutterUpscaler(
    tileSize: 1028,
    overlap: 8,
  );

  @override
  void initState() {
    super.initState();
    _initializeUpscaler();
    _processImage();
  }

  Future<void> _initializeUpscaler() async {
    await _upscaler.initializeModel('assets/rt4ksr_x2.onnx'); // モデルの初期化
  }

  Future<void> _processImage() async {
    final originalImageBytes = await widget.originalImage.readAsBytes();
    final decodedImage = await decodeImageFromList(originalImageBytes);

    if (decodedImage != null) {
      // リサイズ（1028x1028）
      const targetSize = 1028;
      final resizedImage = await _resizeImageToModelSize(decodedImage, targetSize);

      // 超解像を実行
      final upscaledImage = await _upscaler.upscaleImage(resizedImage, 2);

      if (upscaledImage != null) {
        final originalWidth = decodedImage.width * 2;
        final originalHeight = decodedImage.height * 2;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high;

        canvas.drawImageRect(
          upscaledImage,
          Rect.fromLTWH(0, 0, upscaledImage.width.toDouble(), upscaledImage.height.toDouble()),
          Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
          paint,
        );

        final resizedUpscaledImage = await recorder.endRecording().toImage(originalWidth, originalHeight);
        final resizedBytes = await resizedUpscaledImage.toByteData(format: ImageByteFormat.png);

        if (resizedBytes != null) {
          setState(() {
            _resizedImage = resizedBytes.buffer.asUint8List(); // 超解像画像をセット
          });
        }
      }
    }
  }

  Future<ui.Image> _resizeImageToModelSize(ui.Image image, int targetSize) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    final sourceRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final destRect = Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble());

    canvas.drawImageRect(image, sourceRect, destRect, paint);
    return await recorder.endRecording().toImage(targetSize, targetSize);
  }

  @override
  void dispose() {
    _upscaler.dispose(); // リソース解放
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Super-Resolution'),
        actions: [
          if (_resizedImage != null)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                widget.onSave(_resizedImage!); // 保存コールバック
                Navigator.pop(context); // 画面を閉じる
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_resizedImage == null)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(), // 処理中
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Original Image'),
                        Expanded(
                          child: InteractiveViewer(
                            boundaryMargin: EdgeInsets.all(100),
                            minScale: 1.0,
                            maxScale: 100.0,
                            child: Image.file(widget.originalImage),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Upscaled Image'),
                        Expanded(
                          child: InteractiveViewer(
                            boundaryMargin: EdgeInsets.all(100),
                            minScale: 1.0,
                            maxScale: 100.0,
                            child: Image.memory(_resizedImage!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
