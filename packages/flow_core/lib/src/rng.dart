/// Small deterministic PRNG (mulberry32). Same seed gives the same sequence
/// on every platform and Dart version, which `dart:math` does not promise.
class SeededRng {
  SeededRng(int seed) : _state = seed & _mask;

  static const int _mask = 0xFFFFFFFF;
  int _state;

  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask;
    var t = _state;
    t = _imul(t ^ (t >>> 15), t | 1);
    t ^= (t + _imul(t ^ (t >>> 7), t | 61)) & _mask;
    return (t ^ (t >>> 14)) & _mask;
  }

  /// Uniform integer in `[0, max)`.
  int nextInt(int max) {
    if (max <= 0) throw RangeError.range(max, 1, null, 'max');
    return (nextDouble() * max).floor();
  }

  /// Uniform integer in `[min, max]` (both inclusive).
  int nextRange(int min, int max) => min + nextInt(max - min + 1);

  /// Uniform double in `[0, 1)`.
  double nextDouble() => nextUint32() / 4294967296.0;

  bool nextBool([double probability = 0.5]) => nextDouble() < probability;

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  /// Fisher–Yates shuffle in place.
  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }

  static int _imul(int a, int b) => ((a & _mask) * (b & _mask)) & _mask;
}
