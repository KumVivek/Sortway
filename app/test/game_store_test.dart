import 'package:flow_sort/services/database.dart';
import 'package:flow_sort/services/game_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameStore store;

  setUp(() => store = GameStore(AppDatabase.memory()));
  tearDown(() => store.close());

  test('wallet starts once, adds, spends, and never goes negative', () async {
    await store.ensureWallet(300);
    await store.ensureWallet(999);
    expect(await store.coins(), 300);
    expect(await store.addCoins(50), 350);
    expect(await store.spendCoins(400), isFalse);
    expect(await store.spendCoins(-5), isFalse);
    expect(await store.spendCoins(350), isTrue);
    expect(await store.coins(), 0);
    expect(await store.addCoins(-20), 0);
  });

  test('watchCoins emits changes', () async {
    await store.ensureWallet(10);
    final seen = <int>[];
    final sub = store.watchCoins().listen(seen.add);
    await pumpEventQueue();
    await store.addCoins(5);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, containsAllInOrder([10, 15]));
  });

  test('attempts are counted without marking the level complete', () async {
    await store.recordAttempt('L001');
    await store.recordAttempt('L001');
    final p = (await store.progress())['L001']!;
    expect(p.attempts, 2);
    expect(p.completed, isFalse);
    expect(p.stars, 0);
  });

  test(
    'completeLevel saves stars, flips, coins and sticker together',
    () async {
      await store.ensureWallet(0);
      await store.recordAttempt('L001');
      await store.saveSnapshot({'ref': 'campaign:L001'});
      final first = await store.completeLevel(
        levelId: 'L001',
        stars: 2,
        flips: 9,
        coinsFor: (first, prev) => first ? 30 : 5,
        sticker: (set: 0, index: 4),
        now: DateTime(2026, 1, 2),
      );
      expect(first.firstCompletion, isTrue);
      expect(first.coins, 30);
      expect(await store.stickers(), {(set: 0, index: 4)});
      expect(await store.loadSnapshot(), isNull, reason: 'snapshot cleared');

      final again = await store.completeLevel(
        levelId: 'L001',
        stars: 1,
        flips: 12,
        coinsFor: (first, prev) => first ? 30 : 5,
      );
      expect(again.firstCompletion, isFalse);
      expect(again.previousStars, 2);
      expect(again.coins, 35);
      final p = (await store.progress())['L001']!;
      expect(p.stars, 2, reason: 'best stars are kept');
      expect(p.bestFlips, 9, reason: 'fewest flips are kept');
      expect(p.completedAt, DateTime(2026, 1, 2));
      expect(p.attempts, 1);

      final better = await store.completeLevel(
        levelId: 'L001',
        stars: 3,
        flips: 7,
        coinsFor: (_, __) => 0,
        sticker: (set: 0, index: 4),
      );
      expect(better.previousStars, 2);
      final p2 = (await store.progress())['L001']!;
      expect(p2.stars, 3);
      expect(p2.bestFlips, 7);
      expect(
        await store.stickers(),
        hasLength(1),
        reason: 'no duplicate sticker',
      );
    },
  );

  test('a failed transaction leaves nothing behind', () async {
    await store.ensureWallet(100);
    await expectLater(
      store.completeLevel(
        levelId: 'L002',
        stars: 3,
        flips: 1,
        coinsFor: (_, __) => throw StateError('boom'),
        sticker: (set: 0, index: 0),
      ),
      throwsStateError,
    );
    expect(await store.progress(), isEmpty);
    expect(await store.stickers(), isEmpty);
    expect(await store.coins(), 100);
  });

  test('snapshot round trip and corruption recovery', () async {
    expect(await store.loadSnapshot(), isNull);
    await store.saveSnapshot({
      'ref': 'daily:20261114',
      'session': {'flips': 3},
    });
    final snap = await store.loadSnapshot();
    expect(snap!['ref'], 'daily:20261114');
    await store.write('snapshot', '{not json');
    expect(await store.loadSnapshot(), isNull);
    expect(await store.read('snapshot'), isNull);
    await store.saveSnapshot({'ref': 'x'});
    await store.clearSnapshot();
    expect(await store.loadSnapshot(), isNull);
  });

  test('key/value helpers and watch streams', () async {
    expect(await store.readInt('missing', orElse: 4), 4);
    await store.write('k', '12');
    expect(await store.readInt('k'), 12);
    await store.remove('k');
    expect(await store.read('k'), isNull);

    await store.completeLevel(
      levelId: 'L009',
      stars: 3,
      flips: 2,
      coinsFor: (_, __) => 0,
      sticker: (set: 1, index: 2),
    );
    expect((await store.watchProgress().first)['L009']!.stars, 3);
    expect(await store.watchStickers().first, {(set: 1, index: 2)});
  });
}
