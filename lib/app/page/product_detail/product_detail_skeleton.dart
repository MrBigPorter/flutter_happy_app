import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/common.dart';

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Skeleton.react(width: double.infinity, height: 276.w, borderRadius: BorderRadius.zero),
            SizedBox(height: 20.w),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Skeleton.react(width: double.infinity, height: 200.w, borderRadius: BorderRadius.circular(8.w)),
            ),
            SizedBox(height: 20.w),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Skeleton.react(width: double.infinity, height: 100.w, borderRadius: BorderRadius.circular(8.w)),
            ),
          ],
        ),
      ),
    );
  }
}