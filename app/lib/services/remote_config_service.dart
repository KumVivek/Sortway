import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Remote Config keys (plan §9).
abstract final class RcKeys {
  static const interstitialFirstLevel = 'interstitial_first_level';
  static const interstitialMinGapLevels = 'interstitial_min_gap_levels';
  static const interstitialMinGapSeconds = 'interstitial_min_gap_seconds';
  static const rewardedDoubleCoinsEnabled = 'rewarded_double_coins_enabled';
  static const beltTickMsBase = 'belt_tick_ms_base';
  static const difficultyOffset = 'difficulty_offset';
  static const coinsLevelComplete = 'coins_level_complete';
  static const coinsSetComplete = 'coins_set_complete';
  static const coinsDaily = 'coins_daily';
  static const startingCoins = 'starting_coins';
  static const boosterPrices = 'booster_prices';
  static const levelPackManifest = 'level_pack_manifest';
  static const weeklyEvent = 'weekly_event';
  static const forceUpdateMinVersion = 'force_update_min_version';
}

/// Local defaults for every key, exactly as listed in plan §9. Values are
/// strings because that is what Remote Config stores.
const Map<String, String> remoteConfigDefaults = {
  RcKeys.interstitialFirstLevel: '10',
  RcKeys.interstitialMinGapLevels: '3',
  RcKeys.interstitialMinGapSeconds: '90',
  RcKeys.rewardedDoubleCoinsEnabled: 'true',
  RcKeys.beltTickMsBase: '600',
  RcKeys.difficultyOffset: '0',
  RcKeys.coinsLevelComplete: '20',
  RcKeys.coinsSetComplete: '300',
  RcKeys.coinsDaily: '100',
  RcKeys.startingCoins: '300',
  RcKeys.boosterPrices: '{"undo":100,"life":150,"slow":120}',
  RcKeys.levelPackManifest: '[]',
  RcKeys.weeklyEvent: 'null',
  RcKeys.forceUpdateMinVersion: '1.0.0',
};

class PackManifestEntry {
  const PackManifestEntry({
    required this.id,
    required this.version,
    required this.url,
  });

  final String id;
  final int version;
  final String url;
}

class WeeklyEventConfig {
  const WeeklyEventConfig({
    required this.id,
    required this.title,
    required this.seed,
    required this.band,
    required this.reward,
    required this.start,
  });

  final String id;
  final String title;
  final int seed;
  final int band;
  final int reward;

  /// Monday the event opens; it runs for seven days.
  final DateTime start;

  bool isActive(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    final first = DateTime(start.year, start.month, start.day);
    return !day.isBefore(first) &&
        day.isBefore(first.add(const Duration(days: 7)));
  }

  static WeeklyEventConfig? tryParse(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      final id = json['id'];
      final start = DateTime.tryParse(json['start'] as String? ?? '');
      if (id is! String || id.isEmpty || start == null) return null;
      return WeeklyEventConfig(
        id: id,
        title: json['title'] as String? ?? id,
        seed: (json['seed'] as num?)?.toInt() ?? id.hashCode & 0xFFFFFF,
        band: ((json['band'] as num?)?.toInt() ?? 4).clamp(1, 8),
        reward: ((json['reward'] as num?)?.toInt() ?? 500).clamp(0, 100000),
        start: start,
      );
    } on Object {
      return null;
    }
  }
}

/// Typed, validated snapshot of the tunables. Bad remote values fall back to
/// the local default for that key, so a typo in the console cannot break the
/// game.
@immutable
class RemoteConfigValues {
  const RemoteConfigValues._(this._raw);

  factory RemoteConfigValues.fromRaw([Map<String, String> raw = const {}]) =>
      RemoteConfigValues._({...remoteConfigDefaults, ...raw});

  static final RemoteConfigValues defaults = RemoteConfigValues.fromRaw();

  final Map<String, String> _raw;

  int _int(String key, {int min = 0, int max = 1 << 30}) {
    final v =
        int.tryParse(_raw[key]!.trim()) ??
        int.parse(remoteConfigDefaults[key]!);
    return v.clamp(min, max);
  }

