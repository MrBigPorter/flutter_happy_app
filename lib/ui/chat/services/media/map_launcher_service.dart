import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapLauncherService {

  static Future<void> openMap(
      BuildContext context, {
        required double lat,
        required double lng,
        required String title,
        String? address,
      }) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;

      if (!context.mounted) return;

      if (availableMaps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No map apps installed.')),
        );
        return;
      }

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
                    //  核心修改：不再解析 SVG，而是用安全的本地映射
                    leading: _buildMapIconByMapType(map.mapType),
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

  ///  根据地图类型手动返回漂亮的图标
  static Widget _buildMapIconByMapType(MapType type) {
    // 定义一个默认大小
    final double size = 32.w;

    IconData iconData;
    Color color;

    // 根据不同地图给不同的颜色和图标
    switch (type) {
      case MapType.google:
        iconData = Icons.location_on;
        color = Colors.red; // Google 地图经典红
        break;
      case MapType.apple:
        iconData = Icons.map;
        color = Colors.green; // Apple 地图经典绿
        break;
      case MapType.amap: // 高德
        iconData = Icons.navigation;
        color = Colors.blue;
        break;
      case MapType.baidu:
        iconData = Icons.near_me;
        color = Colors.indigo;
        break;
      case MapType.waze:
        iconData = Icons.directions_car;
        color = Colors.lightBlue;
        break;
      default:
        iconData = Icons.map_outlined;
        color = Colors.grey;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // 浅色背景
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 20.w,
      ),
    );
  }
}