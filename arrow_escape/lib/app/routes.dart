/// Route paths, in one place.
abstract final class Routes {
  static const splash = '/';
  static const home = '/home';
  static const settings = '/settings';
  static const daily = '/daily';
  static String game(int level) => '/game/$level';
  static String dailyGame(String dateKey) => '/daily/$dateKey';
}
