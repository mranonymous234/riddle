import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'package:flutter/services.dart'; // For clipboard

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _dark = true;
  bool _loading = false;
  String _riddle = '';
  List<String> _favorites = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() => _isPlaying = false);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _generateRiddle();
  }

  Future<void> _generateRiddle() async {
    setState(() {
      _loading = true;
      _riddle = '';
    });

    final rand = Random().nextInt(100000);
    final url =
        'https://text.pollinations.ai/Write_an_unsolvable_riddle_in_a_poetic_style_dont_give_other_stuff_like_ok_response_just_one_riddle_also_use_simple_english_and_give_random_at_a_time_\$rand';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          _riddle = res.body.trim();
        });
      } else {
        setState(() {
          _riddle = 'Error \${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _riddle = 'Network error: \$e';
      });
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _playTTS() async {
    if (_riddle.isEmpty) return;
    final ttsUrl =
        'https://text.pollinations.ai/\${Uri.encodeComponent(_riddle)}?model=openai-audio&voice=nova';
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(ttsUrl);
    } catch (_) {}
  }

  Future<void> _stopTTS() async {
    await _audioPlayer.stop();
    setState(() => _isPlaying = false);
  }

  void _copyRiddle(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  void _toggleFavorite() {
    if (_favorites.contains(_riddle)) {
      _favorites.remove(_riddle);
    } else {
      _favorites.add(_riddle);
    }
    setState(() {});
  }

  void _showFavorites() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: _favorites.isEmpty
            ? const Center(child: Text('No favorites yet'))
            : ListView.builder(
                itemCount: _favorites.length,
                itemBuilder: (context, i) {
                  final fav = _favorites[i];
                  return Card(
                    child: ListTile(
                      title: Text(fav),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => _copyRiddle(fav),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() => _favorites.removeAt(i));
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFav = _favorites.contains(_riddle);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riddle Realms'),
        actions: [
          IconButton(icon: const Icon(Icons.favorite), onPressed: _showFavorites),
          IconButton(
            icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _dark = !_dark),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _riddle,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _generateRiddle,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate'),
                ),
                ElevatedButton.icon(
                  onPressed: (_riddle.isEmpty) ? null : _toggleFavorite,
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                  label: Text(isFav ? 'Saved' : 'Save'),
                ),
                ElevatedButton.icon(
                  onPressed: (_riddle.isEmpty)
                      ? null
                      : _isPlaying
                          ? _stopTTS
                          : _playTTS,
                  icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
                  label: Text(_isPlaying ? 'Stop' : 'Listen'),
                ),
                ElevatedButton.icon(
                  onPressed: (_riddle.isEmpty) ? null : () => _copyRiddle(_riddle),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ],
            )
          ],
        ),
      ),
      backgroundColor: _dark ? Colors.grey[900] : null,
    );
  }
}
