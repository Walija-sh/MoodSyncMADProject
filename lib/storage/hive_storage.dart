import 'package:hive/hive.dart';

class HiveStorage {
  static final HiveStorage _instance = HiveStorage._internal();
  factory HiveStorage() => _instance;
  HiveStorage._internal();

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox('app_storage');
  }

  // =====================
  // KEYS
  // =====================
  static const _pinKey = 'user_pin';
  static const _isPinSetKey = 'is_pin_set';
  static const _usernameKey = 'username';
  static const _onboardingKey = 'onboarding_completed';
  static const _journalEntriesKey = 'journal_entries';
  static const _streakKey = 'streak';
  static const _lastEntryDateKey = 'last_entry_date';

  // =====================
  // PIN
  // =====================
  Future<void> setPIN(String pin) async {
    await _box.put(_pinKey, pin);
    await _box.put(_isPinSetKey, true);
  }

  String? getPIN() => _box.get(_pinKey);

  bool isPINSet() => _box.get(_isPinSetKey, defaultValue: false);

  Future<void> clearPIN() async {
    await _box.delete(_pinKey);
    await _box.delete(_isPinSetKey);
  }

  // =====================
  // USER
  // =====================
  Future<void> setUsername(String name) async {
    await _box.put(_usernameKey, name);
  }

  String getUsername() {
    return _box.get(_usernameKey, defaultValue: 'User');
  }

  // =====================
  // ONBOARDING
  // =====================
  Future<void> setOnboardingCompleted(bool value) async {
    await _box.put(_onboardingKey, value);
  }

  bool getOnboardingCompleted() {
    return _box.get(_onboardingKey, defaultValue: false);
  }

  bool isFirstLaunch() {
    return !getOnboardingCompleted() || !isPINSet();
  }

  // =====================
  // JOURNAL
  // =====================
 List<Map<String, dynamic>> getJournalEntries() {
  final list = _box.get(_journalEntriesKey, defaultValue: []);
  return List<Map<String, dynamic>>.from(
    (list as List).map(
      (e) => Map<String, dynamic>.from(e as Map)
    )
  );
}


  Future<void> saveJournalEntry(Map<String, dynamic> entry) async {
    final entries = getJournalEntries();
    entries.add(entry);
    await _box.put(_journalEntriesKey, entries);
  }

  Future<void> deleteJournalEntry(int index) async {
    final entries = getJournalEntries();
    if (index >= 0 && index < entries.length) {
      entries.removeAt(index);
      await _box.put(_journalEntriesKey, entries);
    }
  }
  
Future<void> updateJournalEntry(int index, Map<String, dynamic> newEntry) async {
  final entries = getJournalEntries();
  if (index >= 0 && index < entries.length) {
    entries[index] = newEntry;
    await _box.put(_journalEntriesKey, entries);
  }
}

  int getTotalEntries() => getJournalEntries().length;

  double getAverageMood() {
    final entries = getJournalEntries();
    if (entries.isEmpty) return 0.0;
    final sum = entries.fold<double>(
      0,
      (prev, e) => prev + (e['mood'] as int).toDouble(),
    );
    return sum / entries.length;
  }

  // =====================
  // STREAK
  // =====================
  int getStreak() => _box.get(_streakKey, defaultValue: 0);

  Future<void> _setStreak(int value) async {
    await _box.put(_streakKey, value);
  }

  String? getLastEntryDate() => _box.get(_lastEntryDateKey);

  Future<void> _setLastEntryDate(String date) async {
    await _box.put(_lastEntryDateKey, date);
  }

  Future<void> updateStreak(String currentDate) async {
    final lastDateStr = getLastEntryDate();

    if (lastDateStr == null) {
      await _setStreak(1);
    } else {
      final last = DateTime.parse(lastDateStr);
      final current = DateTime.parse(currentDate);
      final diff = current.difference(last).inDays;

      if (diff == 1) {
        await _setStreak(getStreak() + 1);
      } else if (diff > 1) {
        await _setStreak(1);
      }
    }

    await _setLastEntryDate(currentDate);
  }

  // =====================
  // CLEAR
  // =====================
  Future<void> clearAllUserData() async {
    await _box.deleteAll([
      _pinKey,
      _isPinSetKey,
      _usernameKey,
      _onboardingKey,
      _journalEntriesKey,
      _streakKey,
      _lastEntryDateKey,
    ]);
  }
}
