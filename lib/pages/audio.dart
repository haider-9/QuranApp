import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String _currentRecitationUrl = '';
  String _currentRecitationTitle = '';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  List<Map<String, dynamic>> _recitations = [];

  // Selected reciter ID
  int _selectedReciterId = 2;

  // List of available reciters
  final List<Map<String, dynamic>> _reciters = [
    {'id': 7, 'name': 'Mishary Rashid Alafasy'},
    {'id': 3, 'name': 'Abdul Rahman Al-Sudais'},
    {'id': 2, 'name': 'Abdul Basit Abdul Samad'},
    {'id': 6, 'name': 'Mahmoud Khalil Al-Husary'},
    {'id': 9, 'name': 'Siddiq Al-Mishawi'},
  ];

  // Colors from surah.dart
  final Color backgroundColor = const Color(0xFFECFDF5);
  final Color primaryColor = const Color(0xFF1E4B6C);
  final Color accentColor = const Color(0xFF10B981);

  // API endpoint for Arabic recitations (will be formatted with reciter ID)
  final String _audioEndpointTemplate =
      'https://api.quran.com/api/v4/chapter_recitations/';

  // New endpoint for fetching surah names
  final String _surahNamesEndpoint = 'http://api.alquran.cloud/v1/surah';

  @override
  void initState() {
    super.initState();

    // Set up audio player listeners
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });

    // Fetch initial recitations
    _fetchRecitations();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchRecitations() async {
    setState(() {
      _isLoading = true;
      _recitations = []; // Clear previous recitations
    });

    try {
      // First fetch surah names from alquran.cloud API
      final surahResponse = await http.get(
        Uri.parse(_surahNamesEndpoint),
        headers: {'Accept': 'application/json'},
      );

      if (surahResponse.statusCode != 200) {
        throw Exception('Failed to load surah names');
      }

      final surahData = json.decode(surahResponse.body);
      final List<dynamic> surahs = surahData['data'];

      // Map of surah IDs to names
      Map<int, Map<String, String>> surahNames = {};
      for (var surah in surahs) {
        surahNames[surah['number']] = {
          'name': surah['name'],
          'englishName': surah['englishName'],
        };
      }

      // Now fetch audio recitations from quran.com API with selected reciter
      final String _audioEndpoint =
          _audioEndpointTemplate + _selectedReciterId.toString();

      final response = await http.get(
        Uri.parse(_audioEndpoint),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load recitations');
      }

      final data = json.decode(response.body);
      List<Map<String, dynamic>> parsedRecitations = [];

      // Parse Arabic recitations from Quran.com API
      final audioFiles = data['audio_files'] as List;
      for (var file in audioFiles) {
        final chapterId = file['chapter_id'];
        if (surahNames.containsKey(chapterId)) {
          parsedRecitations.add({
            'id': file['id'].toString(),
            'title':
                '${surahNames[chapterId]!['name']} - ${surahNames[chapterId]!['englishName']}',
            'url': file['audio_url'],
            'duration': _formatDuration(
              Duration(seconds: file['duration'] ?? 0),
            ),
            'author': file['reciter_name'],
            'chapter_id': chapterId,
          });
        }
      }

      parsedRecitations.sort(
        (a, b) => a['chapter_id'].compareTo(b['chapter_id']),
      );

      setState(() {
        _recitations = parsedRecitations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching recitations: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load recitations: $e')));
    }
  }

  Future<void> _playRecitation(String url, String title) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No audio available for this recitation')),
      );
      return;
    }

    if (_currentRecitationUrl == url && _isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else if (_currentRecitationUrl == url && !_isPlaying) {
      await _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
      });
    } else {
      // New audio to play
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _duration = Duration.zero;
        _currentRecitationUrl = url;
        _currentRecitationTitle = title;
      });

      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        print('Error playing audio: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play audio: $e')));
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Quran Recitations'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Reciter selection dropdown
          Container(
            padding: const EdgeInsets.all(16.0),
            color: primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Text(
                  'Select Reciter:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedReciterId,
                      isExpanded: true,
                      underline: SizedBox(),
                      icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                      items:
                          _reciters.map((reciter) {
                            return DropdownMenuItem<int>(
                              value: reciter['id'],
                              child: Text(reciter['name']),
                            );
                          }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null &&
                            newValue != _selectedReciterId) {
                          setState(() {
                            _selectedReciterId = newValue;
                            // Stop current playback when changing reciter
                            if (_isPlaying) {
                              _audioPlayer.stop();
                              _isPlaying = false;
                              _currentRecitationUrl = '';
                              _currentRecitationTitle = '';
                            }
                          });
                          _fetchRecitations();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recitation list
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                    : _recitations.isEmpty
                    ? Center(
                      child: Text(
                        'No recitations available',
                        style: TextStyle(color: primaryColor),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _recitations.length,
                      itemBuilder: (context, index) {
                        final recitation = _recitations[index];
                        final isSelected =
                            _currentRecitationUrl == recitation['url'];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color:
                              isSelected
                                  ? primaryColor.withOpacity(0.1)
                                  : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? accentColor
                                      : Colors.grey.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          elevation: isSelected ? 4 : 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              recitation['title'],
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              recitation['author'] ?? '',
                              style: TextStyle(
                                color: primaryColor.withOpacity(0.7),
                              ),
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isSelected
                                        ? accentColor.withOpacity(0.2)
                                        : primaryColor.withOpacity(0.1),
                              ),
                              child: Center(
                                child: Text(
                                  '${recitation['chapter_id']}',
                                  style: TextStyle(
                                    color:
                                        isSelected ? accentColor : primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  recitation['duration'] ?? '',
                                  style: TextStyle(
                                    color: primaryColor.withOpacity(0.7),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  isSelected && _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color:
                                      isSelected ? accentColor : primaryColor,
                                  size: 28,
                                ),
                              ],
                            ),
                            selected: isSelected,
                            onTap: () {
                              _playRecitation(
                                recitation['url'],
                                recitation['title'],
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),

          // Player controls
          if (_currentRecitationUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: primaryColor.withOpacity(0.1),
              child: Column(
                children: [
                  Text(
                    _currentRecitationTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      thumbColor: accentColor,
                      activeTrackColor: accentColor,
                      inactiveTrackColor: primaryColor.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _position.inSeconds.toDouble(),
                      max:
                          _duration.inSeconds.toDouble() == 0
                              ? 1
                              : _duration.inSeconds.toDouble(),
                      onChanged: (value) async {
                        final position = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(position);
                        setState(() {
                          _position = position;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.replay_10, color: primaryColor),
                        onPressed: () async {
                          final newPosition = Duration(
                            seconds: (_position.inSeconds - 10).clamp(
                              0,
                              _duration.inSeconds,
                            ),
                          );
                          await _audioPlayer.seek(newPosition);
                        },
                      ),
                      IconButton(
                        iconSize: 50,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: accentColor,
                        ),
                        onPressed: () {
                          if (_isPlaying) {
                            _audioPlayer.pause();
                            setState(() {
                              _isPlaying = false;
                            });
                          } else {
                            _audioPlayer.resume();
                            setState(() {
                              _isPlaying = true;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.forward_10, color: primaryColor),
                        onPressed: () async {
                          final newPosition = Duration(
                            seconds: (_position.inSeconds + 10).clamp(
                              0,
                              _duration.inSeconds,
                            ),
                          );
                          await _audioPlayer.seek(newPosition);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
