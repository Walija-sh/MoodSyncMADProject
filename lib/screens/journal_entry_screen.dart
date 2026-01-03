import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  int _selectedMood = 2; // Default to "Okay"
  final List<String> _tags = [
    'stress',
    'excitement',
    'calm',
    'tired',
    'productive',
    'anxious',
    'motivated',
    'grateful'
  ];
  late List<bool> _selectedTags; // dynamically initialized
  final TextEditingController _textController = TextEditingController();
  final HiveStorage _storage = HiveStorage();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTags = List<bool>.filled(_tags.length, false);
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await _storage.init();
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

  String _getDateForStorage() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveEntry() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something in your journal entry'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': _getDateForStorage(),
      'mood': _selectedMood,
      'content': _textController.text,
      'tags': [
        for (int i = 0; i < _tags.length; i++)
          if (_selectedTags[i]) _tags[i]
      ],
    };

    await _storage.saveJournalEntry(entry);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Journal Entry',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              _getFormattedDate(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Mood selection
            const Text(
              'How are you feeling?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMoodButton(0, '😭', 'Very sad'),
                _buildMoodButton(1, '😢', 'Sad'),
                _buildMoodButton(2, '😐', 'Okay'),
                _buildMoodButton(3, '😊', 'Happy'),
                _buildMoodButton(4, '🤩', 'Amazing'),
              ],
            ),
            const SizedBox(height: 32),

            // Journal text input
            const Text(
              'Write what\'s on your mind...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Start writing your thoughts here...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),

            // Tags
            const Text(
              'Add tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                _tags.length,
                (index) => FilterChip(
                  selected: _selectedTags[index],
                  showCheckmark: false,
                  label: Text(_tags[index]),
                  onSelected: (selected) {
                    setState(() {
                      _selectedTags[index] = selected;
                    });
                  },
                  selectedColor: Colors.purple.shade100,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: _selectedTags[index] ? Colors.purple : Colors.black87,
                    fontWeight: _selectedTags[index] ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodButton(int index, String emoji, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = index;
        });
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _selectedMood == index ? Colors.purple.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
              border: _selectedMood == index ? Border.all(color: Colors.purple, width: 2) : null,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _selectedMood == index ? Colors.purple : Colors.grey.shade600,
              fontWeight: _selectedMood == index ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
