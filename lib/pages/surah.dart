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

  final arabicData = jsonDecode(
    arabicResponse.statusCode == 200 ? arabicResponse.body : '{"data":{}}',
  );
  final arabicChapter = arabicData['data'];

  // Fetch audio URLs using the same API as audio.dart
  final audioResponse = await http.get(
    Uri.parse('https://api.quran.com/api/v4/chapter_recitations/170/$surahId'),
    headers: {'Accept': 'application/json'},
  );

  Map<int, String> audioUrls = {};
  if (audioResponse.statusCode == 200) {
    final audioData = json.decode(audioResponse.body);
    if (audioData['audio_files'] != null) {
      final audioFiles = audioData['audio_files'] as List;
      for (var file in audioFiles) {
        if (file['verse_key'] != null) {
          final verseNumber =
              int.tryParse(file['verse_key'].toString().split(':').last) ?? 0;
          if (verseNumber > 0) {
            audioUrls[verseNumber] = file['audio_url'];
          }
        }
      }
    }
  }

  // Fetch translations
  Map<String, List<Ayah>> translations = {};

  // Urdu translation
  final urduResponse = await http.get(
    Uri.parse('http://api.alquran.cloud/v1/surah/$surahId/ur.jalandhry'),
  );

  if (urduResponse.statusCode == 200) {
    final urduData = jsonDecode(urduResponse.body);
    final urduChapter = urduData['data'];

    List<Ayah> urduAyahs = [];
    for (var ayah in urduChapter['ayahs']) {
      urduAyahs.add(
        Ayah(
          number: ayah['number'],
          text: ayah['text'],
          numberInSurah: ayah['numberInSurah'],
          juz: ayah['juz'],
          manzil: ayah['manzil'],
          page: ayah['page'],
          ruku: ayah['ruku'],
          hizbQuarter: ayah['hizbQuarter'],
          sajda: ayah['sajda'] is bool ? ayah['sajda'] : false,
        ),
      );
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
      englishAyahs.add(
        Ayah(
          number: ayah['number'],
          text: ayah['text'],
          numberInSurah: ayah['numberInSurah'],
          juz: ayah['juz'],
          manzil: ayah['manzil'],
          page: ayah['page'],
          ruku: ayah['ruku'],
          hizbQuarter: ayah['hizbQuarter'],
          sajda: ayah['sajda'] is bool ? ayah['sajda'] : false,
        ),
      );
    }
    translations['English'] = englishAyahs;
  }

  try {
    if (arabicChapter != null) {
      List<Ayah> ayahs = [];
      for (var i = 0; i < arabicChapter['ayahs'].length; i++) {
        var ayah = arabicChapter['ayahs'][i];
        String? audioUrl;

        // Get audio URL from our new map
        if (audioUrls.containsKey(ayah['numberInSurah'])) {
          audioUrl = audioUrls[ayah['numberInSurah']];
        }

        ayahs.add(
          Ayah(
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
          ),
        );
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

  const SurahPage({super.key, required this.surahId});

  @override
  _SurahPageState createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  late Future<SurahDetails> surahDetails;
  final AudioPlayer audioPlayer = AudioPlayer();
  int? playingAyahNumber;
  String selectedTranslation = 'None';

  // New variables for enhanced audio playback
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isLoading = false;
  bool isAutoPlayEnabled = false;
  int? currentAyahIndex;

  // Colors from home.dart
  final Color backgroundColor = const Color(0xFFECFDF5);
  final Color primaryColor = const Color(0xFF1E4B6C);
  final Color accentColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    surahDetails = fetchSurahDetails(widget.surahId);

    // Set up audio player listeners
    audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed && isAutoPlayEnabled) {
        playNextAyah();
      }
    });

    audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });

    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        playingAyahNumber = null;
        if (isAutoPlayEnabled && currentAyahIndex != null) {
          playNextAyah();
        }
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  // Format duration as mm:ss
  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void playAudio(String? url, int ayahNumber, int index) async {
    if (url == null) return;

    setState(() {
      isLoading = true;
    });

    if (playingAyahNumber == ayahNumber) {
      // Pause if already playing
      await audioPlayer.pause();
      setState(() {
        playingAyahNumber = null;
        currentAyahIndex = null;
        isLoading = false;
      });
    } else {
      // Play new audio
      await audioPlayer.stop();
      try {
        await audioPlayer.play(UrlSource(url));
        setState(() {
          playingAyahNumber = ayahNumber;
          currentAyahIndex = index;
        });
      } catch (e) {
        // Handle error
        print("Error playing audio: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void playNextAyah() async {
    if (currentAyahIndex == null) return;

    final surah = await surahDetails;
    final nextIndex = currentAyahIndex! + 1;

    if (nextIndex < surah.ayahs.length) {
      final nextAyah = surah.ayahs[nextIndex];
      if (nextAyah.audioUrl != null) {
        playAudio(nextAyah.audioUrl, nextAyah.number, nextIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Surah Details'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          // Auto-play toggle button
          IconButton(
            icon: Icon(
              isAutoPlayEnabled ? Icons.repeat_one : Icons.repeat,
              color: isAutoPlayEnabled ? accentColor : Colors.white,
            ),
            onPressed: () {
              setState(() {
                isAutoPlayEnabled = !isAutoPlayEnabled;
              });
            },
            tooltip:
                isAutoPlayEnabled ? 'Disable Auto-Play' : 'Enable Auto-Play',
          ),
        ],
      ),
      body: FutureBuilder<SurahDetails>(
        future: surahDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: primaryColor),
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Text(
                'No Data Available',
                style: TextStyle(color: primaryColor),
              ),
            );
          } else {
            final surah = snapshot.data!;

            // Build translation options
            List<String> translationOptions = [
              'None',
              ...surah.translations.keys,
            ];

            return Column(
              children: [
                // Surah header
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${surah.englishName} - ${surah.englishTranslation}',
                        style: TextStyle(
                          fontSize: 18,
                          color: primaryColor.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoChip('${surah.numberOfAyahs} Ayahs'),
                          const SizedBox(width: 8),
                          _buildInfoChip(surah.revelationType),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Translation selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTranslation,
                            dropdownColor: backgroundColor,
                            style: TextStyle(color: primaryColor),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: primaryColor,
                            ),
                            isExpanded: true,
                            hint: Text(
                              'Select Translation',
                              style: TextStyle(
                                color: primaryColor.withOpacity(0.7),
                              ),
                            ),
                            items:
                                translationOptions.map((String value) {
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
                        ),
                      ),
                    ],
                  ),
                ),

                // Audio player controls (shows when an ayah is playing)
                if (playingAyahNumber != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: primaryColor.withOpacity(0.1),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Playing Ayah ${currentAyahIndex != null ? surah.ayahs[currentAyahIndex!].numberInSurah : ""}',
                              style: TextStyle(color: primaryColor),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.skip_previous,
                                    color: primaryColor,
                                  ),
                                  onPressed:
                                      currentAyahIndex != null &&
                                              currentAyahIndex! > 0
                                          ? () {
                                            final prevIndex =
                                                currentAyahIndex! - 1;
                                            final prevAyah =
                                                surah.ayahs[prevIndex];
                                            playAudio(
                                              prevAyah.audioUrl,
                                              prevAyah.number,
                                              prevIndex,
                                            );
                                          }
                                          : null,
                                ),
                                IconButton(
                                  icon: Icon(
                                    isLoading
                                        ? Icons.hourglass_empty
                                        : Icons.pause,
                                    color: primaryColor,
                                  ),
                                  onPressed:
                                      isLoading
                                          ? null
                                          : () async {
                                            await audioPlayer.pause();
                                            setState(() {
                                              playingAyahNumber = null;
                                            });
                                          },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.skip_next,
                                    color: primaryColor,
                                  ),
                                  onPressed:
                                      currentAyahIndex != null &&
                                              currentAyahIndex! <
                                                  surah.ayahs.length - 1
                                          ? () => playNextAyah()
                                          : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            thumbColor: accentColor,
                            activeTrackColor: accentColor,
                            inactiveTrackColor: primaryColor.withOpacity(0.2),
                          ),
                          child: Slider(
                            min: 0,
                            max: duration.inSeconds.toDouble(),
                            value: position.inSeconds.toDouble(),
                            onChanged: (value) async {
                              final newPosition = Duration(
                                seconds: value.toInt(),
                              );
                              await audioPlayer.seek(newPosition);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatTime(position),
                                style: TextStyle(
                                  color: primaryColor.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                formatTime(duration),
                                style: TextStyle(
                                  color: primaryColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Ayahs list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: surah.ayahs.length,
                    itemBuilder: (context, index) {
                      final ayah = surah.ayahs[index];
                      final bool isPlaying = playingAyahNumber == ayah.number;

                      // Get translation if selected
                      String translationText = '';
                      if (selectedTranslation != 'None' &&
                          surah.translations.containsKey(selectedTranslation) &&
                          index <
                              surah.translations[selectedTranslation]!.length) {
                        translationText =
                            surah
                                .translations[selectedTranslation]![index]
                                .text;
                      }

                      return AyahCard(
                        ayah: ayah,
                        isPlaying: isPlaying,
                        isLoading:
                            isLoading && playingAyahNumber == ayah.number,
                        translationText: translationText,
                        onPlayPressed:
                            () => playAudio(ayah.audioUrl, ayah.number, index),
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                        backgroundColor: backgroundColor,
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// New widget for displaying individual ayahs
class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final bool isPlaying;
  final bool isLoading;
  final String translationText;
  final VoidCallback onPlayPressed;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;

  const AyahCard({
    super.key,
    required this.ayah,
    required this.isPlaying,
    required this.isLoading,
    required this.translationText,
    required this.onPlayPressed,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isPlaying ? primaryColor.withOpacity(0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isPlaying ? accentColor : Colors.grey.withOpacity(0.2),
          width: isPlaying ? 2 : 1,
        ),
      ),
      elevation: isPlaying ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ayah header with number and audio controls
            Row(
              children: [
                // Ayah number in decorative circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isPlaying
                            ? accentColor.withOpacity(0.2)
                            : primaryColor.withOpacity(0.1),
                    border: Border.all(
                      color:
                          isPlaying
                              ? accentColor
                              : primaryColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: TextStyle(
                        color: isPlaying ? accentColor : primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Ayah metadata
                Text(
                  'Juz ${ayah.juz} | Page ${ayah.page}',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 16),
                // Play button
                if (ayah.audioUrl != null)
                  isLoading
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                      : IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: isPlaying ? accentColor : primaryColor,
                          size: 28,
                        ),
                        onPressed: onPlayPressed,
                      ),
              ],
            ),
            const SizedBox(height: 16),

            // Arabic text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ayah.text,
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Amiri',
                  height: 1.8,
                  color: primaryColor,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),

            // Translation text if available
            if (translationText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  translationText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: primaryColor.withOpacity(0.8),
                  ),
                ),
              ),
            ],

            // Additional metadata
            if (ayah.sajda) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.volunteer_activism, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sajdah',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
