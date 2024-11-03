import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  List<dynamic> songs = [];
  bool isLoading = true;
  String currentPlayingUrl = '';

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    try {
      final response = await http.get(Uri.parse('https://storage.googleapis.com/uamp/catalog.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          songs = data['music'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load songs');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching songs: $e');
    }
  }

  void playMusic(String url) async {
    if (currentPlayingUrl == url) {
      // If the same song is clicked, pause it
      await audioPlayer.stop();
      setState(() {
        currentPlayingUrl = '';
      });
    } else {
      // Otherwise, play the new song
      await audioPlayer.play(UrlSource(url));
      setState(() {
        currentPlayingUrl = url;
      });
    }
  }

  void stopMusic() async {
    await audioPlayer.stop();
    setState(() {
      currentPlayingUrl = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lo-Fi Music'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  elevation: 4.0,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        song['image'],
                        width: 60.0,
                        height: 60.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      song['title'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(song['artist']),
                    trailing: IconButton(
                      icon: Icon(
                        currentPlayingUrl == song['source'] ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.purpleAccent,
                        size: 32.0,
                      ),
                      onPressed: () => playMusic(song['source']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
