import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  test('same seed, same sequence', () {
    final a = SeededRng(20261114);
    final b = SeededRng(20261114);
    for (var i = 0; i < 200; i++) {
      expect(a.nextUint32(), b.nextUint32());
    }
  });

  test('matches the reference mulberry32 output', () {
    // First values of mulberry32(1) from the reference JS implementation.
    final rng = SeededRng(1);
    expect(rng.nextUint32(), 2693262067);
    expect(rng.nextUint32(), 11749833);
  });

  test('different seeds diverge', () {
    expect(SeededRng(1).nextUint32(), isNot(SeededRng(2).nextUint32()));
  });

  test('ranges are respected', () {
    final rng = SeededRng(7);
    for (var i = 0; i < 2000; i++) {
      expect(rng.nextInt(5), inInclusiveRange(0, 4));
      expect(rng.nextRange(3, 6), inInclusiveRange(3, 6));
      final d = rng.nextDouble();
      expect(d, greaterThanOrEqualTo(0));
      expect(d, lessThan(1));
    }
    expect(() => rng.nextInt(0), throwsRangeError);
  });

  test('nextInt is roughly uniform', () {
    final rng = SeededRng(99);
    final counts = List.filled(4, 0);
    for (var i = 0; i < 8000; i++) {
      counts[rng.nextInt(4)]++;
    }
    for (final c in counts) {
      expect(c, inInclusiveRange(1800, 2200));
    }
  });

  test('shuffle keeps the elements and is deterministic', () {
    final a = [1, 2, 3, 4, 5, 6, 7, 8];
    final b = [...a];
    SeededRng(5).shuffle(a);
    SeededRng(5).shuffle(b);
    expect(a, b);
    expect(a.toSet(), {1, 2, 3, 4, 5, 6, 7, 8});
    expect(SeededRng(5).pick(const ['x']), 'x');
    expect(SeededRng(5).nextBool(1), isTrue);
    expect(SeededRng(5).nextBool(0), isFalse);
  });
}
