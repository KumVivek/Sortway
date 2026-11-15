import 'dart:io';

import 'package:flow_core/flow_core.dart';
import 'package:flow_levelgen/flow_levelgen.dart';
import 'package:flow_solver/flow_solver.dart';
import 'package:test/test.dart';

void main() {
  group('hand-made levels', () {
    final levels = handmadeLevels();

    test('there are 30, numbered L001..L030', () {
      expect(levels, hasLength(handmadeCount));
      expect(levels.first.id, 'L001');
      expect(levels.last.id, 'L030');
    });

    test('use only basic routing (M0-M1)', () {
      for (final l in levels) {
        expect(l.gates, isEmpty, reason: l.id);
        expect(l.bins.any((b) => b.unlockAfter != null), isFalse);
        expect(l.meta.mechanics, isEmpty, reason: l.id);
      }
    });

    test('start gentle: first three have one switch and two colours', () {
      for (final l in levels.take(3)) {
        expect(l.switches, hasLength(1));
        expect(l.bins, hasLength(2));
      }
      expect(levels.first.meta.tutorial, 'tap_switch');
    });

    test('every one is winnable without a mistake', () {
      for (final l in levels) {
        final r = solve(l);
        expect(r.perfect, isTrue, reason: l.id);
        expect(playSolution(l, r).status, GameStatus.won, reason: l.id);
        expect(l.meta.parFlips, r.minFlips, reason: l.id);
      }
    });
  });

  group('compact notation', () {
    test('parses trees, belts and initial switches', () {
      final l = parseCompactLevel(
        id: 'X',
        tree: '(r(bg))',
        belt: 'rbbg',
        init: 'LR',
      );
      expect(l.switches.map((s) => s.id), ['s1', 's2']);
      expect(l.bins.map((b) => b.colour), [
        ItemColour.red,
        ItemColour.blue,
        ItemColour.green,
      ]);
      expect(l.bins[1].capacity, 2);
      expect(l.initialSwitches, {'s1': SwitchDir.left, 's2': SwitchDir.right});
    });

    test('rejects bad input', () {
      LevelDef p(String tree, String belt) =>
          parseCompactLevel(id: 'X', tree: tree, belt: belt);
      expect(() => p('(rb)', 'rz'), throwsFormatException);
      expect(() => p('(rz)', 'r'), throwsFormatException);
      expect(() => p('(rb', 'r'), throwsFormatException);
      expect(() => p('(r', 'r'), throwsFormatException);
      expect(() => p('(rb)b', 'r'), throwsFormatException);
    });
  });

  group('generator', () {
    test('is deterministic for a seed', () {
      const req = GenRequest(id: 'A', seed: 12345, band: 4);
      final a = generateCandidates(req);
      final b = generateCandidates(req);
      expect(a, isNotEmpty);
      expect([for (final l in a) l.toJson()], [for (final l in b) l.toJson()]);
    });

    test('respects the band template and needs more than one flip', () {
      for (var band = minBand; band <= maxBand; band++) {
        final t = templateFor(band);
        final levels = generateCandidates(
          GenRequest(id: 'B', seed: 900 + band, band: band),
          candidates: 4,
        );
        expect(levels, isNotEmpty, reason: 'band $band');
        for (final l in levels) {
          expect(l.bins.length, inInclusiveRange(t.minBins, t.maxBins));
          expect(l.belt.length, inInclusiveRange(t.minBelt, t.maxBelt));
          expect(l.tickMs, t.tickMs);
          expect(l.meta.band, band);
          expect(l.meta.parFlips, greaterThan(1));
          final r = solve(l, reactionBudget: l.meta.reactionBudget);
          expect(r.perfect, isTrue);
          expect(playSolution(l, r).livesLost, 0);
        }
      }
    });

    test('can require a mechanic or forbid them', () {
      final locked = generateCandidates(
        const GenRequest(
          id: 'L',
          seed: 5,
          band: 2,
          require: Mechanics.lockedBin,
        ),
      );
      expect(locked, isNotEmpty);
      for (final l in locked) {
        expect(l.meta.mechanics, [Mechanics.lockedBin]);
      }
      final gated = generateCandidates(
        const GenRequest(
          id: 'G',
          seed: 6,
          band: 2,
          require: Mechanics.colourGate,
        ),
      );
      expect(gated, isNotEmpty);
      for (final l in gated) {
        expect(l.meta.mechanics, [Mechanics.colourGate]);
      }
      final plain = generateCandidates(
        const GenRequest(
          id: 'P',
          seed: 7,
          band: 5,
          allowLocked: false,
          allowGates: false,
        ),
      );
      for (final l in plain) {
        expect(l.gates, isEmpty);
        expect(l.bins.any((b) => b.unlockAfter != null), isFalse);
      }
    });

    test('batch output is distinct, sized and sorted by difficulty', () {
      final levels = generateBatch(band: 3, count: 12, seed: 1000);
      expect(levels, hasLength(12));
      expect({for (final l in levels) levelHash(l)}, hasLength(12));
      expect(levels.first.id, 'G001');
      for (var i = 1; i < levels.length; i++) {
        expect(
          levels[i].meta.difficulty,
          greaterThanOrEqualTo(levels[i - 1].meta.difficulty),
        );
      }
    });

    test('daily challenge is the same for everyone on a date', () {
      final a = generateDaily(DateTime(2026, 11, 14, 8));
      final b = generateDaily(DateTime(2026, 11, 14, 23, 59));
      final next = generateDaily(DateTime(2026, 11, 15));
      expect(a.id, 'D20261114');
      expect(a.toJson(), b.toJson());
      expect(levelHash(next), isNot(levelHash(a)));
      expect(solve(a, reactionBudget: a.meta.reactionBudget).perfect, isTrue);
      final harder = generateDaily(DateTime(2026, 11, 14), difficultyOffset: 2);
      expect(harder.meta.band, greaterThan(a.meta.band));
    });

    test('a month of dailies always generates', () {
      for (var d = 1; d <= 30; d++) {
        expect(generateDaily(DateTime(2027, 4, d)).belt, isNotEmpty);
      }
    });

    test('weekly event has seven distinct solvable levels', () {
      final levels = generateEvent(eventId: 'ev1', seed: 77);
      expect(levels, hasLength(7));
      expect({for (final l in levels) levelHash(l)}, hasLength(7));
      expect(levels.first.id, 'ev1-1');
      expect(levels.last.meta.band, greaterThan(levels.first.meta.band));
    });
  });

  group('campaign', () {
    final packs = buildCampaignPacks();
    final all = [for (final p in packs) ...p.levels];

    test('has 240 uniquely numbered, distinct levels', () {
      expect(all, hasLength(campaignLength));
      for (var i = 0; i < all.length; i++) {
        expect(all[i].id, levelId(i + 1));
      }
      expect({for (final l in all) levelHash(l)}, hasLength(campaignLength));
    });

    test('introduces mechanics on schedule with tutorial levels', () {
      for (var n = 1; n <= campaignLength; n++) {
        final m = all[n - 1].meta.mechanics;
        if (n < lockedBinFirstLevel) {
          expect(m.contains(Mechanics.lockedBin), isFalse, reason: 'L$n');
        }
        if (n < colourGateFirstLevel) {
          expect(m.contains(Mechanics.colourGate), isFalse, reason: 'L$n');
        }
      }
      for (var n = lockedBinFirstLevel; n < lockedBinFirstLevel + 3; n++) {
        expect(all[n - 1].meta.mechanics, [Mechanics.lockedBin]);
      }
      for (var n = colourGateFirstLevel; n < colourGateFirstLevel + 3; n++) {
        expect(all[n - 1].meta.mechanics, [Mechanics.colourGate]);
      }
      expect(all[lockedBinFirstLevel - 1].meta.tutorial, Mechanics.lockedBin);
      expect(all[colourGateFirstLevel - 1].meta.tutorial, Mechanics.colourGate);
    });

    test('marks every tenth level hard and ramps the band up', () {
      for (var n = 60; n <= campaignLength; n += 10) {
        expect(all[n - 1].meta.hard, isTrue, reason: 'L$n');
      }
      double avg(int from, int to) =>
          all
              .sublist(from - 1, to)
              .map((l) => l.meta.difficulty)
              .reduce((a, b) => a + b) /
          (to - from + 1);
      expect(avg(200, 240), greaterThan(avg(50, 90)));
      expect(campaignBand(240), greaterThan(campaignBand(52)));
      // Breather: the sixth level of each cycle sits below its neighbours.
      expect(campaignBand(126), lessThan(campaignBand(125)));
    });

    test('every level is winnable without a mistake, fast', () {
      var worst = 0;
      for (final l in all) {
        final sw = Stopwatch()..start();
        final r = solve(l, reactionBudget: l.meta.reactionBudget);
        sw.stop();
        if (sw.elapsedMilliseconds > worst) worst = sw.elapsedMilliseconds;
        expect(r.perfect, isTrue, reason: l.id);
        final end = playSolution(l, r);
        expect(end.status, GameStatus.won, reason: l.id);
        expect(end.livesLost, 0, reason: l.id);
      }
      // Plan budget is 200 ms; leave headroom for slow CI machines.
      expect(worst, lessThan(1000));
    });

    test('bundled assets match the generator output', () {
      for (final pack in packs) {
        final file = File('../../app/assets/levels/${pack.packId}.json');
        expect(file.existsSync(), isTrue, reason: file.path);
        expect(
          decodeLevelPack(file.readAsStringSync()).toJson(),
          pack.toJson(),
          reason:
              'Run `dart run flow_levelgen:flow_levelgen campaign` to refresh',
        );
      }
    });
  });
}
