import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapLauncherService {

  /// 打开地图选择菜单
  static Future<void> openMap(
      BuildContext context, {
        required double lat,
        required double lng,
        required String title,
        String? address,
      }) async {
    try {
      // 1. 获取已安装地图
      final availableMaps = await MapLauncher.installedMaps;

      if (!context.mounted) return;

      if (availableMaps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No map apps installed.')),
        );
        return;
      }

      // 2. 弹出底部菜单
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        builder: (BuildContext ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Text(
                    "Open in Maps",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey[200]),

                // 3. 遍历地图列表
                ...availableMaps.map((map) {
                  return ListTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      map.showMarker(
                        coords: Coords(lat, lng),
                        title: title,
                        description: address,
                      );
                    },
                    // 核心修复：安全的图标构建器
                    leading: _buildSafeMapIcon(map.icon),
                    title: Text(
                      map.mapName,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  );
                }).toList(),

                Divider(height: 1, color: Colors.grey[200]),
                ListTile(
                  onTap: () => Navigator.pop(ctx),
                  title: Center(
                    child: Text(
                      "Cancel",
                      style: TextStyle(fontSize: 16.sp, color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Launch map error: $e");
    }
  }

  ///  安全构建图标的方法
  static Widget _buildSafeMapIcon(String svgString) {
    // 修复布局错误：强制限制宽高，防止 SVG 无限扩张挤崩 ListTile
    return SizedBox(
      width: 32.w,
      height: 32.w,
      child: Builder(
        builder: (context) {
          try {
            // map.icon 是一个 SVG 字符串，必须用 .string()
            return SvgPicture.string(
              svgString,
              width: 32.w,
              height: 32.w,
              // 如果 SVG 数据本身有问题，尝试显示 fallback
              placeholderBuilder: (_) => const Icon(Icons.map, color: Colors.grey),
            );
          } catch (e) {
            //  终极兜底：如果 SVG 解析直接报错 (Invalid SVG data)，显示默认图标
            debugPrint("SVG Parse Error: $e");
            return const Icon(Icons.map, color: Colors.blueGrey);
          }
        },
      ),
    );
  }
}