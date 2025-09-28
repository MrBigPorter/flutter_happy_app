import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';

import '../utils/helper.dart';
import '../utils/jump_helper.dart';

class HomeBanner extends StatefulWidget {
  final List<Banners> banners;
  final String? bannerID;
  final double height;
  final bool autoPlay;
  final Duration interval;

  const HomeBanner({
    super.key,
    required this.banners,
    this.bannerID,
    this.height = 356,
    this.autoPlay = true,
    this.interval = const Duration(seconds: 3),
  });

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  late final PageController _pc = PageController();
  int _index = 0;
  Timer? _timer;

  /// 初始化时设置计时器 setup timer on init
  @override
  void initState() {
    super.initState();
    _setupTimer();
  }

  /// 释放资源 dispose resources
  @override
  void dispose(){
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  /// 当 widget 更新时，检查是否需要重新设置计时器 when widget updated, check if need to reset timer
  @override
  void didUpdateWidget(HomeBanner oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.autoPlay != widget.autoPlay || oldWidget.interval != widget.interval || oldWidget.banners.length != widget.banners.length){
      _setupTimer();
    }
  }

  void _setupTimer() {
    _timer?.cancel();

    // 只有在需要自动轮播且条数>1时才启动
    if (!widget.autoPlay || widget.banners.length <= 1) return;

    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || widget.banners.isEmpty) return;

      final next = _index + 1;
      _pc.animateToPage(
        next >= widget.banners.length ? 0 : next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.banners;

    /// 无数据时显示占位图 show placeholder when no data
    if(items.isEmpty){
      return Container(
        height: widget.height,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgBrandPrimary,
          borderRadius: BorderRadius.circular(12)
        )
      );
    }

    /// 有数据时显示轮播图 show banner when have data
    return Container(
      key: widget.bannerID != null ? Key(widget.bannerID!) : null,
      margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox(
            width: double.infinity,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() {
                _index = i;
              }),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => JumHelper.handleTap(context, item),
                  child: Hero(
                    tag: 'banner_$i',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: proxied(item.bannerImgUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: widget.height,
                        placeholder: (_, __) => Skeleton.react(
                            width: double.infinity,
                            height: widget.height,
                            borderRadius: BorderRadius.circular(8)
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0x11000000),
                          alignment: Alignment.center,
                          child: Icon(CupertinoIcons.photo, size: 32, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: _Dots(
                count: items.length,
                index: _index,
                activeColor: context.buttonPrimaryBg,
                inactiveColor: context.bgActive
            ),
          ),
        ],
      ),
    );
  }
}

/// Dots indicator for banner
class _Dots extends StatelessWidget {
  final int count;
  final int index;
  final Color activeColor;
  final Color inactiveColor;

  const _Dots({
    required this.count,
    required this.index,
    required this.activeColor,
    required this.inactiveColor
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
