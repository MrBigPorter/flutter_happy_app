import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter_app/ui/chat/services/avatar/group_avatar_service.dart';
// 1. 引入刚才写的缺省组件
import 'default_group_avatar.dart';

class GroupAvatar extends StatefulWidget {
  final List<String> memberAvatars;
  final double size;

  const GroupAvatar({
    super.key,
    required this.memberAvatars,
    this.size = 50
  });

  @override
  State<GroupAvatar> createState() => _GroupAvatarState();
}

class _GroupAvatarState extends State<GroupAvatar> {
  Future<Uint8List?>? _avatarFuture;

  @override
  void didUpdateWidget(covariant GroupAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有成员列表变了才重新生成
    if (!listEquals(oldWidget.memberAvatars, widget.memberAvatars)) {
      _avatarFuture = GroupAvatarService.getOrGenerateGroupAvatar(widget.memberAvatars);
    }
  }

  @override
  void initState() {
    super.initState();
    _avatarFuture = GroupAvatarService.getOrGenerateGroupAvatar(widget.memberAvatars);
  }

  @override
  Widget build(BuildContext context) {
    // 2. 准备缺省占位组件
    final placeholder = DefaultGroupAvatar(
      count: widget.memberAvatars.length,
      size: widget.size,
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<Uint8List?>(
          future: _avatarFuture,
          builder: (context, snapshot) {
            // 1. 成功且有数据
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                gaplessPlayback: true, // 防止闪烁
                // 如果图片解码出错，也回退到缺省图
                errorBuilder: (ctx, err, stack) => placeholder,
              );
            }

            // 2. Loading, Error, 或数据为 null -> 显示缺省骨架
            return placeholder;
          },
        ),
      ),
    );
  }
}