import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImagePreviewPage extends StatelessWidget {
  final String imagePath;

  const ImagePreviewPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 照片展示
          Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),

          // 2. 底部操作栏
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //  Retake Button
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context, false); // 返回 false = 重拍
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                      "Retake",
                      style: TextStyle(color: Colors.white, fontSize: 16)
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),

                // ✅ Use Photo Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, true); // 返回 true = 确认
                  },
                  icon: const Icon(Icons.check, color: Colors.black),
                  label:  Text(
                      "Use Photo",
                      style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}