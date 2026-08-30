import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../app_state.dart';
import '../../app_localizations.dart';
import '../../main.dart' show RootShell, InfoPage;

class OnboardingPrivacyScreen extends StatelessWidget {
  const OnboardingPrivacyScreen({required this.store, super.key});

  final HourDraftStore store;

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
                        child: Icon(Icons.check, size: 56, color: AppColors.accent),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'You\'re all set!',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'By tapping Continue, you agree to our',
                        style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const InfoPage(kind: 'privacy'),
                              ),
                            ),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _dot(false),
                          const SizedBox(width: 8),
                          _dot(false),
                          const SizedBox(width: 8),
                          _dot(true),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            store.completeOnboarding();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => RootShell(store: store),
                              ),
                            );
                          },
                          child: Text(l10n.tr('continueLabel')),
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