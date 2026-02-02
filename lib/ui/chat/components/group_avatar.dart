import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'default_group_avatar.dart';

class GroupAvatar extends StatelessWidget {
  /// 后端合成后的完整 URL (对应数据库中的 groupAvatar 或 avatar 字段)
  final String? avatarUrl;

  /// 成员数量：用于在 URL 为空时绘制对应的灰色九宫格骨架
  final int memberCount;

  final double size;

  const GroupAvatar({
    super.key,
    this.avatarUrl,
    required this.memberCount,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 准备缺省占位组件（骨架屏）
    final placeholder = DefaultGroupAvatar(
      count: memberCount,
      size: size,
    );

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        // 保持圆角风格一致，15% 是比较接近微信的圆角比例
        borderRadius: BorderRadius.circular(size * 0.15),
        child: _buildAvatarImage(placeholder),
      ),
    );
  }

  Widget _buildAvatarImage(Widget placeholder) {
    // 如果 URL 根本不存在（后端还没开始合成），直接展示骨架
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return placeholder;
    }

    // 使用 CachedNetworkImage 进行高效缓存和异步加载
    return CachedNetworkImage(
      imageUrl: avatarUrl!,
      fit: BoxFit.cover,
      // 加载时的占位图：即九宫格骨架
      placeholder: (context, url) => placeholder,
      // 加载失败（比如 404 或 R2 还没同步过去）回退到骨架
      errorWidget: (context, url, error) => placeholder,
      // 淡入效果，体验更丝滑
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}