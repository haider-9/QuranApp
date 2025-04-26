import 'package:my_app/pages/home.dart' as HomePage;
import 'package:flutter/material.dart';
import 'package:my_app/pages/reading.dart' as Reading;
import 'package:my_app/pages/quran_editions.dart' as edition;
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
        '/quran_editions':
            (context) => const edition.QuranViewPage(edition: 'quran-uthmani'),
        '/audio': (context) => const audio.AudioPage(),
      },
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
    );
  }
}
