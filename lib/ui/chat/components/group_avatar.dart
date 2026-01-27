import 'dart:math';
import 'package:flutter/material.dart';

/// 九宫格群头像组件
class GroupAvatar extends StatelessWidget {
  final List<String?> memberAvatars; // 头像 URL 列表
  final double size; // 控件整体大小
  final Color backgroundColor;

  const GroupAvatar({
    super.key,
    required this.memberAvatars,
    this.size = 50, // 默认大小
    this.backgroundColor = const Color(0xFFE0E0E0), // 默认浅灰背景
  });

  @override
  Widget build(BuildContext context) {
    // 1. 截取前9个，避免溢出
    final count = min(memberAvatars.length, 9);
    final validAvatars = memberAvatars.take(count).toList();

    // 2. 如果只有1个人，直接显示大图 (优化性能)
    if (count == 1) {
      return _buildSingleAvatar(validAvatars.first, size);
    }

    // 3. 多人组合模式
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.04), // 内部微小边距
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.15), // 圆角
      ),
      child: Stack(
        children: _buildChildren(validAvatars, size),
      ),
    );
  }

  // 构建单个大头像
  Widget _buildSingleAvatar(String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.15),
        color: backgroundColor,
        image: (url != null && url.isNotEmpty)
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: (url == null || url.isEmpty)
          ? Icon(Icons.group, color: Colors.white, size: size * 0.5)
          : null,
    );
  }

  // 计算九宫格布局
  List<Widget> _buildChildren(List<String?> avatars, double parentSize) {
    final count = avatars.length;
    final List<Widget> children = [];

    // ------------------------------------------------
    // 核心算法：根据人数决定 列数(column) 和 行数(row)
    // ------------------------------------------------
    int rowCount = 1;
    if (count > 4) {
      rowCount = 3; // 5-9人：3行
    } else if (count > 1) {
      rowCount = 2; // 2-4人：2行
    }

    // 计算单个小头像的大小 (除去间隙)
    // 间隙设为头像大小的 10%
    // 公式：Size = (ParentSize - (row + 1) * gap) / row
    // 这里简化计算，直接按比例给
    double itemSize;
    if (rowCount == 1) itemSize = parentSize;
    else if (rowCount == 2) itemSize = parentSize * 0.45; // 2行模式，大约占45%
    else itemSize = parentSize * 0.30; // 3行模式，大约占30%

    // 间隙
    final gap = (parentSize - (itemSize * 3)) / 4; // 按3列算的通用间隙

    // ------------------------------------------------
    // 布局生成器 (WeChat Style)
    // ------------------------------------------------
    // 每一行的起始 Y 坐标
    double yOffset = 0;

    // 垂直居中修正：如果内容不足以填满容器，上下留白
    if (rowCount == 2) yOffset = (parentSize - itemSize * 2 - gap) / 2;
    if (rowCount == 3) yOffset = (parentSize - itemSize * 3 - gap * 2) / 2;

    // 当前处理到第几个头像
    int index = 0;

    // 逐行布局
    // 3行模式通常是：
    // 5人: 2 (居中) + 3
    // 6人: 3 + 3
    // 7人: 1 (居中) + 3 + 3
    // 8人: 2 (居中) + 3 + 3
    // 9人: 3 + 3 + 3

    // 这里我们使用一个简化的通用逻辑：
    // 2-4人：第一行和第二行根据数量平分
    // 5-9人：优先填满最后一行，倒推

    // 为了代码简洁，我们使用硬编码的“每行数量配置”
    List<int> rowConfig = [];
    if (count == 2) rowConfig = [2]; // 特殊处理：2人其实是一行，但要垂直居中
    else if (count == 3) rowConfig = [1, 2];
    else if (count == 4) rowConfig = [2, 2];
    else if (count == 5) rowConfig = [2, 3];
    else if (count == 6) rowConfig = [3, 3];
    else if (count == 7) rowConfig = [1, 3, 3];
    else if (count == 8) rowConfig = [2, 3, 3];
    else if (count == 9) rowConfig = [3, 3, 3];

    for (int rowItems in rowConfig) {
      // 计算当前行的 X 轴起始偏移量 (为了水平居中)
      // 3列模式的总宽度 = itemSize * 3 + gap * 2
      // 当前行宽度 = itemSize * rowItems + gap * (rowItems - 1)
      double rowWidth = itemSize * rowItems + 2 * (rowItems - 1); // 2是微调间隙
      double xOffset = (parentSize - rowWidth) / 2;

      for (int i = 0; i < rowItems; i++) {
        if (index >= count) break;

        children.add(Positioned(
          left: xOffset + (itemSize + 2) * i, // 2是微调间隙
          top: yOffset,
          child: _buildItem(avatars[index], itemSize),
        ));
        index++;
      }
      // 换行，更新Y
      yOffset += itemSize + 2;
    }

    return children;
  }

  Widget _buildItem(String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300], // 占位色
        borderRadius: BorderRadius.circular(2), // 微小圆角
        image: (url != null && url.isNotEmpty)
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: (url == null || url.isEmpty)
          ? Center(child: Icon(Icons.person, size: size * 0.6, color: Colors.white))
          : null,
    );
  }
}