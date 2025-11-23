// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdRes _$AdResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdRes', json, ($checkedConvert) {
      final val = AdRes(
        bannerCate: $checkedConvert('bannerCate', (v) => (v as num?)?.toInt()),
        img: $checkedConvert('img', (v) => v as String?),
        videoUrl: $checkedConvert('videoUrl', (v) => v as String?),
        gridId: $checkedConvert('gridId', (v) => (v as num?)?.toInt()),
        id: $checkedConvert('id', (v) => v as String),
        jumpCate: $checkedConvert('jumpCate', (v) => (v as num?)?.toInt()),
        jumpUrl: $checkedConvert('jumpUrl', (v) => v as String?),
        position: $checkedConvert('position', (v) => (v as num?)?.toInt()),
        relatedTitleId: $checkedConvert('relatedTitleId', (v) => v as String?),
        sortOrder: $checkedConvert('sortOrder', (v) => (v as num).toInt()),
        sortType: $checkedConvert('sortType', (v) => (v as num).toInt()),
        status: $checkedConvert('status', (v) => (v as num).toInt()),
        bannerArray: $checkedConvert(
          'bannerArray',
          (v) => (v as List<dynamic>?)
              ?.map((e) => BannerItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        fileType: $checkedConvert('fileType', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AdResToJson(AdRes instance) => <String, dynamic>{
  'bannerCate': instance.bannerCate,
  'img': instance.img,
  'videoUrl': instance.videoUrl,
  'gridId': instance.gridId,
  'id': instance.id,
  'fileType': instance.fileType,
  'jumpCate': instance.jumpCate,
  'jumpUrl': instance.jumpUrl,
  'position': instance.position,
  'relatedTitleId': instance.relatedTitleId,
  'sortOrder': instance.sortOrder,
  'sortType': instance.sortType,
  'status': instance.status,
  'bannerArray': instance.bannerArray,
};

BannerItem _$BannerItemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BannerItem',
  json,
  ($checkedConvert) {
    final val = BannerItem(
      gridId: $checkedConvert('gridId', (v) => (v as num?)?.toInt()),
      img: $checkedConvert('img', (v) => v as String),
      imgStyleType: $checkedConvert('imgStyleType', (v) => (v as num).toInt()),
      videoUrl: $checkedConvert('videoUrl', (v) => v as String?),
      jumpCate: $checkedConvert('jumpCate', (v) => (v as num).toInt()),
      jumpUrl: $checkedConvert('jumpUrl', (v) => v as String),
      relatedTitleId: $checkedConvert('relatedTitleId', (v) => v as String?),
      sortOrder: $checkedConvert('sortOrder', (v) => (v as num?)?.toInt()),
      sortType: $checkedConvert('sortType', (v) => (v as num?)?.toInt()),
      position: $checkedConvert('position', (v) => (v as num?)?.toInt()),
      status: $checkedConvert('status', (v) => (v as num?)?.toInt()),
      title: $checkedConvert('title', (v) => v as String),
      validState: $checkedConvert('validState', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
);

Map<String, dynamic> _$BannerItemToJson(BannerItem instance) =>
    <String, dynamic>{
      'gridId': instance.gridId,
      'img': instance.img,
      'imgStyleType': instance.imgStyleType,
      'videoUrl': instance.videoUrl,
      'jumpCate': instance.jumpCate,
      'jumpUrl': instance.jumpUrl,
      'relatedTitleId': instance.relatedTitleId,
      'sortOrder': instance.sortOrder,
      'sortType': instance.sortType,
      'position': instance.position,
      'status': instance.status,
      'title': instance.title,
      'validState': instance.validState,
    };
