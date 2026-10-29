import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current local time. Overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
