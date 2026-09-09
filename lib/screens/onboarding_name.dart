import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../app_state.dart';
import '../../app_localizations.dart';
import 'onboarding_privacy.dart';

/// Third onboarding step (before Privacy) — asks for the student's name and
/// saves it via [HourDraftStore.updateProfile] before moving on. This is the
/// same save path the Profile page uses later, so the name typed here is
/// exactly what shows up in the drawer / Profile screen afterwards.
class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({required this.store, super.key});

  final HourDraftStore store;

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final l10n = AppLocalizations.of(context);
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = l10n.tr('nameRequiredError'));
      return;
    }
    // Saved immediately — HourDraftStore._changed() persists it to disk
    // right away, same as every other store mutation in the app.
    widget.store.updateProfile(newName: value);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OnboardingPrivacyScreen(store: widget.store),
      ),
    );
  }

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
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.badge_outlined, size: 52, color: AppColors.accent),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.tr('chooseNameTitle'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          letterSpacing: -0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.tr('chooseNameSubtitle'),
                        style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          labelText: l10n.tr('yourNameLabel'),
                          hintText: l10n.tr('yourNameHint'),
                          errorText: _error,
                        ),
                        onSubmitted: (_) => _continue(),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                      const Spacer(),
                      // 4 steps total: Welcome -> How -> Name (this) -> Privacy
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _dot(false),
                          const SizedBox(width: 8),
                          _dot(false),
                          const SizedBox(width: 8),
                          _dot(true),
                          const SizedBox(width: 8),
                          _dot(false),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _continue,
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