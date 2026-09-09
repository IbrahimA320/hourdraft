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
    this.academicYear,
    this.approved,
  });

  final String id;
  String date;
  String category;
  double hours;
  String note;
  String? academicYear;
  bool? approved;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'category': category,
        'hours': hours,
        'note': note,
        'academicYear': academicYear,
        'approved': approved,
      };

  factory HourEntry.fromJson(Map<String, dynamic> json) => HourEntry(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        date: json['date'] as String? ?? _dateKey(DateTime.now()),
        category: json['category'] as String? ?? 'indoor',
        hours: (json['hours'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
        academicYear: json['academicYear'] as String?,
        approved: json['approved'] as bool?,
      );
}

class BlockedPeriod {
  BlockedPeriod({
    required this.id,
    required this.start,
    required this.end,
    required this.label,
  });

  final String id;
  String start;
  String end;
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
    required this.dailyLimits,
    required this.blockedPeriods,
    required this.blockedWeekday,
    required this.yearlyGoal,
    required this.academicYear,
    required this.themeMode,
    required this.onboardingDone,
  });

  static const _storageKey = 'hourdraft_state_v2';

  final List<HourEntry> entries;
  String languageCode;
  String name;
  Map<String, double> limits;
  Map<String, double> dailyLimits;

  List<BlockedPeriod> blockedPeriods;
  int? blockedWeekday;
  double yearlyGoal;
  String? academicYear;
  String themeMode;
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
        dailyLimits: {'indoor': 8, 'outdoor': 8, 'group': 8},
        blockedPeriods: <BlockedPeriod>[],
        blockedWeekday: null,
        yearlyGoal: 100,
         academicYear: 'year1',
        themeMode: 'system',
        onboardingDone: false,
      );
    }

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final rawEntries = data['entries'] as List<dynamic>? ?? [];
      final rawPeriods = data['blockedPeriods'] as List<dynamic>? ?? [];
      final selectedYear = _normalizeAcademicYear(
            data['academicYear'] as String?,
          ) ??
          'year1';
      final loadedEntries = rawEntries
          .whereType<Map<String, dynamic>>()
          .map(HourEntry.fromJson)
          .toList();
      // Entries created before year selection are kept in the first
      // available year instead of disappearing after the migration.
      for (final entry in loadedEntries) {
        entry.academicYear ??= selectedYear;
      }
      return HourDraftStore(
        entries: loadedEntries,
        languageCode: data['languageCode'] as String? ?? 'en',
        name: data['name'] as String? ?? 'Alex Student',
        limits: _readLimits(data['limits']),
        dailyLimits: _readDailyLimits(data['dailyLimits']),
        blockedPeriods: rawPeriods
            .whereType<Map<String, dynamic>>()
            .map(BlockedPeriod.fromJson)
            .toList(),
        blockedWeekday: data['blockedWeekday'] as int?,
        yearlyGoal: (data['yearlyGoal'] as num?)?.toDouble() ?? 100,
        academicYear: selectedYear,
        themeMode: data['themeMode'] as String? ?? 'system',
        onboardingDone: data['onboardingDone'] as bool? ?? false,
      );
    } catch (_) {
      return HourDraftStore(
        entries: <HourEntry>[],
        languageCode: 'en',
        name: 'Alex Student',
        limits: {'indoor': 20, 'outdoor': 20, 'group': 20},
        dailyLimits: {'indoor': 8, 'outdoor': 8, 'group': 8},
        blockedPeriods: <BlockedPeriod>[],
        blockedWeekday: null,
        yearlyGoal: 100,
         academicYear: 'year1',
        themeMode: 'system',
        onboardingDone: false,
      );
    }
  }

  double total({String? category, DateTime? from, DateTime? to}) {
    return entries
        .where((entry) =>
            _matchesSelectedYear(entry) &&
            (category == null || entry.category == category) &&
            _inRange(entry.date, from, to))
        .fold<double>(0, (sum, entry) => sum + entry.hours);
  }

  double dailyTotal(String date, {String? category}) {
    return entries
        .where((entry) =>
            _matchesSelectedYear(entry) &&
            entry.date == date &&
            (category == null || entry.category == category))
        .fold<double>(0, (sum, entry) => sum + entry.hours);
  }

  int loggedDays({DateTime? from, DateTime? to}) => entries
      .where((entry) =>
          _matchesSelectedYear(entry) && _inRange(entry.date, from, to))
      .map((entry) => entry.date)
      .toSet()
      .length;

  List<HourEntry> forDate(String date) => entries
      .where((entry) =>
          _matchesSelectedYear(entry) && entry.date == date)
      .toList()
    ..sort((a, b) => b.id.compareTo(a.id));

  List<HourEntry> get sortedEntries => [...entries]
    ..removeWhere((entry) => !_matchesSelectedYear(entry))
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

  void updateDailyLimits(Map<String, double> values) {
    dailyLimits = values;
    _changed();
  }

  void setYearlyGoal(double value) {
    yearlyGoal = value;
    _changed();
  }

  void setAcademicYear(String value) {
    academicYear = _normalizeAcademicYear(value) ?? 'year1';
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

  String? blockedLabelFor(DateTime date) {
    final key = dateKey(date);
    for (final p in blockedPeriods) {
      if (p.start.isEmpty || p.end.isEmpty) continue;
      if (key.compareTo(p.start) >= 0 && key.compareTo(p.end) <= 0) return p.label;
    }
    if (blockedWeekday != null && date.weekday % 7 == blockedWeekday) {
      return null;
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
            'dailyLimits': dailyLimits,
            'blockedPeriods': blockedPeriods.map((p) => p.toJson()).toList(),
            'blockedWeekday': blockedWeekday,
            'yearlyGoal': yearlyGoal,
            'academicYear': academicYear,
            'themeMode': themeMode,
            'onboardingDone': onboardingDone,
          }),
        },
      );
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
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

  static Map<String, double> _readDailyLimits(dynamic value) {
    if (value is Map) {
      return {
        'indoor': (value['indoor'] as num?)?.toDouble() ?? 8,
        'outdoor': (value['outdoor'] as num?)?.toDouble() ?? 8,
        'group': (value['group'] as num?)?.toDouble() ?? 8,
      };
    }
    return {'indoor': 8, 'outdoor': 8, 'group': 8};
  }

  bool _matchesSelectedYear(HourEntry entry) {
    return entry.academicYear == (academicYear ?? 'year1');
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

String? _normalizeAcademicYear(String? value) {
  switch (value) {
    case 'year1':
    case 'year2':
    case 'year3':
      return value;
    default:
      return null;
  }
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';