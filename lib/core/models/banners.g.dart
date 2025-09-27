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
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      bannerCate: $checkedConvert('banner_cate', (v) => (v as num?)?.toInt()),
      bannerImgUrl: $checkedConvert('banner_img_url', (v) => v as String),
      videoUrl: $checkedConvert('video_url', (v) => v as String?),
      jumpCate: $checkedConvert('jump_cate', (v) => (v as num).toInt()),
      relatedTitleId: $checkedConvert(
        'related_title_id',
        (v) => (v as num).toInt(),
      ),
      state: $checkedConvert('state', (v) => (v as num).toInt()),
      sortOrder: $checkedConvert('sort_order', (v) => (v as num).toInt()),
      jumpUrl: $checkedConvert('jump_url', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'bannerCate': 'banner_cate',
    'bannerImgUrl': 'banner_img_url',
    'videoUrl': 'video_url',
    'jumpCate': 'jump_cate',
    'relatedTitleId': 'related_title_id',
    'sortOrder': 'sort_order',
    'jumpUrl': 'jump_url',
  },
);

Map<String, dynamic> _$BannersToJson(Banners instance) => <String, dynamic>{
  'id': instance.id,
  'banner_cate': instance.bannerCate,
  'banner_img_url': instance.bannerImgUrl,
  'video_url': instance.videoUrl,
  'jump_cate': instance.jumpCate,
  'related_title_id': instance.relatedTitleId,
  'state': instance.state,
  'sort_order': instance.sortOrder,
  'jump_url': instance.jumpUrl,
};
