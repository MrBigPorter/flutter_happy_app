import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';



class SwiperBanner<T> extends StatelessWidget {
  final List<T> banners;
  final String? bannerID;
  final double height;
  final double width;
  final bool showIndicator;
  final Duration interval;
  final bool autoPlay;
  final double borderRadius;
  final Function(T item)? onTapItem;
  final Widget Function(T item)? itemBuilder;

  // dots
  final double dotSize;
  final double activeDotSize;
  final Color? dotColor;
  final Color? activeDotColor;
  final double dotSpace;
  final double dotBorderRadius;
  final void Function(int index)? onIndexChanged;

  final SwiperController? controller;
  final Key? storageKey;

  const SwiperBanner({
    super.key,
    required this.banners,
    this.bannerID,
    this.height = 356,
    this.width = double.infinity,
    this.showIndicator = true,
    this.autoPlay = true,
    this.interval = const Duration(seconds: 3),
    this.borderRadius = 8.0,
    this.onTapItem,
    this.itemBuilder,
    this.dotSize = 6.0,
    this.activeDotSize = 16.0,
    this.dotColor,
    this.activeDotColor,
    this.dotSpace = 3.0,
    this.dotBorderRadius = 3.0,
    this.controller,
    this.storageKey,
    this.onIndexChanged,
  });


  @override
  Widget build(BuildContext context) {
    if (banners.isNullOrEmpty) {
      return Skeleton.react(
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(borderRadius),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(borderRadius)),
      //  给 Swiper 一个稳定的 key，避免被当成“新对象”
      child: Swiper(
        key: storageKey,
        controller: controller,
        itemCount: banners.length,
        autoplay: autoPlay && banners.length > 1,
        loop: banners.length > 1,
        autoplayDelay: interval.inMilliseconds,
        onIndexChanged: (index) {
           onIndexChanged?.call(index);
        },
        itemBuilder: (_, index) {
          final item = banners[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: GestureDetector(
              onTap: onTapItem == null ? null : () => onTapItem!(item),
              child: ImageWidget(
                item: item,
                width: width,
                height: height,
                itemBuilder: itemBuilder,
              ),
            ),
          );
        },
        pagination: SwiperPagination(
          builder: CustomDotPaginationBuilder(
            showIndicator: showIndicator,
            size: dotSize,
            activeSize: activeDotSize,
            color: dotColor,
            activeColor: activeDotColor,
            space: dotSpace,
            borderRadius: dotBorderRadius,
          ),
        ),
      ),
    );
  }
}

/// custom dot pagination
/// active dot is larger and has different color
/// can customize size, color, space, borderRadius
/// default size: 6.0, activeSize: 16.0, color: white with 50% opacity, activeColor: white, space: 3.0, borderRadius: 3.0
/// if only one item, no pagination is shown
/// example:
/// ```dart
/// Swiper(
///  itemCount: 5,
///  pagination: SwiperPagination(
///  builder: CustomDotPaginationBuilder(
///  size: 8.0,
///  activeSize: 20.0,
///  color: Colors.grey,
///  activeColor: Colors.blue,
///  space: 4.0,
///  borderRadius: 4.0,
///  ),
class CustomDotPaginationBuilder extends SwiperPlugin {
  final double size; // inactive dot size, width and height
  final double activeSize;// active dot size, width only, height is same as inactive dot
  final Color? color; // inactive dot color
  final Color? activeColor; // active dot color
  final double space; // space between dots
  final double borderRadius; // dot border radius
  final bool showIndicator; // whether to show indicator

  const CustomDotPaginationBuilder({
    required this.size,
    required this.activeSize,
    required this.color,
    required this.activeColor,
    required this.space,
    required this.borderRadius,
    required this.showIndicator,
  });

  @override
  Widget build(BuildContext context, SwiperPluginConfig config){

    if(!showIndicator) return SizedBox.shrink();
    if (config.itemCount <= 1 ) return Container();

    List<Widget> dots = [];

    dots = List.generate(config.itemCount, ((i){
      bool active = config.activeIndex == i;
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        key: Key("pagination_$i"),
        width: active ? activeSize : size,
        height: size,
        margin: EdgeInsets.symmetric(horizontal: space),
        decoration: BoxDecoration(
            color: active ? activeColor??context.buttonPrimaryBg : color??context.bgActive,
            borderRadius: BorderRadius.circular(borderRadius)
        ),
      );
    }) as Widget Function(int index));

    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: dots,
      ),
    );
  }
}

/// Image widget with placeholder and error handling
/// if itemBuilder is provided, use it to build the widget
/// otherwise, use CachedNetworkImage to load image from network
/// with placeholder and error widget
class ImageWidget<T> extends StatelessWidget {
  final dynamic item;
  final double width;
  final double height;
  final Widget Function(T item)? itemBuilder;

  const ImageWidget({
    super.key,
    this.item,
    required this.width,
    required this.height,
    this.itemBuilder
  });

  @override
  Widget build(BuildContext context) {
    /// if itemBuilder is provided, use it to build the widget
    if(itemBuilder != null) {
      return itemBuilder!(item);
    }

    String url = '';
    if(item is String){
      url = item.toString();
    }else {
      url = item?.bannerImgUrl;
    }

    return CachedNetworkImage(
        imageUrl: proxied(url),
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_,__)=>Skeleton.react(width: width, height: height),
        errorWidget: (_,__,___)=>Container(
          width: width,
          height: height,
          color: const Color(0x11000000),
          alignment: Alignment.center,
          child: Icon(
            CupertinoIcons.photo,
            size: 32.w,
          ),
        )
    );
  }
}
