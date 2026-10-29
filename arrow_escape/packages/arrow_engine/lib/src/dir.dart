/// The four directions a vehicle can face. Screen coordinates: +y is down.
enum Dir {
  up(0, -1),
  right(1, 0),
  down(0, 1),
  left(-1, 0);

  const Dir(this.dx, this.dy);

  final int dx;
  final int dy;

  Dir get opposite => Dir.values[(index + 2) % 4];
  Dir get clockwise => Dir.values[(index + 1) % 4];
  Dir get counterClockwise => Dir.values[(index + 3) % 4];

  bool get isHorizontal => dy == 0;

  /// Compact single-letter code used in level JSON.
  String get code => const ['u', 'r', 'd', 'l'][index];

  static Dir fromCode(String code) {
    switch (code) {
      case 'u':
        return Dir.up;
      case 'r':
        return Dir.right;
      case 'd':
        return Dir.down;
      case 'l':
        return Dir.left;
    }
    throw FormatException('Unknown direction code "$code"');
  }

  /// Direction from [from] to an orthogonally adjacent [to], or null.
  static Dir? between(int fromX, int fromY, int toX, int toY) {
    final dx = toX - fromX;
    final dy = toY - fromY;
    for (final d in Dir.values) {
      if (d.dx == dx && d.dy == dy) return d;
    }
    return null;
  }
}
