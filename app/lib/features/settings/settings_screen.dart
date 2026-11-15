import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmAgeReset(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l.ageReset),
            content: Text(l.ageResetBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton(
                key: const Key('age-reset-confirm'),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l.confirm),
              ),
            ],
          ),
    );
    if (ok ?? false) await ref.read(settingsProvider.notifier).resetAgeBand();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    return AppScaffold(
      title: l.settings,
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('setting-sound'),
                    secondary: const Icon(Icons.volume_up_rounded),
                    title: Text(l.sound),
                    value: s.soundOn,
                    onChanged: (v) => c.setSound(on: v),
                  ),
                  SwitchListTile(
                    key: const Key('setting-music'),
                    secondary: const Icon(Icons.music_note_rounded),
                    title: Text(l.music),
                    value: s.musicOn,
                    onChanged: (v) => c.setMusic(on: v),
                  ),
                  SwitchListTile(
                    key: const Key('setting-haptics'),
                    secondary: const Icon(Icons.vibration_rounded),
                    title: Text(l.haptics),
                    value: s.hapticsOn,
                    onChanged: (v) => c.setHaptics(on: v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.language_rounded,
                          color: AppColors.textDim,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          l.language,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (code, label) in [
                          (null, l.languageSystem),
                          ('en', 'English'),
                          ('hi', 'हिन्दी'),
                        ])
                          ChoiceChip(
                            key: Key('lang-${code ?? 'system'}'),
                            label: Text(label),
                            selected: s.languageCode == code,
                            onSelected: (_) => c.setLanguage(code),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('setting-privacy'),
                    leading: const Icon(Icons.shield_rounded),
                    title: Text(l.privacy),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  ListTile(
                    key: const Key('setting-age-reset'),
                    leading: const Icon(Icons.cake_rounded),
                    title: Text(l.ageReset),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _confirmAgeReset(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                l.version(kAppVersion),
                style: const TextStyle(color: AppColors.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plain-language privacy page listing every SDK (plan §8).
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ads = ref.watch(adsServiceProvider);
    final paragraphs = [
      l.privacyData,
      l.privacyAge,
      l.privacyAds,
      l.privacyAnalytics,
      l.privacyCrash,
      l.privacyPurchases,
      l.privacyNone,
      if (Env.privacyPolicyUrl.isNotEmpty)
        l.privacyPolicyLink(Env.privacyPolicyUrl),
      if (Env.supportEmail.isNotEmpty) l.privacyContact(Env.supportEmail),
    ];
    return AppScaffold(
      title: l.privacyTitle,
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            for (final p in paragraphs) ...[
              SelectableText(p, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 14),
            ],
            // Required by Google's consent rules where they apply (EEA, UK,
            // Switzerland); never shown to minors, who get no consent form.
            if (ads.privacyOptionsRequired)
              OutlinedButton.icon(
                key: const Key('privacy-ad-choices'),
                onPressed: ads.showPrivacyOptions,
                icon: const Icon(Icons.tune_rounded),
                label: Text(l.privacyAdChoices),
              ),
          ],
        ),
      ),
    );
  }
}

/// Blocks the app when Remote Config says this version is too old.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppScaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.system_update_rounded,
                size: 64,
                color: AppColors.accent,
              ),
              const SizedBox(height: 16),
              Text(
                l.updateTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(l.updateBody, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
