import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HourEntry {
  HourEntry({
    required this.id,
    required this.date,
    required this.category,
    required this.hours,
    required this.note,
    this.approved,
  });

  final String id;
  String date;
  String category;
  double hours;
  String note;
  bool? approved;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'category': category,
        'hours': hours,
        'note': note,
        'approved': approved,
      };

  factory HourEntry.fromJson(Map<String, dynamic> json) => HourEntry(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        date: json['date'] as String? ?? _dateKey(DateTime.now()),
        category: json['category'] as String? ?? 'indoor',
        hours: (json['hours'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
        approved: json['approved'] as bool?,
      );
}

/// A date range the student is not allowed to log volunteer hours in
/// (e.g. school exam week, a family trip, a program blackout period).
class BlockedPeriod {
  BlockedPeriod({
    required this.id,
    required this.start,
    required this.end,
    required this.label,
  });

  final String id;
  String start; // yyyy-MM-dd, inclusive
  String end; // yyyy-MM-dd, inclusive
  String label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start,
        'end': end,
        'label': label,
      };

  factory BlockedPeriod.fromJson(Map<String, dynamic> json) => BlockedPeriod(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        start: json['start'] as String? ?? '',
        end: json['end'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class HourDraftStore extends ChangeNotifier {
  HourDraftStore({
    required this.entries,
    required this.languageCode,
    required this.name,
    required this.limits,
    required this.blockedPeriods,
    required this.blockedWeekday,
    required this.yearlyGoal,
    required this.themeMode,
    required this.onboardingDone,
  });

  static const _storageKey = 'hourdraft_state_v1';

  final List<HourEntry> entries;
  String languageCode;
  String name;
  Map<String, double> limits;

  /// Explicit date ranges the student cannot log hours in.
  List<BlockedPeriod> blockedPeriods;

  /// A weekday (0 = Sunday ... 6 = Saturday) that repeats every month the
  /// student is unavailable, or null if not set.
  int? blockedWeekday;

  /// Yearly hour goal, independent of the weekly per-category limits.
  double yearlyGoal;

  /// 'system' | 'light' | 'dark'
  String themeMode;

  /// Whether the 3-screen intro has already been shown once.
  bool onboardingDone;

  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<HourDraftStore> load() async {
    final raw = await _readStoredValue();
    if (raw == null || raw.isEmpty) {
      return HourDraftStore(
        entries: <HourEntry>[],
        languageCode: 'en',
        name: 'Alex Student',
        limits: {'indoor': 20, 'outdoor': 20, 'group': 20},
        blockedPeriods: <BlockedPeriod>[],
        blockedWeekday: null,
        yearlyGoal: 100,
        themeMode: 'system',
        onboardingDone: false,
      );
    }

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final rawEntries = data['entries'] as List<dynamic>? ?? [];
      final rawPeriods = data['blockedPeriods'] as List<dynamic>? ?? [];
      return HourDraftStore(
        entries: rawEntries
            .whereType<Map<String, dynamic>>()
            .map(HourEntry.fromJson)
            .toList(),
        languageCode: data['languageCode'] as String? ?? 'en',
        name: data['name'] as String? ?? 'Alex Student',
        limits: _readLimits(data['limits']),
        blockedPeriods: rawPeriods
            .whereType<Map<String, dynamic>>()
            .map(BlockedPeriod.fromJson)
            .toList(),
        blockedWeekday: data['blockedWeekday'] as int?,
        yearlyGoal: (data['yearlyGoal'] as num?)?.toDouble() ?? 100,
        themeMode: data['themeMode'] as String? ?? 'system',
        onboardingDone: data['onboardingDone'] as bool? ?? false,
      );
    } catch (_) {
      return HourDraftStore(
        entries: <HourEntry>[],
        languageCode: 'en',
        name: 'Alex Student',
        limits: {'indoor': 20, 'outdoor': 20, 'group': 20},
        blockedPeriods: <BlockedPeriod>[],
        blockedWeekday: null,
        yearlyGoal: 100,
        themeMode: 'system',
        onboardingDone: false,
      );
    }
  }

  double total({String? category, DateTime? from, DateTime? to}) {
    return entries
        .where((entry) =>
            (category == null || entry.category == category) &&
            _inRange(entry.date, from, to))
        .fold<double>(0, (sum, entry) => sum + entry.hours);
  }

  int loggedDays({DateTime? from, DateTime? to}) => entries
      .where((entry) => _inRange(entry.date, from, to))
      .map((entry) => entry.date)
      .toSet()
      .length;

  List<HourEntry> forDate(String date) => entries
      .where((entry) => entry.date == date)
      .toList()
    ..sort((a, b) => b.id.compareTo(a.id));

  List<HourEntry> get sortedEntries => [...entries]
    ..sort((a, b) => b.date.compareTo(a.date));

  void add(HourEntry entry) {
    entries.add(entry);
    _changed();
  }

  void update(HourEntry entry) {
    final index = entries.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      add(entry);
      return;
    }
    entries[index] = entry;
    _changed();
  }

  void remove(String id) {
    entries.removeWhere((entry) => entry.id == id);
    _changed();
  }

  void setLanguage(String value) {
    languageCode = value;
    _changed();
  }

  void updateProfile({required String newName}) {
    name = newName.trim().isEmpty ? name : newName.trim();
    _changed();
  }

  void updateLimits(Map<String, double> values) {
    limits = values;
    _changed();
  }

  void setYearlyGoal(double value) {
    yearlyGoal = value;
    _changed();
  }

  void setThemeMode(String value) {
    themeMode = value;
    _changed();
  }

  void completeOnboarding() {
    onboardingDone = true;
    _changed();
  }

  void addBlockedPeriod(BlockedPeriod period) {
    blockedPeriods.add(period);
    _changed();
  }

  void removeBlockedPeriod(String id) {
    blockedPeriods.removeWhere((p) => p.id == id);
    _changed();
  }

  void setBlockedWeekday(int? value) {
    blockedWeekday = value;
    _changed();
  }

  /// True if the student is not allowed to log hours on [date] — either
  /// because it falls inside a named blocked period, or it matches the
  /// recurring blocked weekday.
  bool isDateBlocked(DateTime date) {
    final key = dateKey(date);
    for (final p in blockedPeriods) {
      if (p.start.isEmpty || p.end.isEmpty) continue;
      if (key.compareTo(p.start) >= 0 && key.compareTo(p.end) <= 0) return true;
    }
    if (blockedWeekday != null && date.weekday % 7 == blockedWeekday) {
      return true;
    }
    return false;
  }

  /// Returns a human label for why [date] is blocked, or null if it isn't.
  String? blockedLabelFor(DateTime date) {
    final key = dateKey(date);
    for (final p in blockedPeriods) {
      if (p.start.isEmpty || p.end.isEmpty) continue;
      if (key.compareTo(p.start) >= 0 && key.compareTo(p.end) <= 0) return p.label;
    }
    if (blockedWeekday != null && date.weekday % 7 == blockedWeekday) {
      return null; // caller can fall back to a generic "recurring" message
    }
    return null;
  }

  void clearAll() {
    entries.clear();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      await _storageChannel.invokeMethod<void>(
        'set',
        <String, dynamic>{
          'key': _storageKey,
          'value': jsonEncode({
            'entries': entries.map((entry) => entry.toJson()).toList(),
            'languageCode': languageCode,
            'name': name,
            'limits': limits,
            'blockedPeriods': blockedPeriods.map((p) => p.toJson()).toList(),
            'blockedWeekday': blockedWeekday,
            'yearlyGoal': yearlyGoal,
            'themeMode': themeMode,
            'onboardingDone': onboardingDone,
          }),
        },
      );
    } on PlatformException {
      // The app remains usable if it is temporarily running on a target
      // without the native storage handler, such as a preview shell.
    } on MissingPluginException {
      // See the platform setup instructions for iOS and Android.
    }
  }

  static const MethodChannel _storageChannel =
      MethodChannel('hourdraft/storage');

  static Future<String?> _readStoredValue() async {
    try {
      return await _storageChannel.invokeMethod<String>(
        'get',
        <String, dynamic>{'key': _storageKey},
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Map<String, double> _readLimits(dynamic value) {
    if (value is Map) {
      return {
        'indoor': (value['indoor'] as num?)?.toDouble() ?? 20,
        'outdoor': (value['outdoor'] as num?)?.toDouble() ?? 20,
        'group': (value['group'] as num?)?.toDouble() ?? 20,
      };
    }
    return {'indoor': 20, 'outdoor': 20, 'group': 20};
  }
}

bool _inRange(String date, DateTime? from, DateTime? to) {
  final value = DateTime.tryParse(date);
  if (value == null) return false;
  final day = DateTime(value.year, value.month, value.day);
  if (from != null && day.isBefore(DateTime(from.year, from.month, from.day))) {
    return false;
  }
  if (to != null && day.isAfter(DateTime(to.year, to.month, to.day))) {
    return false;
  }
  return true;
}

String dateKey(DateTime date) => _dateKey(date);

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';