import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

// A model to hold Surah details
class SurahDetails {
  final String name;
  final String englishName;
  final String englishTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final List<Ayah> ayahs;
  final Map<String, List<Ayah>> translations;

  SurahDetails({
    required this.name,
    required this.englishName,
    required this.englishTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
    required this.translations,
  });
}

class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;
  final String? audioUrl;

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.sajda,
    this.audioUrl,
  });
}

// Fetch Surah details by surahId with translations
Future<SurahDetails> fetchSurahDetails(String surahId) async {
  // Fetch Arabic text (Uthmani)
  final arabicResponse = await http.get(
    Uri.parse('http://api.alquran.cloud/v1/surah/$surahId/quran-uthmani'),
  );

  if (arabicResponse.statusCode != 200) {
    throw Exception('Failed to load Surah details');
  }

  final arabicData = jsonDecode(arabicResponse.statusCode == 200 ? arabicResponse.body : '{"data":{}}');
  final arabicChapter = arabicData['data'];

  // Fetch audio URLs
  final audioResponse = await http.get(
    Uri.parse('http://api.alquran.cloud/v1/surah/$surahId/ar.alafasy'),
  );
  
  final audioData = jsonDecode(audioResponse.statusCode == 200 ? audioResponse.body : '{"data":{}}');
  final audioChapter = audioResponse.statusCode == 200 ? audioData['data'] : null;

  // Fetch translations
  Map<String, List<Ayah>> translations = {};
  
  // Urdu translation
  final urduResponse = await http.get(
    Uri.parse('http://api.alquran.cloud/v1/surah/$surahId/ur.ahmedali'),
  );
  
  if (urduResponse.statusCode == 200) {
    final urduData = jsonDecode(urduResponse.body);
    final urduChapter = urduData['data'];
    
    List<Ayah> urduAyahs = [];
    for (var ayah in urduChapter['ayahs']) {
      urduAyahs.add(Ayah(
        number: ayah['number'],
        text: ayah['text'],
        numberInSurah: ayah['numberInSurah'],
        juz: ayah['juz'],
        manzil: ayah['manzil'],
        page: ayah['page'],
        ruku: ayah['ruku'],
        hizbQuarter: ayah['hizbQuarter'],
        sajda: ayah['sajda'] is bool ? ayah['sajda'] : false,
      ));
    }
    translations['Urdu'] = urduAyahs;
  }

  // English translation
  final englishResponse = await http.get(
    Uri.parse('http://api.alquran.cloud/v1/surah/$surahId/en.asad'),
  );
  
  if (englishResponse.statusCode == 200) {
    final englishData = jsonDecode(englishResponse.body);
    final englishChapter = englishData['data'];
    
    List<Ayah> englishAyahs = [];
    for (var ayah in englishChapter['ayahs']) {
      englishAyahs.add(Ayah(
        number: ayah['number'],
        text: ayah['text'],
        numberInSurah: ayah['numberInSurah'],
        juz: ayah['juz'],
        manzil: ayah['manzil'],
        page: ayah['page'],
        ruku: ayah['ruku'],
        hizbQuarter: ayah['hizbQuarter'],
        sajda: ayah['sajda'] is bool ? ayah['sajda'] : false,
      ));
    }
    translations['English'] = englishAyahs;
  }

  try {
    if (arabicChapter != null) {
      List<Ayah> ayahs = [];
      for (var i = 0; i < arabicChapter['ayahs'].length; i++) {
        var ayah = arabicChapter['ayahs'][i];
        String? audioUrl;
        
        if (audioChapter != null && i < audioChapter['ayahs'].length) {
          audioUrl = audioChapter['ayahs'][i]['audio'];
        }
        
        ayahs.add(Ayah(
          number: ayah['number'],
          text: ayah['text'],
          numberInSurah: ayah['numberInSurah'],
          juz: ayah['juz'],
          manzil: ayah['manzil'],
          page: ayah['page'],
          ruku: ayah['ruku'],
          hizbQuarter: ayah['hizbQuarter'],
          sajda: ayah['sajda'] is bool ? ayah['sajda'] : false,
          audioUrl: audioUrl,
        ));
      }

      return SurahDetails(
        name: arabicChapter['name'],
        englishName: arabicChapter['englishName'],
        englishTranslation: arabicChapter['englishNameTranslation'],
        revelationType: arabicChapter['revelationType'],
        numberOfAyahs: arabicChapter['numberOfAyahs'],
        ayahs: ayahs,
        translations: translations,
      );
    } else {
      throw Exception('Chapter data is missing');
    }
  } catch (e) {
    throw Exception('Error parsing the data: $e');
  }
}

class SurahPage extends StatefulWidget {
  final String surahId;

  const SurahPage({Key? key, required this.surahId}) : super(key: key);

  @override
  _SurahPageState createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  late Future<SurahDetails> surahDetails;
  final AudioPlayer audioPlayer = AudioPlayer();
  int? playingAyahNumber;
  String selectedTranslation = 'None';

  @override
  void initState() {
    super.initState();
    surahDetails = fetchSurahDetails(widget.surahId);
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  void playAudio(String? url, int ayahNumber) async {
    if (url == null) return;
    
    if (playingAyahNumber == ayahNumber) {
      // Stop if already playing
      await audioPlayer.stop();
      setState(() {
        playingAyahNumber = null;
      });
    } else {
      // Play new audio
      await audioPlayer.stop();
      await audioPlayer.play(UrlSource(url));
      setState(() {
        playingAyahNumber = ayahNumber;
      });
      
      // Reset playing state when audio completes
      audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          playingAyahNumber = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surah Details'),
      ),
      body: FutureBuilder<SurahDetails>(
        future: surahDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No Data Available'));
          } else {
            final surah = snapshot.data!;
            
            // Build translation options
            List<String> translationOptions = ['None', ...surah.translations.keys.toList()];
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Surah Name: ${surah.name}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'English Name: ${surah.englishName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'English Translation: ${surah.englishTranslation}',
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revelation Type: ${surah.revelationType}',
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Number of Ayahs: ${surah.numberOfAyahs}',
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Translation selector
                  Row(
                    children: [
                      const Text('Translation: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: selectedTranslation,
                        items: translationOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedTranslation = newValue ?? 'None';
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: surah.ayahs.length,
                      itemBuilder: (context, index) {
                        final ayah = surah.ayahs[index];
                        final bool isPlaying = playingAyahNumber == ayah.number;
                        
                        // Get translation if selected
                        String translationText = '';
                        if (selectedTranslation != 'None' && 
                            surah.translations.containsKey(selectedTranslation) &&
                            index < surah.translations[selectedTranslation]!.length) {
                          translationText = surah.translations[selectedTranslation]![index].text;
                        }
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${ayah.numberInSurah}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (ayah.audioUrl != null)
                                      IconButton(
                                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                                        onPressed: () => playAudio(ayah.audioUrl, ayah.number),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ayah.text,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontFamily: 'Amiri', // Arabic font
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                ),
                                if (translationText.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    translationText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Juz: ${ayah.juz}, Page: ${ayah.page}, Manzil: ${ayah.manzil}, Ruku: ${ayah.ruku}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
