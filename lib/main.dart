import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import 'app_state.dart';
import 'native_launcher.dart';
import 'theme.dart';
import 'screens/onboarding_welcome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await HourDraftStore.load();
  runApp(HourDraftApp(store: store));
}

class HourDraftApp extends StatefulWidget {
  const HourDraftApp({required this.store, super.key});

  final HourDraftStore store;

  @override
  State<HourDraftApp> createState() => _HourDraftAppState();
}

class _HourDraftAppState extends State<HourDraftApp> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    widget.store.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // Resolve light/dark once per build and stamp it onto AppColors before
    // any AppColors.* getter is read further down the tree.
    final platformBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    final isDark = switch (widget.store.themeMode) {
      'dark' => true,
      'light' => false,
      _ => platformBrightness == Brightness.dark,
    };
    AppTheme.applyBrightness(isDark);

    final locale = Locale(widget.store.languageCode);
    return MaterialApp(
      title: 'HourDraft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: widget.store.languageCode == 'en'
            ? TextDirection.ltr
            : TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      // First launch (or right after a "reset") shows the 3-screen intro.
      // Once OnboardingPrivacyScreen's Continue button is tapped it calls
      // store.completeOnboarding(), which flips this for good.
      home: widget.store.onboardingDone
          ? RootShell(store: widget.store)
          : OnboardingWelcomeScreen(store: widget.store),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({required this.store, super.key});

  final HourDraftStore store;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  HourDraftStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    store.addListener(_refresh);
  }

  @override
  void dispose() {
    store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = [l10n.tr('appName'), l10n.tr('historyTitle'), l10n.tr('approvalTitle')];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: l10n.tr('settings'),
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (_tab == 0)
            IconButton(
              tooltip: l10n.tr('today'),
              icon: const Icon(Icons.today_outlined),
              onPressed: () => _jumpToToday(),
            ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            HomeView(store: store, onOpenEntry: _openEditor),
            HistoryView(store: store, onOpenEntry: _openEditor),
            ApprovalView(store: store, onOpenEntry: _openEditor),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (value) => setState(() => _tab = value),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: l10n.tr('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.fact_check_outlined),
            activeIcon: const Icon(Icons.fact_check),
            label: l10n.tr('approval'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        tooltip: l10n.tr('logHours'),
        onPressed: () => _openEditor(date: dateKey(DateTime.now())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: AppColors.accentLight,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      _initials(store.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.tr(
                            'hoursLogged',
                            {'hours': _formatHours(store.total())},
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(
                    context,
                    Icons.person_outline,
                    l10n.tr('profile'),
                    () => _openPage(ProfilePage(store: store)),
                  ),
                  _drawerItem(
                    context,
                    Icons.tune,
                     l10n.tr('settings'),
                     () => _openPage(LimitsPage(store: store)),
                  ),
                  _drawerItem(
                    context,
                    Icons.bar_chart_rounded,
                    l10n.tr('analytics'),
                    () => _openPage(AnalyticsPage(store: store)),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                    child: Text(
                      l10n.tr('language'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  _languageTile(context, 'en', l10n.tr('languageEnglish')),
                  _languageTile(context, 'ar', l10n.tr('languageArabic')),
                  _languageTile(context, 'he', l10n.tr('languageHebrew')),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                    child: Text(
                      l10n.tr('appearance'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  _themeTile(context, 'system', l10n.tr('themeSystem'), Icons.brightness_auto),
                  _themeTile(context, 'light', l10n.tr('themeLight'), Icons.light_mode_outlined),
                  _themeTile(context, 'dark', l10n.tr('themeDark'), Icons.dark_mode_outlined),
                  const Divider(),
                  _drawerItem(
                    context,
                    Icons.shield_outlined,
                    l10n.tr('privacy'),
                    () => _openPage(const InfoPage(kind: 'privacy')),
                  ),
                  _drawerItem(
                    context,
                    Icons.star_outline,
                    l10n.tr('feedback'),
                    () => _openPage(const FeedbackPage()),
                  ),
                  _drawerItem(
                    context,
                    Icons.info_outline,
                    l10n.tr('about'),
                    () => _openPage(const InfoPage(kind: 'about')),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '''HourDraft 1.0.0
                © 2026 Ibrahim Alayan. All Rights Reserved.''',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, size: 21, color: AppColors.text),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _languageTile(BuildContext context, String code, String label) {
    final selected = store.languageCode == code;
    return ListTile(
      dense: true,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.accent : AppColors.textMuted,
        size: 20,
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () {
        store.setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  Widget _themeTile(BuildContext context, String mode, String label, IconData icon) {
    final selected = store.themeMode == mode;
    return ListTile(
      dense: true,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.accent : AppColors.textMuted,
        size: 20,
      ),
      title: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
      onTap: () {
        store.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  void _jumpToToday() {
    setState(() => _tab = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).tr('today'))),
    );
  }

  Future<void> _openEditor({required String date, HourEntry? entry}) async {
    final l10n = AppLocalizations.of(context);
    final targetDate = DateTime.tryParse(entry?.date ?? date);
    if (targetDate != null && store.isDateBlocked(targetDate) && entry == null) {
      _showBlockedDialog(context);
      return;
    }
    final result = await showModalBottomSheet<HourEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EntryEditorSheet(date: date, initial: entry, store: store),
    );
    if (!mounted || result == null) return;
    if (entry == null) {
      store.add(result);
    } else {
      store.update(result);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.tr('entrySaved'))),
    );
  }
}

void _showBlockedDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.block, color: AppColors.danger),
      title: Text(l10n.tr('dateBlockedTitle')),
      content: Text(l10n.tr('dateBlockedMessage')),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.tr('ok')),
        ),
      ],
    ),
  );
}

Future<bool> confirmDeleteEntry(
  BuildContext context,
  HourDraftStore store,
  HourEntry entry,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.tr('deleteQuestion')),
      content: Text(l10n.tr('deleteHint')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.tr('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.tr('delete')),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    store.remove(entry.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('entryDeleted'))),
      );
    }
    return true;
  }
  return false;
}

class HomeView extends StatefulWidget {
  const HomeView({required this.store, required this.onOpenEntry, super.key});

  final HourDraftStore store;
  final Future<void> Function({required String date, HourEntry? entry})
      onOpenEntry;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late DateTime _month;

  HourDraftStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    store.addListener(_refresh);
  }

  @override
  void dispose() {
    store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final weekStart = _monday(now);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weeklyTotal = store.total(from: weekStart, to: weekEnd);
    final weeklyLimit =
        store.limits.values.fold<double>(0, (sum, value) => sum + value);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.tr('today')} · ${_prettyDate(now, l10n)}',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _metricCard(
                  l10n.tr('weeklyLimits'),
                  '${_formatHours(weeklyTotal)}/${_formatHours(weeklyLimit)}h',
                  _weekOverLimit(weekStart, weekEnd)
                      ? AppColors.danger
                      : AppColors.accent,
                  _weekOverLimit(weekStart, weekEnd)
                      ? AppColors.danger.withOpacity(.08)
                      : AppColors.accentLight,
                  progress: _progress(weeklyTotal, weeklyLimit),
                ),
                _metricCard(
                  l10n.tr('indoor'),
                  l10n.tr(
                    'hoursLeft',
                    {'hours': _formatHours(_remaining('indoor', weekStart, weekEnd))},
                  ),
                  AppColors.indoor,
                  AppColors.indoorLight,
                ),
                _metricCard(
                  l10n.tr('outdoor'),
                  l10n.tr(
                    'hoursLeft',
                    {'hours': _formatHours(_remaining('outdoor', weekStart, weekEnd))},
                  ),
                  AppColors.outdoor,
                  AppColors.outdoorLight,
                ),
                _metricCard(
                  l10n.tr('group'),
                  l10n.tr(
                    'hoursLeft',
                    {'hours': _formatHours(_remaining('group', weekStart, weekEnd))},
                  ),
                  AppColors.group,
                  AppColors.groupLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _calendar(context),
          const SizedBox(height: 22),
          _weekSummary(context, weekStart, weekEnd, weeklyTotal),
          const SizedBox(height: 22),
          _recentLogs(context),
        ],
      ),
    );
  }

  double _remaining(String category, DateTime from, DateTime to) {
    final value = (store.limits[category] ?? 20) -
        store.total(category: category, from: from, to: to);
    return value < 0 ? 0 : value;
  }

  bool _weekOverLimit(DateTime from, DateTime to) {
    return ['indoor', 'outdoor', 'group'].any(
      (category) => store.total(category: category, from: from, to: to) >
          (store.limits[category] ?? 20),
    );
  }

  bool _dateWeekOverLimit(DateTime date) {
    final from = _monday(date);
    return _weekOverLimit(from, from.add(const Duration(days: 6)));
  }

  double _progress(double value, double goal) =>
      goal <= 0 ? 0.0 : (value / goal).clamp(0, 1).toDouble();

  Widget _metricCard(
    String label,
    String value,
    Color color,
    Color lightColor, {
    double? progress,
  }) {
    return Container(
      width: 138,
      margin: const EdgeInsetsDirectional.only(end: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
          const Spacer(),
          if (progress != null)
            Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: color,
                    backgroundColor: lightColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _calendar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final year = _month.year;
    final month = _month.month;
    final firstDay = DateTime(year, month, 1).weekday % 7;
    final days = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                    () => _month = DateTime(year, month - 1),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${l10n.month(month)} $year',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                    () => _month = DateTime(year, month + 1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            child: Row(
              children: l10n.weekdays
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 61,
              ),
              itemCount: firstDay + days,
              itemBuilder: (context, index) {
                if (index < firstDay) return const SizedBox.shrink();
                final day = index - firstDay + 1;
                final date = DateTime(year, month, day);
                final key = dateKey(date);
                final entries = store.forDate(key);
                final total = entries.fold(0.0, (sum, item) => sum + item.hours);
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isBlocked = store.isDateBlocked(date);
                final isWeekOverLimit = _dateWeekOverLimit(date);
                return InkWell(
                  onTap: () {
                    if (isBlocked) {
                      _showBlockedDialog(context);
                      return;
                    }
                    _openDay(context, date, entries);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: isBlocked
                          ? AppColors.blocked
                          : isWeekOverLimit
                              ? AppColors.danger.withOpacity(.24)
                              : isToday
                                  ? AppColors.accentLight
                                  : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isWeekOverLimit
                            ? AppColors.danger
                            : isToday
                                ? AppColors.accent
                                : Colors.transparent,
                        width: isWeekOverLimit ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isWeekOverLimit || isToday || total > 0
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isBlocked
                                ? AppColors.blockedText
                                : isWeekOverLimit
                                    ? AppColors.danger
                                    : isToday
                                        ? AppColors.accent
                                        : AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isBlocked)
                          Icon(Icons.block, size: 11, color: AppColors.blockedText)
                        else if (total > 0)
                          Text(
                            '${_formatHours(total)}h',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        if (!isBlocked && entries.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: entries
                                .take(3)
                                .map(
                                  (entry) => Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: categoryColor(entry.category),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDay(
  BuildContext context,
  DateTime date,
  List<HourEntry> entries,
) {
  if (entries.isEmpty) {
    widget.onOpenEntry(date: dateKey(date));
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _prettyDate(date, AppLocalizations.of(context)),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CategoryIcon(category: entry.category),
                  title: Text(
                    '${_formatHours(entry.hours)}h · ${AppLocalizations.of(context).category(entry.category)}',
                  ),
                  subtitle: Text(entry.note.isEmpty
                      ? AppLocalizations.of(context).tr('noNote')
                      : entry.note),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.onOpenEntry(date: entry.date, entry: entry);
                  },
                  trailing: IconButton(
                    tooltip: AppLocalizations.of(context).tr('delete'),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await confirmDeleteEntry(context, store, entry);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    widget.onOpenEntry(date: dateKey(date));
                  },
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context).tr('addHours')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weekSummary(
    BuildContext context,
    DateTime from,
    DateTime to,
    double total,
  ) {
    final l10n = AppLocalizations.of(context);
    final overLimit = _weekOverLimit(from, to);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('thisWeek'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
         Card(
           color: overLimit ? AppColors.danger.withOpacity(.05) : null,
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: overLimit
                 ? BorderSide(color: AppColors.danger.withOpacity(.4))
                 : BorderSide.none,
           ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.tr(
                          'hoursLogged',
                          {'hours': _formatHours(total)},
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      l10n.tr(
                        'daysLogged',
                        {'days': '${store.loggedDays(from: from, to: to)}'},
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _summaryLine(context, 'indoor', from, to),
                const SizedBox(height: 10),
                _summaryLine(context, 'outdoor', from, to),
                const SizedBox(height: 10),
                _summaryLine(context, 'group', from, to),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryLine(
    BuildContext context,
    String category,
    DateTime from,
    DateTime to,
  ) {
    final l10n = AppLocalizations.of(context);
    final value = store.total(category: category, from: from, to: to);
    final max = store.limits[category] ?? 20;
    return Row(
      children: [
        CategoryIcon(category: category, compact: true),
        const SizedBox(width: 9),
        SizedBox(
          width: 62,
          child: Text(
            l10n.category(category),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress(value, max),
              minHeight: 7,
              color: categoryColor(category),
              backgroundColor: categoryLightColor(category),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          '${_formatHours(value)}h',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _recentLogs(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = store.sortedEntries.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('recentLogs'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.edit_calendar_outlined, color: AppColors.textMuted, size: 34),
                    const SizedBox(height: 10),
                    Text(
                      l10n.tr('noEntries'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tr('startLogging'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...items.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntryTile(
                entry: entry,
                onTap: () => widget.onOpenEntry(
                  date: entry.date,
                  entry: entry,
                ),
                onDelete: () => confirmDeleteEntry(context, store, entry),
              ),
            ),
          ),
      ],
    );
  }
}

class HistoryView extends StatelessWidget {
  const HistoryView({required this.store, required this.onOpenEntry, super.key});

  final HourDraftStore store;
  final Future<void> Function({required String date, HourEntry? entry})
      onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = store.sortedEntries;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Text(
          l10n.tr(
            'hoursLogged',
            {'hours': _formatHours(store.total())},
          ),
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          EmptyCard(
            icon: Icons.history,
            title: l10n.tr('historyEmpty'),
            hint: l10n.tr('historyEmptyHint'),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntryTile(
                entry: entry,
                onTap: () => onOpenEntry(date: entry.date, entry: entry),
                onDelete: () => confirmDeleteEntry(context, store, entry),
              ),
            ),
          ),
      ],
    );
  }
}

class ApprovalView extends StatelessWidget {
  const ApprovalView({required this.store, required this.onOpenEntry, super.key});

  final HourDraftStore store;
  final Future<void> Function({required String date, HourEntry? entry})
      onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = store.sortedEntries;
    final approved = entries.where((entry) => entry.approved == true).fold(
        0.0, (sum, entry) => sum + entry.hours);
    final pending = entries.where((entry) => entry.approved != true).fold(
        0.0, (sum, entry) => sum + entry.hours);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Row(
          children: [
            Expanded(
              child: _approvalStat(
                l10n.tr('approved'),
                '${_formatHours(approved)}h',
                AppColors.approved,
                AppColors.approvedLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _approvalStat(
                l10n.tr('pending'),
                '${_formatHours(pending)}h',
                AppColors.pending,
                AppColors.pendingLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (entries.isEmpty)
          EmptyCard(
            icon: Icons.fact_check_outlined,
            title: l10n.tr('approvalEmpty'),
            hint: l10n.tr('approvalEmptyHint'),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntryTile(
                entry: entry,
                onTap: () => onOpenEntry(date: entry.date, entry: entry),
                onDelete: () => confirmDeleteEntry(context, store, entry),
              ),
            ),
          ),
      ],
    );
  }

  Widget _approvalStat(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class EntryEditorSheet extends StatefulWidget {
  const EntryEditorSheet({
    required this.date,
    required this.store,
    this.initial,
    super.key,
  });

  final String date;
  final HourDraftStore store;
  final HourEntry? initial;

  @override
  State<EntryEditorSheet> createState() => _EntryEditorSheetState();
}

class _EntryEditorSheetState extends State<EntryEditorSheet> {
  late String _date;
  late String _category;
  late bool _approved;
  bool _showSuggestion = false;
  late TextEditingController _hoursController;
  late TextEditingController _noteController;
  String? _error;

  bool get isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _date = initial?.date ?? widget.date;
    _category = initial?.category ?? 'indoor';
    _approved = initial?.approved ?? false;
    _hoursController = TextEditingController(
      text: initial == null ? '' : _formatHours(initial.hours),
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.tr(isEditing ? 'editHours' : 'logHours'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.tr('date'),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 17),
                label: Text(_displayDate(_date, l10n)),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.tr('category'),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _categoryButton('indoor', AppColors.indoor, l10n),
                  const SizedBox(width: 8),
                  _categoryButton('outdoor', AppColors.outdoor, l10n),
                  const SizedBox(width: 8),
                  _categoryButton('group', AppColors.group, l10n),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.tr('showSuggestion'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l10n.tr('suggestionHint'),
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                value: _showSuggestion,
                onChanged: (value) {
                  setState(() => _showSuggestion = value);
                },
              ),
              if (_showSuggestion) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _suggestedTime(l10n),
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _hoursController,
                autofocus: !isEditing,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.tr('hours'),
                  hintText: '0.5',
                  suffixText: 'h',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.tr('note'),
                  hintText: l10n.tr('optionalNote'),
                  alignLabelWithHint: true,
                ),
              ),
              // Approval status now applies to every category, not just
              // group hours — the student decides when they log the entry.
              const SizedBox(height: 16),
              Text(
                l10n.tr('approvalStatus'),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _approvalButton(
                      approved: false,
                      label: l10n.tr('pending'),
                      icon: Icons.schedule_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _approvalButton(
                      approved: true,
                      label: l10n.tr('approved'),
                      icon: Icons.verified_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(l10n.tr('save')),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.tr('cancel')),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline, color: AppColors.danger),
                    label: Text(
                      l10n.tr('delete'),
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final entry = widget.initial;
    if (entry == null) return;
    final deleted = await confirmDeleteEntry(context, widget.store, entry);
    if (deleted && mounted) Navigator.pop(context);
  }

  Widget _categoryButton(
    String category,
    Color color,
    AppLocalizations l10n,
  ) {
    final selected = _category == category;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _category = category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : color.withOpacity(.2)),
          ),
          child: Text(
            l10n.category(category),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _approvalButton({
    required bool approved,
    required String label,
    required IconData icon,
  }) {
    final selected = _approved == approved;
    final color = approved ? AppColors.approved : AppColors.pending;
    return OutlinedButton.icon(
      onPressed: () => setState(() => _approved = approved),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : color,
        backgroundColor: selected ? color : Colors.transparent,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }

  String _suggestedTime(AppLocalizations l10n) {
    final otherEntries = widget.store
        .forDate(_date)
        .where((entry) => entry.id != widget.initial?.id)
        .toList();
    final hasAny = otherEntries.isNotEmpty;
    final start = hasAny ? 4 : 1;
    final end = hasAny ? 7 : 4;
    return l10n.tr(
      'suggestedTime',
      {'start': '$start', 'end': '$end'},
    );
  }

  Future<void> _pickDate() async {
    final parsed = DateTime.tryParse(_date) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      // Days the student marked unavailable simply can't be selected.
      selectableDayPredicate: (date) => !widget.store.isDateBlocked(date),
    );
    if (selected != null) setState(() => _date = dateKey(selected));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final parsedDate = DateTime.tryParse(_date);
    if (parsedDate != null && widget.store.isDateBlocked(parsedDate)) {
      _showBlockedDialog(context);
      return;
    }
    final hours = double.tryParse(_hoursController.text.trim().replaceAll(',', '.'));
    final isHalfHour = hours != null &&
        ((hours * 2).roundToDouble() - hours * 2).abs() < 0.0001;
    if (hours == null || hours < .5 || hours > 24) {
      setState(() => _error = l10n.tr('invalidHours'));
      return;
    }
    if (!isHalfHour) {
      setState(() => _error = l10n.tr('hoursMustBeHalf'));
      return;
    }
    final initial = widget.initial;
    final weekStart = _monday(parsedDate ?? DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 6));
    var weeklyTotal = widget.store.total(
      category: _category,
      from: weekStart,
      to: weekEnd,
    );
    var dailyTotal = widget.store.dailyTotal(_date, category: _category);
    if (initial != null && initial.category == _category) {
      final initialDate = DateTime.tryParse(initial.date);
      if (initialDate != null &&
          !initialDate.isBefore(weekStart) &&
          !initialDate.isAfter(weekEnd)) {
        weeklyTotal -= initial.hours;
      }
      if (initial.date == _date) dailyTotal -= initial.hours;
    }
    final weeklyOverage =
        weeklyTotal + hours - (widget.store.limits[_category] ?? 20);
    final dailyOverage =
        dailyTotal + hours - (widget.store.dailyLimits[_category] ?? 8);
    final warnings = <String>[];
    if (weeklyOverage > 0) {
      warnings.add(
        l10n.tr(
          'exceedsWeeklyLimit',
          {
            'category': l10n.category(_category),
            'hours': _formatHours(weeklyOverage),
          },
        ),
      );
    }
    if (dailyOverage > 0) {
      warnings.add(
        l10n.tr(
          'exceedsDailyLimit',
          {
            'category': l10n.category(_category),
            'hours': _formatHours(dailyOverage),
          },
        ),
      );
    }
    if (warnings.isNotEmpty) {
      final continueSaving = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.tr('limitWarningTitle')),
          content: Text(warnings.join('\n\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.tr('continueAnyway')),
            ),
          ],
        ),
      );
      if (continueSaving != true || !mounted) return;
    }
    Navigator.pop(
      context,
      HourEntry(
        id: initial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        date: _date,
        category: _category,
        hours: hours,
        note: _noteController.text.trim(),
        academicYear: initial?.academicYear ?? widget.store.academicYear ?? 'year1',
        approved: _approved,
      ),
    );
  }
}

class EntryTile extends StatelessWidget {
  const EntryTile({
    required this.entry,
    required this.onTap,
    this.onDelete,
    super.key,
  });

  final HourEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = categoryColor(entry.category);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              CategoryIcon(category: entry.category),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.category(entry.category),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_displayDate(entry.date, l10n)} · ${entry.note.isEmpty ? l10n.tr('noNote') : entry.note}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatHours(entry.hours)}h',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    entry.approved == true ? l10n.tr('approved') : l10n.tr('pending'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: entry.approved == true ? AppColors.approved : AppColors.pending,
                    ),
                  ),
                ],
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: l10n.tr('delete'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: Icon(Icons.chevron_right, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({required this.category, this.compact = false, super.key});

  final String category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      width: compact ? 23 : 38,
      height: compact ? 23 : 38,
      decoration: BoxDecoration(
        color: categoryLightColor(category),
        borderRadius: BorderRadius.circular(compact ? 7 : 10),
      ),
      child: Icon(
        category == 'indoor'
            ? Icons.home_work_outlined
            : category == 'outdoor'
                ? Icons.park_outlined
                : Icons.groups_outlined,
        size: compact ? 14 : 20,
        color: color,
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    required this.icon,
    required this.title,
    required this.hint,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.store, super.key});

  final HourDraftStore store;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _name.text = widget.store.name;
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      _initials(store.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _name,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(labelText: l10n.tr('name')),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        store.updateProfile(newName: _name.text);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.tr('saveProfile')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LimitsPage extends StatefulWidget {
  const LimitsPage({required this.store, super.key});

  final HourDraftStore store;

  @override
  State<LimitsPage> createState() => _LimitsPageState();
}

class _LimitsPageState extends State<LimitsPage> {
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, TextEditingController> _dailyControllers;
  late final TextEditingController _yearlyController;
  late String _academicYear;
  late bool _hasRecurringDay;
  late int? _recurringDay;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final category in ['indoor', 'outdoor', 'group'])
        category: TextEditingController(
          text: _formatHours(widget.store.limits[category] ?? 20),
        ),
    };
    _dailyControllers = {
      for (final category in ['indoor', 'outdoor', 'group'])
        category: TextEditingController(
          text: _formatHours(widget.store.dailyLimits[category] ?? 8),
        ),
    };
    _yearlyController = TextEditingController(
      text: _formatHours(widget.store.yearlyGoal),
    );
    _academicYear = widget.store.academicYear ?? 'year1';
    _recurringDay = widget.store.blockedWeekday;
    _hasRecurringDay = _recurringDay != null;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _dailyControllers.values) {
      controller.dispose();
    }
    _yearlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.tr('limitDescription'),
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr('weeklyLimits'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...['indoor', 'outdoor', 'group'].map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CategoryIcon(category: category),
                          const SizedBox(width: 12),
                          Text(
                            l10n.category(category),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('weeklyLimit'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _controllers[category],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [_decimalInputFormatter()],
                                  decoration: const InputDecoration(
                                    suffixText: 'h',
                                  ),
                              ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('dailyLimit'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _dailyControllers[category],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [_decimalInputFormatter()],
                                  decoration: const InputDecoration(
                                    suffixText: 'h',
                                  ),
                              ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tr('chooseYear'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tr('chooseYearHint'),
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final year in ['year1', 'year2', 'year3'])
                ChoiceChip(
                  label: Text(l10n.tr(year)),
                  selected: _academicYear == year,
                  onSelected: (_) {
                    setState(() => _academicYear = year);
                    widget.store.setAcademicYear(year);
                  },
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: _academicYear == year
                        ? Colors.white
                        : AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.flag_outlined, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.tr('yearlyGoal'), style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          l10n.tr('yearlyGoalHint'),
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _yearlyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [_decimalInputFormatter()],
                      decoration: const InputDecoration(
                        suffixText: 'h',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              widget.store.updateLimits({
                for (final category in _controllers.keys)
                  category: double.tryParse(
                        _controllers[category]!.text.replaceAll(',', '.'),
                      ) ??
                      20,
              });
               widget.store.updateDailyLimits({
                 for (final category in _dailyControllers.keys)
                   category: double.tryParse(
                         _dailyControllers[category]!.text.replaceAll(',', '.'),
                       ) ??
                       8,
               });
              widget.store.setYearlyGoal(
                double.tryParse(_yearlyController.text.replaceAll(',', '.')) ?? 100,
              );
               widget.store.setAcademicYear(_academicYear);
              Navigator.pop(context);
            },
            child: Text(l10n.tr('applyLimits')),
          ),
          const SizedBox(height: 28),
          Divider(color: AppColors.border),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              l10n.tr('advancedSettings'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            children: [
          // --- Unavailable periods ---
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tr('unavailablePeriods'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addPeriod(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.tr('addPeriod')),
              ),
            ],
          ),
          Text(
            l10n.tr('unavailablePeriodsHint'),
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          if (store.blockedPeriods.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.tr('noPeriods'),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            )
          else
            ...store.blockedPeriods.map(
              (p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.event_busy, color: AppColors.danger),
                  title: Text(
                    p.label.isEmpty ? l10n.tr('unavailablePeriods') : p.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('${_displayDate(p.start, l10n)} – ${_displayDate(p.end, l10n)}'),
                  trailing: IconButton(
                    tooltip: l10n.tr('removePeriod'),
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() => store.removeBlockedPeriod(p.id));
                    },
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Divider(color: AppColors.border),
          const SizedBox(height: 8),
          // --- Recurring weekly blocked day ---
          Text(
            l10n.tr('recurringDayQuestion'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            l10n.tr('recurringDayHint'),
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _yesNoChip(true, l10n.tr('yes')),
              const SizedBox(width: 8),
              _yesNoChip(false, l10n.tr('no')),
            ],
          ),
          if (_hasRecurringDay) ...[
            const SizedBox(height: 12),
            Text(
              l10n.tr('pickDay'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final selected = _recurringDay == i;
                return ChoiceChip(
                  label: Text(l10n.weekdays[i]),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _recurringDay = i);
                    store.setBlockedWeekday(i);
                  },
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }),
            ),
          ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _yesNoChip(bool value, String label) {
    final selected = _hasRecurringDay == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _hasRecurringDay = value;
          if (!value) {
            _recurringDay = null;
            widget.store.setBlockedWeekday(null);
          } else if (_recurringDay == null) {
            _recurringDay = 0;
            widget.store.setBlockedWeekday(0);
          }
        });
      },
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.text,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Future<void> _addPeriod(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final labelController = TextEditingController();
    DateTime? start;
    DateTime? end;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.tr('addPeriod')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: labelController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: l10n.tr('periodLabel'),
                    hintText: l10n.tr('periodLabelHint'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(start == null ? l10n.tr('startDate') : _prettyDate(start!, l10n)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: start ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => start = picked);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(end == null ? l10n.tr('endDate') : _prettyDate(end!, l10n)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: end ?? (start ?? DateTime.now()),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => end = picked);
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (start == null || end == null) {
                  setDialogState(() => error = l10n.tr('invalidPeriod'));
                  return;
                }
                // The start date must be strictly before the end date.
                if (!start!.isBefore(end!)) {
                  setDialogState(() => error = l10n.tr('invalidPeriod'));
                  return;
                }
                widget.store.addBlockedPeriod(
                  BlockedPeriod(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    start: dateKey(start!),
                    end: dateKey(end!),
                    label: labelController.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext);
                setState(() {});
              },
              child: Text(l10n.tr('save')),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({required this.store, super.key});

  final HourDraftStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = ['indoor', 'outdoor', 'group'];
    final totals = {for (final c in categories) c: store.total(category: c)};
    final yearlyProgress = store.yearlyGoal <= 0
        ? 0.0
        : (store.total() / store.yearlyGoal).clamp(0, 1).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('analytics'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('total'),
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatHours(store.total())}h',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.tr(
                      'daysLogged',
                      {'days': '${store.loggedDays()}'},
                    ),
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // --- Yearly goal circle ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: yearlyProgress,
                          strokeWidth: 7,
                          color: AppColors.accent,
                          backgroundColor: AppColors.accentLight,
                        ),
                        Text(
                          '${(yearlyProgress * 100).round()}%',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.tr('yearlyProgress'), style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatHours(store.total())}h / ${_formatHours(store.yearlyGoal)}h',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // --- Category share donut ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.tr('categoryShare'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: CustomPaint(
                          painter: _DonutPainter(
                            values: [totals['indoor']!, totals['outdoor']!, totals['group']!],
                            colors: [AppColors.indoor, AppColors.outdoor, AppColors.group],
                            trackColor: AppColors.border,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: categories
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: categoryColor(c),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(l10n.category(c), style: const TextStyle(fontSize: 12))),
                                      Text(
                                        '${_formatHours(totals[c]!)}h',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: categoryColor(c)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CategoryIcon(category: category),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.category(category),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${_formatHours(store.total(category: category))}h',
                        style: TextStyle(
                          color: categoryColor(category),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple donut chart with no external chart package — keeps the app light.
class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors, required this.trackColor});

  final List<double> values;
  final List<Color> colors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.18;
    final total = values.fold<double>(0, (a, b) => a + b);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 0, 2 * math.pi, false, trackPaint);

    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString();
}

class InfoPage extends StatelessWidget {
  const InfoPage({required this.kind, super.key});

  final String kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('privacy'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '''**Privacy Notice**

HourDraft is designed to work locally on the user's device.

The app may ask for the user's name to personalize the application. This information is stored locally on the user's device and is not transmitted to the developer, a remote server, or third parties.

HourDraft does not sell, share, or use the user's name for advertising or tracking.

The app does not require an online account or cloud storage for its core functionality.

© 2026 Ibrahim Alayan. All Rights Reserved.
''',
                style: TextStyle(
                  height: 1.6,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feedback & support page — old card-based design, now with one
/// "Open feedback form" link per language and a "Send email" button that
/// opens the device's mail app with a blank recipient.
///
/// The three form links (and the empty placeholder email address) live in
/// app_localizations.dart, at the top, in `feedbackFormLinks` and
/// `feedbackEmailAddress`.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('about'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.info_outline, color: AppColors.accent),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.tr('appName'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.tr('appVersion'),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.tr('aboutIntro'),
                    style: TextStyle(color: AppColors.textMuted, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formLink = AppLocalizations.feedbackFormLinks[l10n.locale.languageCode] ??
        AppLocalizations.feedbackFormLinks['en']!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('feedback'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.forum_outlined, color: AppColors.accent),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.tr('feedback'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tr('feedbackIntro'),
                    style: TextStyle(color: AppColors.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l10n.tr('openForm')),
                      onPressed: () => NativeLauncher.launchURL(formLink),
                    ),
                  ),
                  const SizedBox(height: 10),
                
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color categoryColor(String category) {
  switch (category) {
    case 'outdoor':
      return AppColors.outdoor;
    case 'group':
      return AppColors.group;
    default:
      return AppColors.indoor;
  }
}

Color categoryLightColor(String category) {
  switch (category) {
    case 'outdoor':
      return AppColors.outdoorLight;
    case 'group':
      return AppColors.groupLight;
    default:
      return AppColors.indoorLight;
  }
}

String _formatHours(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

TextInputFormatter _decimalInputFormatter() {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    final valid = RegExp(r'^\d*([.,]\d*)?$').hasMatch(newValue.text);
    return valid ? newValue : oldValue;
  });
}

String _initials(String value) {
  final words = value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  final initials = words
      .take(2)
      .map((word) => word.substring(0, 1))
      .join();
  return initials.isEmpty ? '?' : initials.toUpperCase();
}

DateTime _monday(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

String _prettyDate(DateTime date, AppLocalizations l10n) =>
    '${date.day} ${l10n.month(date.month)} ${date.year}';

String _displayDate(String value, AppLocalizations l10n) {
  final date = DateTime.tryParse(value);
  return date == null ? value : _prettyDate(date, l10n);
}