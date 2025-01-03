// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/memo_list_screen.dart';
import 'screens/photo_list_screen.dart';
import 'screens/folder_list_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),    // ここにカメラアイコンのある画面を指定
      // routes定義 (main.dartなど)
      routes: {
        '/photoList': (context) {
          final folderId = ModalRoute.of(context)!.settings.arguments as int;
          return PhotoListScreen(folderId: folderId);
        },
      },
    );
  }
}


