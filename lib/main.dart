import 'package:my_app/pages/home.dart' as HomePage;
import 'package:flutter/material.dart';
import 'package:my_app/pages/reading.dart' as Reading;
import 'package:my_app/pages/audio.dart' as audio;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quran App',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage.HomePage(),
        '/read': (context) => const Reading.ItemList(),
        '/audio': (context) => const audio.AudioPage(),
      },
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Color(0xFFECFDF5),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E4B6C),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Color(0xFF065F46))),
        useMaterial3: true,
      ),
    );
  }
}
