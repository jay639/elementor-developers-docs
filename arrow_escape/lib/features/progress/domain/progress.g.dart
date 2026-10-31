// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Progress _$ProgressFromJson(Map<String, dynamic> json) => _Progress(
  unlocked: (json['unlocked'] as num?)?.toInt() ?? 1,
  stars:
      (json['stars'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ) ??
      const <int, int>{},
  dailyStars:
      (json['dailyStars'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
  puzzleStars:
      (json['puzzleStars'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
);

Map<String, dynamic> _$ProgressToJson(_Progress instance) => <String, dynamic>{
  'unlocked': instance.unlocked,
  'stars': instance.stars.map((k, e) => MapEntry(k.toString(), e)),
  'dailyStars': instance.dailyStars,
  'puzzleStars': instance.puzzleStars,
};
