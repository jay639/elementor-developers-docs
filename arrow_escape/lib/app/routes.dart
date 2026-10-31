/// Route paths, in one place.
abstract final class Routes {
  static const splash = '/';
  static const home = '/home';
  static const settings = '/settings';
  static const daily = '/daily';
  static const map = '/map';
  static const collection = '/collection';
  static const shop = '/shop';
  static String game(int level) => '/game/$level';
  static String dailyGame(String dateKey) => '/daily/$dateKey';
  static String puzzleGame(String shape, int layer) => '/puzzle/$shape/$layer';
}
