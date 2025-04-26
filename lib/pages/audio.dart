import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AudioPage extends StatefulWidget {
  const AudioPage({Key? key}) : super(key: key);

  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String _currentLanguage = 'English';
  String _currentRecitationUrl = '';
  String _currentRecitationTitle = '';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  List<Map<String, dynamic>> _recitations = [];

  // API endpoints
  final Map<String, String> _apiEndpoints = {
    'English': 'https://api.quran.com/api/v4/chapter_recitations/7',
    'Arabic': 'https://api.quran.com/api/v4/chapter_recitations/1',
    'Urdu': 'https://api.quran.com/api/v4/resources/translations/95',
  };

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
    _fetchRecitations(_currentLanguage);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchRecitations(String language) async {
    setState(() {
      _isLoading = true;
      _recitations = []; // Clear previous recitations
    });

    try {
      final endpoint = _apiEndpoints[language] ?? '';
      if (endpoint.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> parsedRecitations = [];

        if (language == 'English') {
          // Parse English recitations from Quran.com API
          final audioFiles = data['audio_files'] as List;
          parsedRecitations =
              audioFiles.map((file) {
                return {
                  'id': file['id'].toString(),
                  'title':
                      'Surah ${file['chapter_id']} - ${file['reciter_name']}',
                  'url': file['audio_url'],
                  'duration': _formatDuration(
                    Duration(seconds: file['duration'] ?? 0),
                  ),
                  'author': file['reciter_name'],
                };
              }).toList();
        } else if (language == 'Arabic') {
          // Parse Arabic recitations from Quran.com API
          final audioFiles = data['audio_files'] as List;
          parsedRecitations =
              audioFiles.map((file) {
                return {
                  'id': file['id'].toString(),
                  'title':
                      'سورة ${file['chapter_id']} - ${file['reciter_name']}',
                  'url': file['audio_url'],
                  'duration': _formatDuration(
                    Duration(seconds: file['duration'] ?? 0),
                  ),
                  'author': file['reciter_name'],
                };
              }).toList();
        } else if (language == 'Urdu') {
          // Parse Urdu translations from Quran.com API
          final translations = data['translations'] as List;
          parsedRecitations =
              translations.map((translation) {
                return {
                  'id': translation['id'].toString(),
                  'title': translation['name'],
                  'url': translation['audio_url'] ?? '',
                  'duration': 'N/A',
                  'author': translation['author_name'],
                };
              }).toList();
        }

        setState(() {
          _recitations = parsedRecitations;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load recitations');
      }
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
      appBar: AppBar(title: const Text('Quran Recitations')),
      body: Column(
        children: [
          // Language selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _languageButton('English'),
                _languageButton('Arabic'),
                _languageButton('Urdu'),
              ],
            ),
          ),

          // Recitation list
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _recitations.isEmpty
                    ? Center(child: Text('No recitations available'))
                    : ListView.builder(
                      itemCount: _recitations.length,
                      itemBuilder: (context, index) {
                        final recitation = _recitations[index];
                        final isSelected =
                            _currentRecitationUrl == recitation['url'];

                        return ListTile(
                          title: Text(recitation['title']),
                          subtitle: Text(recitation['author'] ?? ''),
                          leading: Icon(Icons.audio_file),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(recitation['duration'] ?? ''),
                              SizedBox(width: 8),
                              isSelected && _isPlaying
                                  ? Icon(
                                    Icons.pause,
                                    color: Theme.of(context).primaryColor,
                                  )
                                  : Icon(Icons.play_arrow),
                            ],
                          ),
                          selected: isSelected,
                          onTap: () {
                            _playRecitation(
                              recitation['url'],
                              recitation['title'],
                            );
                          },
                        );
                      },
                    ),
          ),

          // Player controls
          if (_currentRecitationUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[200],
              child: Column(
                children: [
                  Text(
                    _currentRecitationTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Slider(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position)),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.replay_10),
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
                        icon: Icon(Icons.forward_10),
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

  Widget _languageButton(String language) {
    final isSelected = _currentLanguage == language;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      onPressed: () {
        if (_currentLanguage != language) {
          setState(() {
            _currentLanguage = language;
            _currentRecitationUrl = '';
            _currentRecitationTitle = '';
          });
          _audioPlayer.stop();
          _fetchRecitations(language);
        }
      },
      child: Text(language),
    );
  }
}
