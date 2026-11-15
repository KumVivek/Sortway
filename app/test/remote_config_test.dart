import 'dart:io';

import 'package:flow_sort/config/env.dart';
import 'package:flow_sort/services/remote_config_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local defaults match plan section 9', () {
    final v = RemoteConfigValues.defaults;
    expect(v.interstitialFirstLevel, 10);
    expect(v.interstitialMinGapLevels, 3);
    expect(v.interstitialMinGapSeconds, 90);
    expect(v.rewardedDoubleCoinsEnabled, isTrue);
    expect(v.beltTickMsBase, 600);
    expect(v.difficultyOffset, 0);
    expect(v.coinsLevelComplete, 20);
    expect(v.coinsSetComplete, 300);
    expect(v.coinsDaily, 100);
    expect(v.startingCoins, 300);
    expect(v.boosterPrices, {'undo': 100, 'life': 150, 'slow': 120});
    expect(v.levelPackManifest, isEmpty);
    expect(v.weeklyEvent, isNull);
    expect(v.forceUpdateMinVersion, '1.0.0');
    expect(v.tickScale, 1.0);
    expect(remoteConfigDefaults.keys, hasLength(14));
  });

  test('remote values override defaults', () {
    final v = RemoteConfigValues.fromRaw({
      RcKeys.coinsDaily: '250',
      RcKeys.rewardedDoubleCoinsEnabled: 'false',
      RcKeys.boosterPrices: '{"undo":1,"life":2,"slow":3}',
      RcKeys.beltTickMsBase: '900',
      RcKeys.difficultyOffset: '-2',
    });
    expect(v.coinsDaily, 250);
    expect(v.rewardedDoubleCoinsEnabled, isFalse);
    expect(v.boosterPrices, {'undo': 1, 'life': 2, 'slow': 3});
    expect(v.tickScale, closeTo(1.5 * 1.16, 1e-9));
  });

  test('bad remote values fall back or clamp instead of breaking', () {
    final v = RemoteConfigValues.fromRaw({
      RcKeys.coinsDaily: 'lots',
      RcKeys.boosterPrices: '{"undo":5}',
      RcKeys.difficultyOffset: '9',
      RcKeys.beltTickMsBase: '1',
      RcKeys.levelPackManifest: 'not json',
      RcKeys.weeklyEvent: '{"id":""}',
      RcKeys.interstitialFirstLevel: '-4',
    });
    expect(v.coinsDaily, 100);
    expect(v.boosterPrices, {'undo': 100, 'life': 150, 'slow': 120});
    expect(v.difficultyOffset, 2);
    expect(v.beltTickMsBase, 200);
    expect(v.levelPackManifest, isEmpty);
    expect(v.weeklyEvent, isNull);
    expect(v.interstitialFirstLevel, 1);
  });

  test('pack manifest keeps only well-formed https entries', () {
    final v = RemoteConfigValues.fromRaw({
      RcKeys.levelPackManifest:
          '[{"id":"core_003","version":2,"url":"https://x/y.json"},'
          '{"id":"bad","version":1,"url":"http://x/y.json"},'
          '{"id":"worse"}, 7]',
    });
    expect(v.levelPackManifest, hasLength(1));
    expect(v.levelPackManifest.single.id, 'core_003');
    expect(v.levelPackManifest.single.version, 2);
    expect(
      RemoteConfigValues.fromRaw({
        RcKeys.levelPackManifest: '{}',
      }).levelPackManifest,
      isEmpty,
    );
  });

  test('weekly event runs Monday to Sunday', () {
    final e =
        WeeklyEventConfig.tryParse(
          '{"id":"ev1","title":"Ocean Week","seed":5,"band":4,"reward":500,'
          '"start":"2026-11-16"}',
        )!;
    expect(e.title, 'Ocean Week');
    expect(e.isActive(DateTime(2026, 11, 15, 23)), isFalse);
    expect(e.isActive(DateTime(2026, 11, 16)), isTrue);
    expect(e.isActive(DateTime(2026, 11, 22, 23, 59)), isTrue);
    expect(e.isActive(DateTime(2026, 11, 23)), isFalse);
    expect(WeeklyEventConfig.tryParse('null'), isNull);
    expect(WeeklyEventConfig.tryParse('{"id":"x"}'), isNull);
    final minimal =
        WeeklyEventConfig.tryParse('{"id":"x","start":"2026-01-05"}')!;
    expect(minimal.title, 'x');
    expect(minimal.band, 4);
    expect(minimal.reward, 500);
  });

  test('version comparison', () {
    expect(compareVersions('1.0.0', '1.0.0'), 0);
    expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
    expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
    expect(compareVersions('2', '1.9'), greaterThan(0));
    expect(compareVersions('1.0.0+7', '1.0.0'), 0);
  });

  test('kAppVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([^\s+]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(kAppVersion, version);
  });

  test('local service notifies on change', () async {
    final service = LocalRemoteConfigService();
    final next = service.changes.first;
    service.set({RcKeys.coinsDaily: '7'});
    expect((await next).coinsDaily, 7);
    expect(service.values.coinsDaily, 7);
    await service.refresh();
  });
}
