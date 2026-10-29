/// Route paths, in one place.
abstract final class Routes {
  static const splash = '/';
  static const home = '/home';
  static const settings = '/settings';
  static String game(int level) => '/game/$level';
}
