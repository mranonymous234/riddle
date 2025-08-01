import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:http/http.dart' as http;
import 'dart:math';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _dark = true;
  bool _loading = false;
  String _riddle = '';
  List<String> _favs = [];

  Future<void> loadRiddle() async {
    setState(() {
      _loading = true;
      _riddle = '';
    });
    final rand = Random().nextInt(100000);
    final uri = Uri.parse(
        'https://text.pollinations.ai/Write_an_unsolvable_riddle_in_a_poetic_style_dont_give_other_stuff_like_ok_response_just_one_riddle_also_use_simple_english_and_give_random_at_a_time_$rand');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        _riddle = res.body.trim();
      } else {
        _riddle = 'Error ${res.statusCode}';
      }
    } catch (e) {
      _riddle = 'Exception: $e';
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadRiddle();
  }

  void _copyRiddle(String text) async {
    if (text.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📋 Text copied to clipboard!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Copy failed: $e'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext m) {
    final theme = _dark ? ThemeData.dark() : ThemeData.light();
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Riddle Realms'),
          actions: [
            IconButton(
              icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _dark = !_dark),
              tooltip: _dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
            IconButton(
              icon: const Icon(Icons.favorite),
              tooltip: 'View Favorites',
              onPressed: () => showModalBottomSheet(
                context: m,
                backgroundColor: _dark ? Colors.grey[900] : Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: _favs.isEmpty
                      ? const Center(child: Text('No favorites yet'))
                      : ListView.builder(
                          itemCount: _favs.length,
                          itemBuilder: (context, index) {
                            final fav = _favs[index];
                            return Card(
                              child: ListTile(
                                title: Text(fav),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.copy, color: Colors.blue),
                                      tooltip: 'Copy',
                                      onPressed: () => _copyRiddle(fav),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Delete',
                                      onPressed: () {
                                        setState(() {
                                          _favs.removeAt(index);
                                        });
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
              ),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading) const CircularProgressIndicator(),
                if (!_loading)
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
                      icon: const Icon(Icons.refresh),
                      label: const Text('New'),
                      onPressed: loadRiddle,
                    ),
                    ElevatedButton.icon(
                      icon: Icon(_favs.contains(_riddle) ? Icons.favorite : Icons.favorite_border),
                      label: Text(_favs.contains(_riddle) ? 'Saved' : 'Save'),
                      onPressed: () {
                        if (_riddle.isEmpty) return;
                        setState(() {
                          if (_favs.contains(_riddle)) {
                            _favs.remove(_riddle);
                          } else {
                            _favs.add(_riddle);
                          }
                        });
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      onPressed: _riddle.isNotEmpty ? () => _copyRiddle(_riddle) : null,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
