import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 建议添加，更丝滑

class GroupAvatar extends StatelessWidget {
  final List<String?> memberAvatars;
  final double size;
  final Color backgroundColor;

  const GroupAvatar({
    super.key,
    required this.memberAvatars,
    this.size = 50,
    this.backgroundColor = const Color(0xFFD0D0D0), // 稍微深一点的灰色，更有质感
  });

  @override
  Widget build(BuildContext context) {
    final count = min(memberAvatars.length, 9);
    final validAvatars = memberAvatars.take(count).toList();

    print('Building GroupAvatar with $count members.');

    if (count == 1) {
      return _buildSingleAvatar(validAvatars.first, size);
    }

    // 微信背景圆角较小，通常是 size * 0.1
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.1),
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        padding: EdgeInsets.all(size * 0.04), // 整体留白
        child: Stack(
          children: _buildChildren(validAvatars, size * 0.92), // 减去 padding 后的实际尺寸
        ),
      ),
    );
  }

  // --- 单人模式不变 ---
  Widget _buildSingleAvatar(String? url, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.1),
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: backgroundColor),
      )
          : Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: Icon(Icons.group, color: Colors.white, size: size * 0.6),
      ),
    );
  }

  List<Widget> _buildChildren(List<String?> avatars, double parentSize) {
    final count = avatars.length;
    final List<Widget> children = [];

    // 1. 确定行数配置 (WeChat Style 核心算法)
    List<int> rowConfig = [];
    if (count == 2) rowConfig = [2];
    else if (count == 3) rowConfig = [1, 2];
    else if (count == 4) rowConfig = [2, 2];
    else if (count == 5) rowConfig = [2, 3];
    else if (count == 6) rowConfig = [3, 3];
    else if (count == 7) rowConfig = [1, 3, 3];
    else if (count == 8) rowConfig = [2, 3, 3];
    else if (count == 9) rowConfig = [3, 3, 3];

    int rowCount = rowConfig.length;

    // 2. 计算小头像尺寸
    // 微信规律：4人及以下用大一点的图，5人以上用小图
    double itemSize;
    double itemGap = parentSize * 0.03; // 头像间距
    if (count <= 4) {
      itemSize = (parentSize - itemGap) / 2;
    } else {
      itemSize = (parentSize - itemGap * 2) / 3;
    }

    // 3. 垂直居中偏移
    double totalHeight = rowCount * itemSize + (rowCount - 1) * itemGap;
    double yOffset = (parentSize - totalHeight) / 2;

    int index = 0;
    for (int rowItems in rowConfig) {
      // 每一行水平居中偏移
      double rowWidth = rowItems * itemSize + (rowItems - 1) * itemGap;
      double xOffset = (parentSize - rowWidth) / 2;

      for (int i = 0; i < rowItems; i++) {
        if (index >= count) break;
        children.add(Positioned(
          left: xOffset + i * (itemSize + itemGap),
          top: yOffset,
          child: _buildItem(avatars[index], itemSize),
        ));
        index++;
      }
      yOffset += itemSize + itemGap; // 下一行
    }

    return children;
  }

  Widget _buildItem(String? url, double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.white, // 间隙背景色
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
      )
          : Icon(Icons.person, size: size * 0.8, color: Colors.grey[400]),
    );
  }
}