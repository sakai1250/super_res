import 'dart:io';
import 'package:flutter/material.dart';

class FadingImageFile extends StatelessWidget {
  final File file;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Duration duration;

  const FadingImageFile({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: duration,
          curve: Curves.easeInOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }
}

