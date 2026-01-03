import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';
import './journal_entry_screen.dart';

class JournalEntryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> entry;
  final int entryIndex;

  const JournalEntryDetailScreen({
    super.key,
    required this.entry,
    required this.entryIndex,
  });

  @override
  State<JournalEntryDetailScreen> createState() => _JournalEntryDetailScreenState();
}

class _JournalEntryDetailScreenState extends State<JournalEntryDetailScreen> {
  final HiveStorage _storage = HiveStorage();
  bool _isDeleting = false;

  Future<void> _deleteEntry() async {
    setState(() {
      _isDeleting = true;
    });

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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteJournalEntry(widget.entryIndex);
      if (mounted) {
        Navigator.pop(context, true); // Go back to HomeScreen with result
      }
    }

    if (mounted) {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _navigateToEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(
          existingEntry: widget.entry,
          existingIndex: widget.entryIndex,
        ),
      ),
    );
    
    // If entry was edited, pop back to HomeScreen
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => Navigator.pop(context),
  ),
  title: Text(
    _formatDisplayDate(widget.entry['date']),
    style: const TextStyle(fontWeight: FontWeight.w600),
  ),
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  elevation: 0.5,
),

      body: _isDeleting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting entry...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Mood
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDisplayDate(widget.entry['date']),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple,
                          ),
                        ),
                        if (widget.entry['mood'] != null)
                          Chip(
                            backgroundColor: _getMoodColor(widget.entry['mood']).withValues(alpha:0.2),
                            label: Text(
                              _getMoodEmoji(widget.entry['mood']),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tags (if any)
                    if (widget.entry['tags'] != null && (widget.entry['tags'] as List).isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: (widget.entry['tags'] as List).map<Widget>((tag) {
                              return Chip(
                                label: Text(
                                  tag.toString(),
                                  style: TextStyle(
                                    color: Colors.purple.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: Colors.purple.shade50,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Content
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.entry['content'] ?? 'No content',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    

                    // Additional Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Entry Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created: ${_formatDateTime(widget.entry['createdAt'] ?? widget.entry['date'])}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (widget.entry['lastEdited'] != null)
                            Text(
                              'Last edited: ${_formatDateTime(widget.entry['lastEdited'])}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          Text(
                            'Word count: ${_countWords(widget.entry['content'])}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Character count: ${widget.entry['content']?.length ?? 0}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      // Floating Action Button for Edit
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEditScreen,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
      // Floating Action Button for Delete
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: ElevatedButton.icon(
      onPressed: _isDeleting ? null : _deleteEntry,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: _isDeleting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_outline),
      label: const Text(
        'Delete Entry',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  ),
),

    );
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 0: return Colors.red; // Very sad
      case 1: return Colors.orange; // Sad
      case 2: return Colors.yellow; // Okay
      case 3: return Colors.lightGreen; // Happy
      case 4: return Colors.green; // Amazing
      default: return Colors.grey;
    }
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 0: return '😭';
      case 1: return '😢';
      case 2: return '😐';
      case 3: return '😊';
      case 4: return '🤩';
      default: return '🤔';
    }
  }

 int _countWords(String? text) {
  if (text == null || text.isEmpty) return 0;
  return text.trim().split(RegExp(r'\s+')).length;
}


  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  String _formatDisplayDate(String dateString) {
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