  int get interstitialFirstLevel => _int(RcKeys.interstitialFirstLevel, min: 1);
  int get interstitialMinGapLevels => _int(RcKeys.interstitialMinGapLevels);
  int get interstitialMinGapSeconds => _int(RcKeys.interstitialMinGapSeconds);
  bool get rewardedDoubleCoinsEnabled =>
      _raw[RcKeys.rewardedDoubleCoinsEnabled]!.trim().toLowerCase() == 'true';
  int get beltTickMsBase => _int(RcKeys.beltTickMsBase, min: 200, max: 3000);
  int get difficultyOffset => _int(RcKeys.difficultyOffset, min: -2, max: 2);
  int get coinsLevelComplete => _int(RcKeys.coinsLevelComplete, max: 100000);
  int get coinsSetComplete => _int(RcKeys.coinsSetComplete, max: 100000);
  int get coinsDaily => _int(RcKeys.coinsDaily, max: 100000);
  int get startingCoins => _int(RcKeys.startingCoins, max: 1000000);
  String get forceUpdateMinVersion =>
      _raw[RcKeys.forceUpdateMinVersion]!.trim();

  /// Multiplier applied to every level's `tickMs`: the base tick relative to
  /// the 600 ms the packs were authored against, slowed or sped up 8% per
  /// `difficulty_offset` band.
  double get tickScale =>
      (beltTickMsBase / 600) * (1 - 0.08 * difficultyOffset);

  Map<String, int> get boosterPrices {
    Map<String, int> parse(String raw) {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return {
        for (final k in const ['undo', 'life', 'slow'])
          k: ((json[k]! as num).toInt()).clamp(0, 1000000),
      };
    }

    try {
      return parse(_raw[RcKeys.boosterPrices]!);
    } on Object {
      return parse(remoteConfigDefaults[RcKeys.boosterPrices]!);
    }
  }

  List<PackManifestEntry> get levelPackManifest {
    try {
      final json = jsonDecode(_raw[RcKeys.levelPackManifest]!);
      if (json is! List<Object?>) return const [];
      return [
        for (final e in json)
          if (e is Map<String, Object?> &&
              e['id'] is String &&
              e['version'] is int &&
              e['url'] is String &&
              (e['url']! as String).startsWith('https://'))
            PackManifestEntry(
              id: e['id']! as String,
              version: e['version']! as int,
              url: e['url']! as String,
            ),
      ];
    } on Object {
      return const [];
    }
  }

  WeeklyEventConfig? get weeklyEvent =>
      WeeklyEventConfig.tryParse(_raw[RcKeys.weeklyEvent]!);
}

/// Compares dotted versions; missing parts count as zero.
int compareVersions(String a, String b) {
  List<int> parts(String v) => [
    for (final p in v.split('+').first.split('.')) int.tryParse(p.trim()) ?? 0,
  ];
  final pa = parts(a);
  final pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

abstract class RemoteConfigService {
  RemoteConfigValues get values;

  /// Fires after a successful [refresh] changed the values.
  Stream<RemoteConfigValues> get changes;

  /// Fetches and activates new values. Never throws; offline keeps the
  /// current values.
  Future<void> refresh();
}

/// Local defaults only (tests, local mode, and whenever Firebase is off).
class LocalRemoteConfigService implements RemoteConfigService {
  LocalRemoteConfigService([Map<String, String> overrides = const {}])
    : values = RemoteConfigValues.fromRaw(overrides);

  final _changes = StreamController<RemoteConfigValues>.broadcast();

  @override
  RemoteConfigValues values;

  @override
  Stream<RemoteConfigValues> get changes => _changes.stream;

  @override
  Future<void> refresh() async {}

  /// Test helper: replace values and notify listeners.
  void set(Map<String, String> overrides) {
    values = RemoteConfigValues.fromRaw(overrides);
    _changes.add(values);
  }
}

class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService(this._rc);

  final FirebaseRemoteConfig _rc;
  final _changes = StreamController<RemoteConfigValues>.broadcast();

  @override
  RemoteConfigValues values = RemoteConfigValues.defaults;

  @override
  Stream<RemoteConfigValues> get changes => _changes.stream;

  Future<void> initialize() async {
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            kDebugMode ? const Duration(minutes: 1) : const Duration(hours: 6),
      ),
    );
    await _rc.setDefaults(remoteConfigDefaults);
    _read();
  }

  void _read() {
    values = RemoteConfigValues.fromRaw({
      for (final key in remoteConfigDefaults.keys) key: _rc.getString(key),
    });
  }

  @override
  Future<void> refresh() async {
    try {
      if (await _rc.fetchAndActivate()) {
        _read();
        _changes.add(values);
      }
    } on Object catch (e) {
      debugPrint('Remote Config refresh failed: $e');
    }
  }
}
