import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/routes/app_router.dart';

import '../core/models/clickable_resource.dart';


class JumHelper {
  static Future<void> handleTap(BuildContext context, ClickableResource item) async {
      final jump = item.jumpCate ?? 1;

      // outer link 外部链接
      // 外部链接：所有平台一套写法
      if (jump == 2 && (item.jumpUrl?.isNotEmpty ?? false)) {
        final uri = Uri.parse(item.jumpUrl!);
        final ok = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,   // 移动端用系统浏览器
          webOnlyWindowName: '_blank',           // Web 打开新标签页
        );
        if (!ok) {
          throw 'Could not launch $uri';
        }
      }

      // 统一的跳转逻辑
      if (item.relatedTitleId != null) {
        // jumpCate = 4 新人活动
        if (jump == 4) {
          appRouter.go('/new-user-promo?coupon_id=${item.relatedTitleId}');
          return;
        }

        // jumpCate = 5 其它映射，暂时也指向 product
        if (jump == 5) {
          appRouter.go('/product/${item.relatedTitleId}');
          return;
        }

        // 兜底：只要有 relatedTitleId 默认进产品页
        appRouter.go('/product/${item.relatedTitleId}');
        return;
      }

      if(item.videoUrl!.isNotEmpty) {
        debugPrint('Play video: ${item.videoUrl!}');
        // Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(video
      }
  }
}