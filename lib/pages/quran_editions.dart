import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuranData {
  final String name;
  final String edition;
  final List<Surah> surahs;

  QuranData({
    required this.name,
    required this.edition,
    required this.surahs,
  });
}

class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final List<Ayah> ayahs;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.ayahs,
  });
}

class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
  });
}

Future<QuranData> fetchQuran(String edition) async {
  final response = await http.get(
    Uri.parse('http://api.alquran.cloud/v1/quran/$edition'),
  );

  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      final quranData = data['data'];

      List<Surah> surahs = [];
      for (var surah in quranData['surahs']) {
        List<Ayah> ayahs = [];
        for (var ayah in surah['ayahs']) {
          ayahs.add(Ayah(
            number: ayah['number'] ?? 0,
            text: ayah['text'] ?? '',
            numberInSurah: ayah['numberInSurah'] ?? 0,
            juz: ayah['juz'] ?? 0,
          ));
        }

        surahs.add(Surah(
          number: surah['number'] ?? 0,
          name: surah['name'] ?? '',
          englishName: surah['englishName'] ?? '',
          englishNameTranslation: surah['englishNameTranslation'] ?? '',
          ayahs: ayahs,
        ));
      }

      return QuranData(
        name: quranData['name'] ?? '',
        edition: quranData['edition']['identifier'] ?? '',
        surahs: surahs,
      );
    } catch (e) {
      throw Exception('Error parsing the data: $e');
    }
  } else {
    throw Exception('Failed to load Quran data');
  }
}

class QuranViewPage extends StatefulWidget {
  final String edition;

  const QuranViewPage({Key? key, required this.edition}) : super(key: key);

  @override
  _QuranViewPageState createState() => _QuranViewPageState();
}

class _QuranViewPageState extends State<QuranViewPage> {
  late Future<QuranData> quranData;
  int? selectedSurah;

  @override
  void initState() {
    super.initState();
    quranData = fetchQuran(widget.edition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quran - ${widget.edition}'),
      ),
      body: FutureBuilder<QuranData>(
        future: quranData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No Data Available'));
          } else {
            final quran = snapshot.data!;
            
            if (selectedSurah != null) {
              // Show selected surah
              final surah = quran.surahs.firstWhere((s) => s.number == selectedSurah);
              
              return Column(
                children: [
                  AppBar(
                    automaticallyImplyLeading: false,
                    title: Text(
                      '${surah.number}. ${surah.englishName} (${surah.name})',
                      style: const TextStyle(fontSize: 18),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          selectedSurah = null;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: surah.ayahs.length,
                      itemBuilder: (context, index) {
                        final ayah = surah.ayahs[index];
                        final bool isRightToLeft = widget.edition.startsWith('ar');
                        
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${ayah.numberInSurah}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Juz ${ayah.juz}'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  ayah.text,
                                  style: TextStyle(
                                    fontSize: isRightToLeft ? 22 : 18,
                                    height: 1.5,
                                    fontFamily: isRightToLeft ? 'Amiri' : null,
                                  ),
                                  textAlign: isRightToLeft ? TextAlign.right : TextAlign.left,
                                  textDirection: isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              // Show surah list
              return ListView.builder(
                itemCount: quran.surahs.length,
                itemBuilder: (context, index) {
                  final surah = quran.surahs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${surah.number}'),
                    ),
                    title: Text(surah.englishName),
                    subtitle: Text('${surah.englishNameTranslation} - ${surah.ayahs.length} ayahs'),
                                        trailing: Text(
                      surah.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedSurah = surah.number;
                      });
                    },
                  );
                },
              );
            }
          }
        },
      ),
    );
  }
}
