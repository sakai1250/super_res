// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/memo_list_screen.dart';
import 'screens/photo_list_screen.dart';
import 'screens/folder_list_screen.dart';
import 'screens/home_screen.dart';
import 'package:super_res/screens/photo_list_screen.dart';
import 'package:super_res/screens/folder_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Clean App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[50], // 背景を薄グレーに
        primarySwatch: Colors.indigo, // メインカラー（1色）
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo,
        ).copyWith(
          secondary: Colors.indigoAccent,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: HomeScreen(),

      routes: {
        '/photoList': (context) {
          final folderId = ModalRoute.of(context)!.settings.arguments as int;
          return PhotoListScreen(folderId: folderId);
        },
      },
    );
  }
}
