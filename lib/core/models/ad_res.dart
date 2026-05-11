import 'package:json_annotation/json_annotation.dart';

import 'clickable_resource.dart';

part 'ad_res.g.dart';

@JsonSerializable(checked: true)
class AdRes implements ClickableResource {
  final int? bannerCate;
  final String? img;
  @override
  final String? videoUrl; // 视频地址
  final int? gridId;
  @JsonKey(fromJson: _stringFromAny)
  final String id;
  final int fileType;
  @override
  final int? jumpCate; // 1 | 2 | 3 | 4; // 跳转类型: 1 - 无跳转 2 - 外部链接 3 - 跳转夺宝
  @override
  @JsonKey(fromJson: _nullableStringFromAny)
  final String? jumpUrl;
  final int? position; //1 | 2 | 3; // 1 左侧 2右上 3右下
  @override
  @JsonKey(fromJson: _nullableStringFromAny)
  final String? relatedTitleId;
  final int sortOrder;
  final int sortType; // 1 | 2; // 1:焦点排版 2:网格排版
  final int status; // 0 | 1; // 0关闭,1开启
  @JsonKey(fromJson: _bannerArrayFromAny)
  final List<BannerItem> bannerArray;

  AdRes({
    this.bannerCate,
    required this.img,
    required this.videoUrl,
    required this.gridId,
    required this.id,
    required this.jumpCate,
    required this.jumpUrl,
    this.position,
    required this.relatedTitleId,
    required this.sortOrder,
    required this.sortType,
    required this.status,
    this.bannerArray = const [],
    required this.fileType,
  });

  static String _stringFromAny(dynamic value) => value?.toString() ?? '';

  static String? _nullableStringFromAny(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<BannerItem> _bannerArrayFromAny(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  factory AdRes.fromJson(Map<String, dynamic> json) => _$AdResFromJson(json);

  Map<String, dynamic> toJson() => _$AdResToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class BannerItem {
  final int? gridId;
  @JsonKey(fromJson: AdRes._stringFromAny)
  final String img;
  final int imgStyleType;
  final String? videoUrl; // 视频地址
  final int jumpCate; // 1 | 2 | 3 | 4;
  @JsonKey(fromJson: AdRes._stringFromAny)
  final String jumpUrl;
  @JsonKey(fromJson: AdRes._nullableStringFromAny)
  final String? relatedTitleId;
  final int? sortOrder;
  final int? sortType; // 1 | 2; // 1:焦点排版 2:网格排版
  final int? position; // 1 | 2 | 3; // 1 左侧 2右上 3右下
  final int? status; // 1 | 2; // 1开启,2关闭,
  @JsonKey(fromJson: AdRes._stringFromAny)
  final String title;
  final int? validState;
  final String? blurhash;

  BannerItem({
    this.gridId,
    required this.img,
    required this.imgStyleType,
    this.videoUrl,
    required this.jumpCate,
    required this.jumpUrl,
    this.relatedTitleId,
    this.sortOrder,
    this.sortType,
    this.position,
    this.status,
    required this.title,
    this.validState,
    this.blurhash,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) =>
      _$BannerItemFromJson(json);

  Map<String, dynamic> toJson() => _$BannerItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
