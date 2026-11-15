import 'dart:async';

import 'package:flutter/material.dart';

import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../onboarding/age_policy.dart';
import 'ads_service.dart';

/// Stand-in ads for local development: shows a clearly labelled "Test ad"
/// screen so every ad flow can be exercised without an AdMob account.
/// Bootstrap only ever selects this outside release builds.
class SimulatedAdsService implements AdsService {
  SimulatedAdsService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  AdRequestProfile? profile;

  @override
  bool get available => true;

  /// Local mode has no consent form.
  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<void> initialize(AgePolicy policy) async =>
      profile = AdRequestProfile.forPolicy(policy);

  @override
  Future<void> applyPolicy(AgePolicy policy) async =>
      profile = AdRequestProfile.forPolicy(policy);

  Future<bool> _show({required int seconds}) async {
    final context = _navigatorKey.currentContext;
    if (context == null) return false;
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => _SimulatedAd(seconds: seconds),
    );
    return done ?? false;
  }

  @override
  Future<bool> showRewarded(RewardedPlacement placement) => _show(seconds: 3);

  @override
  Future<bool> showInterstitial() => _show(seconds: 2);
}

class _SimulatedAd extends StatefulWidget {
  const _SimulatedAd({required this.seconds});

  final int seconds;

  @override
  State<_SimulatedAd> createState() => _SimulatedAdState();
}

class _SimulatedAdState extends State<_SimulatedAd> {
  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.smart_display,
                  size: 72,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  l.simAdTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l.simAdBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDim),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  key: const Key('sim-ad-close'),
                  onPressed:
                      _left > 0 ? null : () => Navigator.of(context).pop(true),
                  child: Text(_left > 0 ? l.simAdClose(_left) : l.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
