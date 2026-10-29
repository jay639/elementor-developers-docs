/// Small deterministic PRNG (xorshift128 on 32-bit lanes).
///
/// `dart:math`'s `Random(seed)` is not guaranteed to produce the same
/// sequence across SDK versions or platforms. The daily challenge must be
/// identical for every player, so generation uses this instead.
class Rng {
  Rng(int seed) {
    // SplitMix-style scrambling so nearby seeds diverge immediately.
    var z = seed & _mask;
    int next() {
      z = (z + 0x9E3779B9) & _mask;
      var t = z;
      t = ((t ^ (t >> 16)) * 0x85EBCA6B) & _mask;
      t = ((t ^ (t >> 13)) * 0xC2B2AE35) & _mask;
      return (t ^ (t >> 16)) & _mask;
    }

    _x = next();
    _y = next();
    _z = next();
    _w = next() | 1; // never all-zero
  }

  static const _mask = 0xFFFFFFFF;

  late int _x;
  late int _y;
  late int _z;
  late int _w;

  /// Next 32-bit unsigned value.
  int nextUint32() {
    final t = (_x ^ (_x << 11)) & _mask;
    _x = _y;
    _y = _z;
    _z = _w;
    _w = (_w ^ (_w >> 19) ^ t ^ (t >> 8)) & _mask;
    return _w;
  }

  /// Uniform integer in `[0, max)`.
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max', 'must be positive');
    return nextUint32() % max;
  }

  /// Uniform double in `[0, 1)`.
  double nextDouble() => nextUint32() / 4294967296.0;

  bool nextBool([double chance = 0.5]) => nextDouble() < chance;

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }
}

/// Stable 32-bit FNV-1a hash (String.hashCode is not stable across runs).
int stableHash(String s) {
  var h = 0x811C9DC5;
  for (final unit in s.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// Natural log using only `+ - * /`, which IEEE 754 makes bit-identical on
/// every platform. `dart:math`'s `log` comes from the platform's libm and
/// may differ in the last bit between Android and iOS, which could make the
/// daily challenge differ between players.
double detLn(double x) {
  if (x <= 0 || x.isNaN) throw ArgumentError.value(x, 'x', 'must be > 0');
  if (x.isInfinite) return x;
  // Bring x into [1, 2) with exact power-of-two scaling.
  var e = 0;
  var m = x;
  while (m >= 2) {
    m /= 2;
    e++;
  }
  while (m < 1) {
    m *= 2;
    e--;
  }
  // ln(m) = 2 * atanh(z), z = (m - 1) / (m + 1), |z| < 1/3.
  final z = (m - 1) / (m + 1);
  final z2 = z * z;
  var term = z;
  var sum = 0.0;
  for (var k = 1; k < 60; k += 2) {
    sum += term / k;
    term *= z2;
  }
  const ln2 = 0.6931471805599453;
  return 2 * sum + e * ln2;
}
