import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../components/skeleton.dart';
import '../../../theme/design_tokens.g.dart';

// ==============================================================================
// 1. Banner 骨架屏 (保持不变，这个已经很准了)
// ==============================================================================
class HomeBannerSkeleton extends StatelessWidget {
  const HomeBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Skeleton.react(
          width: double.infinity,
          height: 356.w, // 对应 Banner 高度
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }
}

// ==============================================================================
// 2. 列表内容骨架屏 (深度优化版)
// ==============================================================================
class HomeTreasureSkeleton extends StatelessWidget {
  const HomeTreasureSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 金刚区 (复刻 SpecialArea)
          const _SpecialAreaSkeleton(),
          SizedBox(height: 20.h),

          // 2. 横向滚动列表 (复刻 Ending)
          const _EndingSkeleton(),
          SizedBox(height: 20.h), // 原代码 Recommendation 上面有 22.h

          // 3. 竖向大图列表 (复刻 HomeFuture)
          const _HomeFutureSkeleton(),
          // HomeFuture 内部有 padding bottom 8.h，这里不需要额外大间距

          // 4. 双列网格 (复刻 Recommendation)
          const _RecommendationSkeleton(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------------
// 细节还原 1: SpecialArea (左图右文 + 进度条 + 底部价格按钮 + 分割线)
// ------------------------------------------------------------------------------
class _SpecialAreaSkeleton extends StatelessWidget {
  const _SpecialAreaSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: EdgeInsets.only(left: 16.w, top: 8.h, bottom: 8.h),
          child: Skeleton.react(width: 120.w, height: 20.h, borderRadius: BorderRadius.circular(4.r)),
        ),
        // 列表容器
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: List.generate(3, (index) {
              // 模拟圆角逻辑：第一个顶部圆角，最后一个底部圆角
              BorderRadius borderRadius = BorderRadius.zero;
              if (index == 0) {
                borderRadius = BorderRadius.only(topLeft: Radius.circular(8.r), topRight: Radius.circular(8.r));
              } else if (index == 2) {
                borderRadius = BorderRadius.only(bottomLeft: Radius.circular(8.r), bottomRight: Radius.circular(8.r));
              }

              return Container(
                padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 12.h),
                decoration: BoxDecoration(
                  color: context.bgPrimary,
                  borderRadius: borderRadius,
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 图片 80x80
                        Skeleton.react(width: 80.w, height: 80.w, borderRadius: BorderRadius.circular(8.r)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 标题 (2行高度模拟)
                              Skeleton.react(width: double.infinity, height: 14.h, borderRadius: BorderRadius.circular(2.r)),
                              SizedBox(height: 6.h),
                              Skeleton.react(width: 120.w, height: 14.h, borderRadius: BorderRadius.circular(2.r)),
                              SizedBox(height: 8.h),
                              // 进度条
                              Skeleton.react(width: double.infinity, height: 12.h, borderRadius: BorderRadius.circular(6.r)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    // 底部：价格 + 倒计时 + 按钮
                    Row(
                      children: [
                        // 价格列
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Skeleton.react(width: 30.w, height: 10.h),
                            SizedBox(height: 4.h),
                            Skeleton.react(width: 50.w, height: 14.h),
                          ],
                        ),
                        const Spacer(),
                        // 倒计时列
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Skeleton.react(width: 40.w, height: 10.h),
                            SizedBox(height: 4.h),
                            Skeleton.react(width: 60.w, height: 14.h),
                          ],
                        ),
                        const Spacer(),
                        // 按钮 (46.h)
                        Skeleton.react(width: 80.w, height: 46.h, borderRadius: BorderRadius.circular(23.r)),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // 分割线 (最后一行没有)
                    if (index < 2) Divider(height: 1.h, color: context.borderSecondary),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------------------
// 细节还原 2: Ending (横向列表，height 380.h)
// ------------------------------------------------------------------------------
class _EndingSkeleton extends StatelessWidget {
  const _EndingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Skeleton.react(width: 100.w, height: 20.h, borderRadius: BorderRadius.circular(4.r)),
        ),
        // 横向列表
        Container(
          height: 380.h, // 严格匹配 Ending height
          padding: EdgeInsets.only(top: 12.h),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              // 模拟 ProductItem (Vertical layout inside horizontal list)
              return Container(
                width: 165.w, // 假设 ProductItem 宽度约为屏幕一半减间距
                decoration: BoxDecoration(
                  color: context.bgPrimary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    // 上方大图
                    Skeleton.react(width: 165.w, height: 165.w, borderRadius: BorderRadius.vertical(top: Radius.circular(8.r))),
                    // 下方信息区
                    Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Skeleton.react(width: double.infinity, height: 14.h),
                          SizedBox(height: 4.h),
                          Skeleton.react(width: 100.w, height: 14.h),
                          SizedBox(height: 12.h),
                          Skeleton.react(width: double.infinity, height: 10.h), // 进度条
                          SizedBox(height: 20.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Skeleton.react(width: 40.w, height: 14.h), // 价格
                              Skeleton.react(width: 60.w, height: 30.h, borderRadius: BorderRadius.circular(15.r)), // 按钮
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------------------
// 细节还原 3: HomeFuture (VerticalAnimatedItem -> ProductCard)
// ------------------------------------------------------------------------------
class _HomeFutureSkeleton extends StatelessWidget {
  const _HomeFutureSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Skeleton.react(width: 150.w, height: 20.h, borderRadius: BorderRadius.circular(4.r)),
        ),
        // 竖向大卡片列表
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: List.generate(2, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Container(
                  height: 288.w, // 对应 ProductCard 的高度
                  decoration: BoxDecoration(
                    color: context.bgSecondary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Stack(
                    children: [
                      // 背景大图
                      Skeleton.react(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(8.r)),
                      // 底部浮层 (ProductInfoCard)
                      Positioned(
                        bottom: 6.w,
                        left: 6.w,
                        right: 6.w,
                        child: Container(
                          // 🔥 修复点：移除固定 height: 110.h，改用 padding 撑开
                          // height: 110.h, <--- 删掉这行
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3), // 模拟半透明
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton.react(width: 200.w, height: 16.h), // 标题
                              SizedBox(height: 15.h),
                              Skeleton.react(width: double.infinity, height: 12.h), // 进度条
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  Skeleton.react(width: 50.w, height: 20.h), // 价格
                                  const Spacer(),
                                  Skeleton.react(width: 80.w, height: 20.h), // 倒计时
                                  const Spacer(),
                                  Skeleton.react(width: 80.w, height: 36.w, borderRadius: BorderRadius.circular(18.w)), // 按钮
                                ],
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------------------
// 细节还原 4: Recommendation (GridView 双列)
// ------------------------------------------------------------------------------
class _RecommendationSkeleton extends StatelessWidget {
  const _RecommendationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Skeleton.react(width: 140.w, height: 20.h, borderRadius: BorderRadius.circular(4.r)),
        ),
        SizedBox(height: 15.h),
        // 双列 Grid
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左列
              Expanded(child: _buildGridColumn(context)),
              SizedBox(width: 10.w), // crossAxisSpacing
              // 右列
              Expanded(child: _buildGridColumn(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridColumn(BuildContext context) {
    // 模拟 item 高度: 380.h (宽高比 165/380)
    // imgHeight 165
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h), // mainAxisSpacing
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              // 1. 上方图片 (1:1 aspect ratio roughly)
              Skeleton.react(width: double.infinity, height: 165.w, borderRadius: BorderRadius.vertical(top: Radius.circular(8.r))),
              // 2. 下方内容
              Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.react(width: double.infinity, height: 14.h), // 标题行1
                    SizedBox(height: 4.h),
                    Skeleton.react(width: 80.w, height: 14.h), // 标题行2
                    SizedBox(height: 8.h),
                    Skeleton.react(width: double.infinity, height: 10.h), // 进度条
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Skeleton.react(width: 40.w, height: 14.h), // 价格
                        Skeleton.react(width: 60.w, height: 30.h, borderRadius: BorderRadius.circular(15.r)), // 按钮
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}