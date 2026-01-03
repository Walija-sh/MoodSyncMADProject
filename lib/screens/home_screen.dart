import 'package:flutter/material.dart';
import 'package:intro/screens/main_app.dart';
import './journal_entry_screen.dart';
import '../storage/hive_storage.dart';
import './journal_entry_detail_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveStorage _storage = HiveStorage();
  String _username = 'User';
  int _streak = 0;
  int _entriesCount = 0;
  List<Map<String, dynamic>> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await _storage.init();
    _loadData();
  }

  Future<void> _loadData() async {
    final entries = _storage.getJournalEntries();

    setState(() {
      _entriesCount = entries.length;
      _allEntries = entries.reversed.toList(); // All entries, latest first
      _streak = _calculateStreak(entries);
      _username = _storage.getUsername();
    });
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

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  int _getOriginalIndex(int displayedIndex) {
    // Since entries are displayed in reverse order (newest first)
    // we need to convert displayed index to original index
    return _allEntries.length - 1 - displayedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
  title: 'Hi $_username',
  subtitle: _getFormattedDate(),
  extraHeight: 150,
  child: GestureDetector(
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const JournalEntryScreen(),
        ),
      );

      if (result == true) {
        _loadData();
      }
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tap to log your mood',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track your daily emotion',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    ),
  ),
),

      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressCard(
                      icon: Icons.local_fire_department,
                      title: 'Streak',
                      value: '$_streak days',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProgressCard(
                      icon: Icons.book,
                      title: 'Entries',
                      value: '$_entriesCount Entries',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Entries',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$_entriesCount total',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_allEntries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No journal entries yet.\nStart by adding your first entry!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                ..._allEntries.asMap().entries.map((entryMap) {
                  final index = entryMap.key;
                  final entry = entryMap.value;
                  final date = entry['date'] ?? '';
                  final content = entry['content'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JournalEntryDetailScreen(
                              entry: entry,
                              entryIndex: _getOriginalIndex(index),
                            ),
                          ),
                        );
                        
                        // Reload data if entry was deleted or edited
                        if (result == true) {
                          _loadData();
                        }
                      },
                      child: _buildJournalEntry(
                        date: date,
                        content: content,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntry({
    required String date,
    required String content,
  }) {
    final safeContent = content.isEmpty ? 'No content' : content;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDisplayDate(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  safeContent.length > 100 ? '${safeContent.substring(0, 100)}...' : safeContent,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        
        return '${months[month - 1]} $day, $year';
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }
}