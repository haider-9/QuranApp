import 'package:flutter/material.dart';
import 'package:my_app/components/card.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
         
          children: [
            const Icon(Icons.book,size: 32,),
            const SizedBox(width: 4,),
            const Text('Quran App'),
           
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Quran App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              const ItemList(),
            ],
          ),
        ),
      ),
    );
  }
}
