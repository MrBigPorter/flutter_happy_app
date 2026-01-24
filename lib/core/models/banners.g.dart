// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banners.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Banners _$BannersFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Banners',
      json,
      ($checkedConvert) {
        final val = Banners(
          id: $checkedConvert('id', (v) => v as String),
          bannerCate:
              $checkedConvert('bannerCate', (v) => (v as num?)?.toInt()),
          bannerImgUrl: $checkedConvert('bannerImgUrl', (v) => v as String),
          videoUrl: $checkedConvert('videoUrl', (v) => v as String?),
          jumpCate: $checkedConvert('jumpCate', (v) => (v as num).toInt()),
          relatedTitleId:
              $checkedConvert('relatedTitleId', (v) => v as String?),
          state: $checkedConvert('state', (v) => (v as num).toInt()),
          sortOrder: $checkedConvert('sortOrder', (v) => (v as num).toInt()),
          jumpUrl: $checkedConvert('jumpUrl', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$BannersToJson(Banners instance) => <String, dynamic>{
      'id': instance.id,
      'bannerCate': instance.bannerCate,
      'bannerImgUrl': instance.bannerImgUrl,
      'videoUrl': instance.videoUrl,
      'jumpCate': instance.jumpCate,
      'relatedTitleId': instance.relatedTitleId,
      'state': instance.state,
      'sortOrder': instance.sortOrder,
      'jumpUrl': instance.jumpUrl,
    };
