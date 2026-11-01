// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SaveData _$SaveDataFromJson(Map<String, dynamic> json) => _SaveData(
  progress: json['progress'] == null
      ? const Progress()
      : Progress.fromJson(json['progress'] as Map<String, dynamic>),
  coins: (json['coins'] as num?)?.toInt() ?? 0,
  ownedSkins:
      (json['ownedSkins'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>['classic'],
  selectedSkin: json['selectedSkin'] as String? ?? 'classic',
  streak: (json['streak'] as num?)?.toInt() ?? 0,
  lastWinDay: json['lastWinDay'] as String?,
  rewardStreak: (json['rewardStreak'] as num?)?.toInt() ?? 0,
  lastRewardDay: json['lastRewardDay'] as String?,
  settings: json['settings'] == null
      ? const AppSettings()
      : AppSettings.fromJson(json['settings'] as Map<String, dynamic>),
  claimedBundles:
      (json['claimedBundles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  levelAttempts:
      (json['levelAttempts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
  seenTips:
      (json['seenTips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  reviewAsks:
      (json['reviewAsks'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  lastReviewLevel: (json['lastReviewLevel'] as num?)?.toInt() ?? 0,
  cloudSynced: json['cloudSynced'] as bool? ?? false,
  revision: (json['revision'] as num?)?.toInt() ?? 0,
  updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SaveDataToJson(_SaveData instance) => <String, dynamic>{
  'progress': instance.progress,
  'coins': instance.coins,
  'ownedSkins': instance.ownedSkins,
  'selectedSkin': instance.selectedSkin,
  'streak': instance.streak,
  'lastWinDay': instance.lastWinDay,
  'rewardStreak': instance.rewardStreak,
  'lastRewardDay': instance.lastRewardDay,
  'settings': instance.settings,
  'claimedBundles': instance.claimedBundles,
  'levelAttempts': instance.levelAttempts,
  'seenTips': instance.seenTips,
  'reviewAsks': instance.reviewAsks,
  'lastReviewLevel': instance.lastReviewLevel,
  'cloudSynced': instance.cloudSynced,
  'revision': instance.revision,
  'updatedAt': instance.updatedAt,
};
