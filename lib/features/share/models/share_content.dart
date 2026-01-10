enum ShareContentType { product, group }

class ShareContent {
  final ShareContentType type;
  final String id;        // 商品 ID (pid)
  final String? groupId;  // 团 ID (gid)
  final String title;     // 标题
  final String imageUrl;  // 图片
  final String desc;      // 动态文案

  ShareContent._({
    required this.type,
    required this.id,
    this.groupId,
    required this.title,
    required this.imageUrl,
    required this.desc,
  });

  // 分享产品：只需传 ID 和文案
  factory ShareContent.product({
    required String id,
    required String title,
    required String imageUrl,
    required String desc,
  }) => ShareContent._(
    type: ShareContentType.product,
    id: id,
    title: title,
    imageUrl: imageUrl,
    desc: desc,
  );

  // 分享拼团：强制要求传 groupId
  factory ShareContent.group({
    required String id,
    required String groupId,
    required String title,
    required String imageUrl,
    required String desc,
  }) => ShareContent._(
    type: ShareContentType.group,
    id: id,
    groupId: groupId,
    title: title,
    imageUrl: imageUrl,
    desc: desc,
  );
}