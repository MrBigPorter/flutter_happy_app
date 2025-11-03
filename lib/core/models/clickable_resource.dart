
/// Description: ClickableResource model interface
abstract class ClickableResource {
  int? get jumpCate;
  String? get jumpUrl;
  String? get relatedTitleId;
  String? get videoUrl;
}

/// Default implementation of ClickableResource
class DefaultClickableResource implements ClickableResource {
  @override
  final int? jumpCate;
  @override
  final String? jumpUrl;
  @override
  final String? relatedTitleId;
  @override
  final String? videoUrl;
  DefaultClickableResource({
    this.jumpCate,
    this.jumpUrl,
    this.relatedTitleId,
    this.videoUrl,
  });


  /// Create a ClickableResource from a JSON map
  factory DefaultClickableResource.fromJson(Map<String, dynamic> json) {
    return DefaultClickableResource(
      jumpCate: json['jump_cate'] as int?,
      jumpUrl: json['jump_url'] as String?,
      relatedTitleId: json['related_title_id'] as String?,
      videoUrl: json['video_url'] as String?,
    );
  }
}