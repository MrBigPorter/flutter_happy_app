import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'package:flutter_app/common.dart';

import '../utils/helper.dart';

class HomeBanner extends StatefulWidget {
  final List<Banners> banners;
  final String? bannerID;
  final double? height;
  final bool? autoPlay;
  final Duration? interval;

  const HomeBanner({
    super.key,
    required this.banners,
    this.bannerID,
    this.height = 150,
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.banners;
    return Container(
      key: widget.bannerID != null ? Key(widget.bannerID!) : null,
      margin: const EdgeInsets.only(top: 8,left: 16,right: 16),
      height: widget.height,
      child: Stack(
          fit: StackFit.expand,
          children: [
            SizedBox(
              height: widget.height,
              width: double.infinity,
              child:  PageView.builder(
                controller: _pc,
                onPageChanged: (i) => setState(() {
                  _index = i;
                }),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Hero(
                      tag: 'banner_$i',
                      child: Image.network(
                        proxied(item.bannerImgUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: widget.height,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(CupertinoIcons.photo),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
    );
  }
}
