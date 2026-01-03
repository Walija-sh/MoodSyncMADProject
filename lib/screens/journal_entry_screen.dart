import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';

class JournalEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? existingEntry;
  final int? existingIndex;

  const JournalEntryScreen({
    super.key,
    this.existingEntry,
    this.existingIndex,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  int _selectedMood = 2;
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
  late List<bool> _selectedTags;
  final TextEditingController _textController = TextEditingController();
  final HiveStorage _storage = HiveStorage();
  bool _isSaving = false;
  bool _isEditing = false;
  double _textFieldHeight = 200; // Initial height
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedTags = List<bool>.filled(_tags.length, false);
    _initializeStorage();
    _loadExistingEntry();
    
    // Listen for content changes to adjust height
    _textController.addListener(_adjustTextFieldHeight);
    _textFocusNode.addListener(_scrollToTextField);
  }

  void _loadExistingEntry() {
    if (widget.existingEntry != null) {
      _isEditing = true;
      _textController.text = widget.existingEntry!['content'] ?? '';
      
      // Set mood
      if (widget.existingEntry!['mood'] != null) {
        _selectedMood = widget.existingEntry!['mood'];
      }
      
      // Set tags
      if (widget.existingEntry!['tags'] != null) {
        final List<dynamic> existingTags = widget.existingEntry!['tags'];
        for (int i = 0; i < _tags.length; i++) {
          _selectedTags[i] = existingTags.contains(_tags[i]);
        }
      }
      
      // Adjust height for existing content
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _adjustTextFieldHeight();
      });
    }
  }

  void _adjustTextFieldHeight() {
    // Calculate required height based on text content
    final text = _textController.text;
    final lineCount = text.split('\n').length;
    final characterCount = text.length;
    
    // Calculate approximate lines needed
    final approximateLines = (characterCount / 40).ceil(); // ~40 chars per line
    final totalLines = lineCount + approximateLines;
    
    // Set height based on lines (min 200, max 600)
    final newHeight = (totalLines * 24.0).clamp(200.0, 600.0);
    
    if (newHeight != _textFieldHeight) {
      setState(() {
        _textFieldHeight = newHeight;
      });
    }
  }

  void _scrollToTextField() {
    if (_textFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
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
      'id': _isEditing && widget.existingEntry != null
          ? widget.existingEntry!['id']
          : DateTime.now().millisecondsSinceEpoch.toString(),
      'date': _isEditing && widget.existingEntry != null
          ? widget.existingEntry!['date']
          : _getDateForStorage(),
      'mood': _selectedMood,
      'content': _textController.text,
      'tags': [
        for (int i = 0; i < _tags.length; i++)
          if (_selectedTags[i]) _tags[i]
      ],
      'createdAt': _isEditing && widget.existingEntry != null
          ? widget.existingEntry!['createdAt']
          : DateTime.now().toIso8601String(),
      'lastEdited': DateTime.now().toIso8601String(),
    };

    bool success = false;
    try {
      if (_isEditing && widget.existingIndex != null) {
        await _storage.updateJournalEntry(widget.existingIndex!, entry);
      } else {
        await _storage.saveJournalEntry(entry);
      }
      success = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Journal entry updated!' : 'Journal entry saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Pop with result to indicate success
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteEntry() async {
    if (!_isEditing || widget.existingIndex == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this journal entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.existingIndex != null) {
      await _storage.deleteJournalEntry(widget.existingIndex!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry deleted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Pop with result
      }
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_adjustTextFieldHeight);
    _textFocusNode.removeListener(_scrollToTextField);
    _textController.dispose();
    _textFocusNode.dispose();
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
        title: Text(
          _isEditing ? 'Edit Journal Entry' : 'New Journal Entry',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteEntry,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              _isEditing && widget.existingEntry != null
                  ? _formatExistingDate(widget.existingEntry!['date'])
                  : _getFormattedDate(),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoodButton(0, '😭', 'Very sad'),
                  const SizedBox(width: 8),
                  _buildMoodButton(1, '😢', 'Sad'),
                  const SizedBox(width: 8),
                  _buildMoodButton(2, '😐', 'Okay'),
                  const SizedBox(width: 8),
                  _buildMoodButton(3, '😊', 'Happy'),
                  const SizedBox(width: 8),
                  _buildMoodButton(4, '🤩', 'Amazing'),
                ],
              ),
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
              constraints: BoxConstraints(
                minHeight: 200,
                maxHeight: _textFieldHeight,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _textFocusNode,
                maxLines: null, // Unlimited lines
                expands: true,   // Expands to fill container
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Start writing your thoughts here...\n\nTip: Press Enter for new lines',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5, // Line spacing
                ),
              ),
            ),
            
            // Word count
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_textController.text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length} words',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
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

            // Save/Update button
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
                    : Text(
                        _isEditing ? 'Update Entry' : 'Save Entry',
                        style: const TextStyle(
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

  String _formatExistingDate(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        
        final date = DateTime(year, month, day);
        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        
        return '${days[date.weekday - 1]}, ${months[month - 1]} $day, $year';
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }
}