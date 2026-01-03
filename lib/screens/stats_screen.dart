import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';
import 'journal_entry_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final HiveStorage _storage = HiveStorage();

  double _averageMood = 0.0;
  int _streak = 0;
  List<Map<String, dynamic>> _mostFrequentEmotions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int _calculateStreak(List<Map<String, dynamic>> entries) {
  if (entries.isEmpty) return 0;
  entries.sort((a, b) => b['date'].compareTo(a['date'])); // latest first
  int streak = 1;
  DateTime previous = DateTime.parse(entries[0]['date']);
  for (int i = 1; i < entries.length; i++) {
    final current = DateTime.parse(entries[i]['date']);
    if (previous.difference(current).inDays == 1) {
      streak++;
      previous = current;
    } else {
      break;
    }
  }
  return streak;
}


  Future<void> _loadData() async {
    final entries = _storage.getJournalEntries();

    if (entries.isEmpty) {
      setState(() {
        _averageMood = 0.0;
        _streak = _calculateStreak(entries);
        _mostFrequentEmotions = [];
      });
      return;
    }

    // Average mood
    double sum = 0;
    for (var entry in entries) {
      sum += (entry['mood'] as int).toDouble();
    }
    final avgMood = sum / entries.length;

    // Most frequent emotions
    final Map<int, int> moodCount = {};
    for (var entry in entries) {
      final mood = entry['mood'] as int;
      moodCount[mood] = (moodCount[mood] ?? 0) + 1;
    }

    List<Map<String, dynamic>> emotions = [];
    moodCount.forEach((mood, count) {
      emotions.add({
        'emotion': _getMoodName(mood),
        'percentage': (count / entries.length) * 100,
      });
    });

    emotions.sort((a, b) => b['percentage'].compareTo(a['percentage']));
    if (emotions.length > 4) emotions = emotions.sublist(0, 4);

    setState(() {
      _averageMood = avgMood;
     _streak = _calculateStreak(entries);
      _mostFrequentEmotions = emotions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Insights'),
        backgroundColor: Colors.purple,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Average Mood
              _buildCard(
                child: Column(
                  children: [
                    const Text(
                      'Average Mood',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_averageMood.toStringAsFixed(1)}/5',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getMoodNameFromValue(_averageMood),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _averageMood / 5.0,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.purple,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Streak
              _buildCard(
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Streak',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_streak days',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Keep it up 🔥',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Frequent emotions
              const Text(
                'Your most frequent emotions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: _mostFrequentEmotions.map((emotion) {
                  return _buildEmotionCard(
                    emotion['emotion'],
                    '${emotion['percentage'].toStringAsFixed(0)}%',
                    _getColorForEmotion(emotion['emotion']),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Add entry
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JournalEntryScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: const Center(
                    child: Text(
                      'Add Journal Entry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  String _getMoodName(int moodIndex) {
    switch (moodIndex) {
      case 0:
        return 'Very Sad';
      case 1:
        return 'Sad';
      case 2:
        return 'Okay';
      case 3:
        return 'Happy';
      case 4:
        return 'Amazing';
      default:
        return 'Okay';
    }
  }

  String _getMoodNameFromValue(double value) {
    if (value < 1.5) return 'Very Sad';
    if (value < 2.5) return 'Sad';
    if (value < 3.5) return 'Okay';
    if (value < 4.5) return 'Happy';
    return 'Amazing';
  }

  Color _getColorForEmotion(String emotion) {
    switch (emotion) {
      case 'Very Sad':
        return Colors.blue.shade100;
      case 'Sad':
        return Colors.green.shade100;
      case 'Okay':
        return Colors.yellow.shade100;
      case 'Happy':
        return Colors.orange.shade100;
      case 'Amazing':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildEmotionCard(String emotion, String percentage, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emotion,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              percentage,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
