import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';

class GroupAvatar extends StatelessWidget {
  /// 后端合成后的完整 URL
  final String? avatarUrl;

  /// 头像尺寸
  final double size;

  const GroupAvatar({
    super.key,
    this.avatarUrl,
    this.size = 50, // 默认大小
  });

  @override
  Widget build(BuildContext context) {
    // 1. 准备一个轻量级的默认占位组件
    // 不再调用复杂的 DefaultGroupAvatar，直接给一个简单的背景+图标
    final placeholder = Container(
      width: size,
      height: size,
      color: context.bgSecondary, // 使用主题次级背景色
      child: Icon(
        Icons.groups_rounded,
        size: size * 0.5,
        color: context.textSecondary700.withOpacity(0.5),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        // 保持圆角风格一致 (15% 比例)
        borderRadius: BorderRadius.circular(size * 0.15),
        child: _buildAvatarImage(placeholder),
      ),
    );
  }

  Widget _buildAvatarImage(Widget placeholder) {
    // 如果 URL 为空，直接展示占位图
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return placeholder;
    }

    // 使用 CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: avatarUrl!,
      fit: BoxFit.cover,
      // 加载中、失败、或为空时，统一使用简单的占位图
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => placeholder,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}