import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/pages/surah.dart';
class Reading {
  final String title;
  final String description;
  final String link;
  Reading({required this.title, required this.description, required this.link});
}

Future<List<Reading>> fetchsurah() async {
  final response = await http.get(
    Uri.parse('https://api.quran.com/api/v4/chapters?language=en'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final surahData = data['chapters'] as List;

    return surahData
        .map(
          (item) => Reading(
            title:
                item['name_simple'] ?? 'No Title', // Updated to 'name_simple'
            description:
                item['translated_name']['name'] ??
                'No Description', // 'translated_name' field
            link: item['id'].toString(),
          ),
        )
        .toList();
  } else {
    throw Exception('Failed to load data');
  }
}

class ItemList extends StatefulWidget {
  const ItemList({super.key});

  @override
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  late Future<List<Reading>> futureSurah;

  @override
  void initState() {
    super.initState();
    futureSurah = fetchsurah();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surah List')),
      body: SingleChildScrollView(
        child: FutureBuilder<List<Reading>>(
          future: futureSurah,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No Data Available'));
            } else {
              final surahList = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  alignment: WrapAlignment.center,
                  children: surahList.map((item) => Read(item: item)).toList(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class Read extends StatelessWidget {
  final Reading item;
  const Read({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E4B6C).withOpacity(0.8),
            const Color(0xFF1E4B6C).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title, // Dynamic title
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description, // Dynamic description
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white,
              ),
              onPressed: () {
                // Navigate to SurahPage and pass the id
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahPage(surahId: item.link),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
