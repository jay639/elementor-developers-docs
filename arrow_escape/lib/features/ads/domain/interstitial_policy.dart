/// Frequency caps for interstitials. Values come from Remote Config.
class InterstitialConfig {
  const InterstitialConfig({
    this.minLevel = 10,
    this.levelGap = 3,
    this.minInterval = const Duration(minutes: 3),
  });

  /// No interstitial until this campaign level has been completed.
  final int minLevel;

  /// At least this many completed levels between interstitials…
  final int levelGap;

  /// …and at least this much time.
  final Duration minInterval;
}

/// Decides whether an interstitial may show after a completed level.
/// Interstitials are only ever offered after a level ends, never before
/// one starts.
class InterstitialPolicy {
  InterstitialPolicy(this._config);

  final InterstitialConfig Function() _config;
  DateTime? _lastShown;
  int _levelsSince = 0;

  InterstitialConfig get config => _config();

  /// Records a completed campaign level and says whether to show an ad now.
  bool onLevelCompleted(int level, DateTime now) {
    _levelsSince++;
    final c = config;
    if (level < c.minLevel) return false;
    // The first eligible ad still waits for a full gap of levels.
    if (_levelsSince < c.levelGap) return false;
    final last = _lastShown;
    if (last != null && now.difference(last) < c.minInterval) return false;
    return true;
  }

  void markShown(DateTime now) {
    _lastShown = now;
    _levelsSince = 0;
  }
}
