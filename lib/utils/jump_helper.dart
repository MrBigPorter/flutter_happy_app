import 'package:web/web.dart' as web;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../core/models/clickable_resource.dart';


class JumHelper {
  static Future<void> handleTap(BuildContext context, ClickableResource item) async {
      final jump = item.jumpCate ?? 1;

      // outer link 外部链接
      if(jump == 2 && item.jumpUrl!.isNotEmpty ){
        final url = item.jumpUrl!;
        if(kIsWeb){
          // web 端直接打开新标签页 open in new tab on web
          web.window.open(url, '_blank');
        } else {
          // 移动端用浏览器打开 open in browser on mobile
          if (await canLaunchUrlString(url)) {
            await launchUrlString(url, mode: LaunchMode.externalApplication);
          } else {
            throw 'Could not launch $url';
          }
        }
      }

      // 统一的跳转逻辑
      if (item.relatedTitleId != null) {
        // jumpCate = 4 新人活动
        if (jump == 4) {
          AppRouter.router.push('/new-user-promo?coupon_id=${item.relatedTitleId}');
          return;
        }

        // jumpCate = 5 其它映射，暂时也指向 product
        if (jump == 5) {
          AppRouter.router.push('/product/${item.relatedTitleId}');
          return;
        }

        // 兜底：只要有 relatedTitleId 默认进产品页
        AppRouter.router.push('/product/${item.relatedTitleId}');
        return;
      }

      if(item.videoUrl!.isNotEmpty) {
        debugPrint('Play video: ${item.videoUrl!}');
        // Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(video
      }
  }
}