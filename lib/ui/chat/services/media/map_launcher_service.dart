import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncherService {
  /// Opens the map application for a specific coordinate.
  /// Handles Web-specific URL redirection and Native-specific app selection.
  static Future<void> openMap(
      BuildContext context, {
        required double lat,
        required double lng,
        required String title,
        String? address,
      }) async {
    try {
      // --- Web Specific Implementation: Redirect to Google Maps Web ---
      if(kIsWeb){
        // Constructs the Google Maps search URL with latitude and longitude.
        final Uri googleMapUrl = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
        );

        // Launch via the browser application.
        if(await canLaunchUrl(googleMapUrl)){
          await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
        } else {
          if(!context.mounted) return;
          RadixToast.info("Could not launch map URL.");
        }
        return;
      }

      // --- Native Implementation (Android/iOS): Invoke installed map apps ---
      final availableMaps = await MapLauncher.installedMaps;

      if (!context.mounted) return;

      if (availableMaps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No map apps installed.')),
        );
        return;
      }

      // Present a BottomSheet for the user to choose their preferred map application.
      showModalBottomSheet(
        context: context,
        backgroundColor: context.bgPrimary,
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
                      color: context.textPrimary900,
                    ),
                  ),
                ),
                Divider(height: 1, color: context.borderPrimary),

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
                    // Visual Optimization: Uses safe local icon mapping instead of SVG parsing.
                    leading: _buildMapIconByMapType(map.mapType),
                    title: Text(
                      map.mapName,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  );
                }).toList(),

                Divider(height: 1, color: context.borderPrimary),
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
      debugPrint("[MapLauncherService] Launch error: $e");
    }
  }

  /// Generates a standardized UI icon based on the specific MapType.
  static Widget _buildMapIconByMapType(MapType type) {
    final double size = 32.w;

    IconData iconData;
    Color color;

    // Assign branding colors and icons based on the map provider type.
    switch (type) {
      case MapType.google:
        iconData = Icons.location_on;
        color = Colors.red;
        break;
      case MapType.apple:
        iconData = Icons.map;
        color = Colors.green;
        break;
      case MapType.amap:
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
        color: color.withOpacity(0.1),
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