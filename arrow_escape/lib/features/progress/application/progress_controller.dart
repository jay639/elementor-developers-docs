import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only view of campaign + daily progress inside the save.
final progressProvider = Provider<Progress>(
  (ref) => ref.watch(saveProvider.select((s) => s.progress)),
);
