import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../app_state.dart';
import '../../app_localizations.dart';
import 'onboarding_how.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({required this.store, super.key});

  final HourDraftStore store;

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 64,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_month, size: 64, color: AppColors.accent),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Welcome to Pathway',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Track your hours. Reach your goals. Stay organized.',
                        style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // --- Language picker lives on the first screen ---
                      Text(
                        l10n.tr('chooseLanguage'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: .3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _langChip('en', l10n.tr('languageEnglish')),
                          _langChip('ar', l10n.tr('languageArabic')),
                          _langChip('he', l10n.tr('languageHebrew')),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _dot(true),
                          const SizedBox(width: 8),
                          _dot(false),
                          const SizedBox(width: 8),
                          _dot(false),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => OnboardingHowScreen(store: widget.store),
                            ),
                          ),
                          child: Text(l10n.tr('next')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _langChip(String code, String label) {
    final selected = widget.store.languageCode == code;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => widget.store.setLanguage(code)),
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.border),
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.border,
        shape: BoxShape.circle,
      ),
    );
  }
}