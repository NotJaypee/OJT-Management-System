import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv

void main() async {
  // Load environment variables from .env
  await dotenv.load();

  // Initialize FFI
  sqfliteFfiInit();

  // Set the factory for the database to use the FFI implementation
  databaseFactory = databaseFactoryFfi;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OJT Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 244, 247, 248),
      ),
      home: const HomePage(),
    );
  }
}
