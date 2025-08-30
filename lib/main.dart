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
      title: '超kAI蔵',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.all(12),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 2,
          shape: StadiumBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
