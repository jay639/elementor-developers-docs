/// Which pieces are still on the board, plus how many have exited (the exit
/// count drives traffic-light parity). Immutable and cheap to hash, because
/// the solver stores millions of these.
class BoardState {
  BoardState._(this._words, this.exits, this.remainingCount);

  /// Every piece of a level with [pieceCount] pieces on the board.
  factory BoardState.initial(int pieceCount) {
    final words = List<int>.filled(_wordCount(pieceCount), 0);
    for (var i = 0; i < pieceCount; i++) {
      words[i ~/ _bits] |= 1 << (i % _bits);
    }
    return BoardState._(List.unmodifiable(words), 0, pieceCount);
  }

  // 30 bits per word keeps every word a small integer on all platforms.
  static const _bits = 30;
  static int _wordCount(int n) => (n + _bits - 1) ~/ _bits;

  final List<int> _words;
  final int exits;
  final int remainingCount;

  bool get isCleared => remainingCount == 0;

  bool isOnBoard(int piece) =>
      (_words[piece ~/ _bits] >> (piece % _bits)) & 1 == 1;

  /// State after [piece] has driven off the board.
  BoardState without(int piece) {
    assert(isOnBoard(piece), 'piece $piece already exited');
    final words = List<int>.of(_words);
    words[piece ~/ _bits] &= ~(1 << (piece % _bits));
    return BoardState._(
      List.unmodifiable(words),
      exits + 1,
      remainingCount - 1,
    );
  }

  Iterable<int> get remaining sync* {
    for (var w = 0; w < _words.length; w++) {
      var word = _words[w];
      var bit = 0;
      while (word != 0) {
        if (word & 1 == 1) yield w * _bits + bit;
        word >>= 1;
        bit++;
      }
    }
  }

  /// Key that ignores the exit count except for its parity, which is all
  /// the rules can observe.
  String get solverKey => '${_words.join(',')}|${exits & 1}';

  @override
  bool operator ==(Object other) {
    if (other is! BoardState || other.exits != exits) return false;
    for (var i = 0; i < _words.length; i++) {
      if (other._words[i] != _words[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(exits, Object.hashAll(_words));
}
