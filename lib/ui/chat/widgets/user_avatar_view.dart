
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// 推荐使用 cached_network_image
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatarView extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final String statusText; // "Calling...", "00:32"
  final bool isVoiceCall;  // 如果是纯语音，头像可以做得更大

  const UserAvatarView({
    super.key,
    required this.userName,
    this.avatarUrl,
    required this.statusText,
    this.isVoiceCall = false,
  });

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = isVoiceCall ? 80.r : 50.r;
    final double fontSize = isVoiceCall ? 28.sp : 24.sp;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头像
          Container(
            padding: EdgeInsets.all(4.w), // 头像白边
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.grey[800],
              backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(avatarUrl!)
                  : null,
              child: (avatarUrl == null || avatarUrl!.isEmpty)
                  ? Icon(Icons.person, size: avatarRadius, color: Colors.white54)
                  : null,
            ),
          ),

          SizedBox(height: 24.h),

          // 名字
          Text(
            userName,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(0, 2))
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // 状态
          Text(
            statusText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              shadows: [
                Shadow(blurRadius: 4, color: Colors.black54, offset: Offset(0, 1))
              ],
            ),
          ),
        ],
      ),
    );
  }
}