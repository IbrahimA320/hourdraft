import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../app_state.dart';
import '../../app_localizations.dart';
import 'onboarding_privacy.dart';

class OnboardingHowScreen extends StatelessWidget {
  const OnboardingHowScreen({required this.store, super.key});

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
                      _featureCard(
                        icon: Icons.calendar_today,
                        iconColor: AppColors.indoor,
                        bgColor: AppColors.indoorLight,
                        title: 'Log Hours by Opportunity',
                        subtitle: 'Record time across all your programs in one place.',
                      ),
                      const SizedBox(height: 12),
                      _featureCard(
                        icon: Icons.bar_chart,
                        iconColor: AppColors.outdoor,
                        bgColor: AppColors.outdoorLight,
                        title: 'Stay Within Weekly Limits',
                        subtitle: 'Get alerts when you\'re near your indoor, outdoor, or group caps.',
                      ),
                      const SizedBox(height: 12),
                      _featureCard(
                        icon: Icons.check_circle,
                        iconColor: AppColors.group,
                        bgColor: AppColors.groupLight,
                        title: 'Track Approval Status',
                        subtitle: 'Know which hours are pending and which are approved.',
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => OnboardingPrivacyScreen(store: store),
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

  Widget _featureCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
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