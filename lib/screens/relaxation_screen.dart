import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // 👈 IMPORTANT
import 'main_app.dart';

class RelaxationScreen extends StatefulWidget {
  const RelaxationScreen({super.key});

  @override
  State<RelaxationScreen> createState() => _RelaxationScreenState();
}

class _RelaxationScreenState extends State<RelaxationScreen> {
  late AudioPlayer _audioPlayer;
  int _selectedSoundIndex = -1;
  bool _isPlaying = false;

  final List<String> _soundNames = [
    'rain',
    'ocean',
    'lofi',
    'forest',
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Returns platform-specific asset path
  String _getSoundPath(int index) {
    final name = _soundNames[index];

    if (kIsWeb) {
      // Web requires mp3 or wav
      return 'assets/sounds/$name.mp3';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android can use ogg
      return 'assets/sounds/$name.ogg';
    } else {
      // iOS prefers mp3
      return 'assets/sounds/$name.mp3';
    }
  }

  // Toggle sound play/pause
  Future<void> _toggleSound(int index) async {
    try {
      if (_selectedSoundIndex == index) {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.resume();
        }
        setState(() => _isPlaying = !_isPlaying);
      } else {
        await _audioPlayer.stop();

        if (kIsWeb) {
          // On web, use UrlSource
          await _audioPlayer.play(
            UrlSource(_getSoundPath(index)),
          );
        } else {
          // Mobile: AssetSource
          await _audioPlayer.play(
            AssetSource(_getSoundPath(index)),
          );
        }

        setState(() {
          _selectedSoundIndex = index;
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Relaxation'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find your calm with soothing sounds.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildSoundOption('Rain', Icons.cloudy_snowing, Colors.blue, 0),
            _buildSoundOption('Ocean', Icons.waves, Colors.teal, 1),
            _buildSoundOption('Lofi beats', Icons.music_note, Colors.purple, 2),
            _buildSoundOption('Forest', Icons.nature, Colors.green, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundOption(String title, IconData icon, Color color, int index) {
    final isSelected = _selectedSoundIndex == index;
    final isPlayingSelected = isSelected && _isPlaying;

    return GestureDetector(
      onTap: () => _toggleSound(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha:0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
            ),
            Icon(
              isPlayingSelected ? Icons.pause : Icons.play_arrow,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
