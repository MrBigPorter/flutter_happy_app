import 'package:flutter/material.dart';
import '../../../components/share_sheet.dart';
import '../../../ui/modal/sheet/radix_sheet.dart';
import '../models/share_content.dart';
import '../index.dart';

class ShareManager {
  // 必须与服务器上的路径一致
  static const String _bridgeHost = "https://dev-api.joyminis.com/share.html";

  static void startShare(BuildContext context, ShareContent content) {
    // 1. 使用 Uri 安全拼装参数，确保 pid 和 gid 对应 HTML 脚本
    final uri = Uri.parse(_bridgeHost).replace(queryParameters: {
      'pid': content.id,
      if (content.groupId != null) 'gid': content.groupId,
    });

    final data = ShareData(
      title: content.title,
      text: content.desc,      // 使用业务层传入的动态文案
      url: uri.toString(),     // 生成的 H5 中转链接
      imageUrl: content.imageUrl,
    );

    // 2. 调起你的底层分享组件
    ShareService.openSystemOrSheet(
      data,
          () => RadixSheet.show(
        headerBuilder: (context) => SharePost(data: data),
        builder: (context, close) => ShareSheet(data: data),
      ),
    );
  }
}