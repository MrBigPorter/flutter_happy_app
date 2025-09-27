// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdRes _$AdResFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdRes',
  json,
  ($checkedConvert) {
    final val = AdRes(
      bannerCate: $checkedConvert('banner_cate', (v) => (v as num?)?.toInt()),
      img: $checkedConvert('img', (v) => v as String),
      videoUrl: $checkedConvert('video_url', (v) => v as String?),
      gridId: $checkedConvert('grid_id', (v) => (v as num).toInt()),
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      jumpCate: $checkedConvert('jump_cate', (v) => (v as num).toInt()),
      jumpUrl: $checkedConvert('jump_url', (v) => v as String),
      position: $checkedConvert('position', (v) => (v as num?)?.toInt()),
      relatedTitleId: $checkedConvert(
        'related_title_id',
        (v) => (v as num).toInt(),
      ),
      sortOrder: $checkedConvert('sort_order', (v) => (v as num).toInt()),
      sortType: $checkedConvert('sort_type', (v) => (v as num).toInt()),
      state: $checkedConvert('state', (v) => (v as num).toInt()),
      bannerArray: $checkedConvert(
        'banner_array',
        (v) => (v as List<dynamic>?)
            ?.map((e) => BannerItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'bannerCate': 'banner_cate',
    'videoUrl': 'video_url',
    'gridId': 'grid_id',
    'jumpCate': 'jump_cate',
    'jumpUrl': 'jump_url',
    'relatedTitleId': 'related_title_id',
    'sortOrder': 'sort_order',
    'sortType': 'sort_type',
    'bannerArray': 'banner_array',
  },
);

Map<String, dynamic> _$AdResToJson(AdRes instance) => <String, dynamic>{
  'banner_cate': instance.bannerCate,
  'img': instance.img,
  'video_url': instance.videoUrl,
  'grid_id': instance.gridId,
  'id': instance.id,
  'jump_cate': instance.jumpCate,
  'jump_url': instance.jumpUrl,
  'position': instance.position,
  'related_title_id': instance.relatedTitleId,
  'sort_order': instance.sortOrder,
  'sort_type': instance.sortType,
  'state': instance.state,
  'banner_array': instance.bannerArray,
};

BannerItem _$BannerItemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BannerItem',
  json,
  ($checkedConvert) {
    final val = BannerItem(
      activityAtStart: $checkedConvert(
        'activity_at_start',
        (v) => (v as num).toInt(),
      ),
      activityAtEnd: $checkedConvert(
        'activity_at_end',
        (v) => (v as num).toInt(),
      ),
      createdAt: $checkedConvert('created_at', (v) => (v as num).toInt()),
      createdBy: $checkedConvert('created_by', (v) => v as String),
      gridId: $checkedConvert('grid_id', (v) => (v as num).toInt()),
      img: $checkedConvert('img', (v) => v as String),
      imgStyleType: $checkedConvert(
        'img_style_type',
        (v) => (v as num).toInt(),
      ),
      videoUrl: $checkedConvert('video_url', (v) => v as String?),
      jumpCate: $checkedConvert('jump_cate', (v) => (v as num).toInt()),
      jumpUrl: $checkedConvert('jump_url', (v) => v as String),
      relatedTitleId: $checkedConvert(
        'related_title_id',
        (v) => (v as num).toInt(),
      ),
      sortOrder: $checkedConvert('sort_order', (v) => (v as num).toInt()),
      sortType: $checkedConvert('sort_type', (v) => (v as num).toInt()),
      startAt: $checkedConvert('start_at', (v) => (v as num).toInt()),
      position: $checkedConvert('position', (v) => (v as num?)?.toInt()),
      state: $checkedConvert('state', (v) => (v as num).toInt()),
      title: $checkedConvert('title', (v) => v as String),
      updatedAt: $checkedConvert('updated_at', (v) => (v as num).toInt()),
      updatedBy: $checkedConvert('updated_by', (v) => v as String),
      validState: $checkedConvert('valid_state', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'activityAtStart': 'activity_at_start',
    'activityAtEnd': 'activity_at_end',
    'createdAt': 'created_at',
    'createdBy': 'created_by',
    'gridId': 'grid_id',
    'imgStyleType': 'img_style_type',
    'videoUrl': 'video_url',
    'jumpCate': 'jump_cate',
    'jumpUrl': 'jump_url',
    'relatedTitleId': 'related_title_id',
    'sortOrder': 'sort_order',
    'sortType': 'sort_type',
    'startAt': 'start_at',
    'updatedAt': 'updated_at',
    'updatedBy': 'updated_by',
    'validState': 'valid_state',
  },
);

Map<String, dynamic> _$BannerItemToJson(BannerItem instance) =>
    <String, dynamic>{
      'activity_at_start': instance.activityAtStart,
      'activity_at_end': instance.activityAtEnd,
      'created_at': instance.createdAt,
      'created_by': instance.createdBy,
      'grid_id': instance.gridId,
      'img': instance.img,
      'img_style_type': instance.imgStyleType,
      'video_url': instance.videoUrl,
      'jump_cate': instance.jumpCate,
      'jump_url': instance.jumpUrl,
      'related_title_id': instance.relatedTitleId,
      'sort_order': instance.sortOrder,
      'sort_type': instance.sortType,
      'start_at': instance.startAt,
      'position': instance.position,
      'state': instance.state,
      'title': instance.title,
      'updated_at': instance.updatedAt,
      'updated_by': instance.updatedBy,
      'valid_state': instance.validState,
    };
