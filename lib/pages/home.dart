import 'package:flutter/material.dart';
import 'package:my_app/components/card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECFDF5),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Welcome to Quran App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('Your Personal Quran Companion'),
              const SizedBox(height: 20),
              const ItemList(),
            ],
          ),
        ),
      ),
    );
  }
}