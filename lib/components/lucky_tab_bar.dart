import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LuckyTabBar extends StatelessWidget {
  final Widget child;

  const LuckyTabBar({super.key, required this.child});

  final List<_TabItem> _tabs = const [
    _TabItem(
      label: "common.tabbar.home",
      icon: "images/TabBar/home.svg",
      activeIcon: "images/TabBar/home_active.svg",
      location: "/home",
    ),
    _TabItem(
      label: "common.tabbar.product",
      icon: "images/TabBar/product.svg",
      activeIcon: "images/TabBar/product_active.svg",
      location: "/product",
    ),
    _TabItem(
      label: "common.tabbar.winners",
      icon: "images/TabBar/winners.svg",
      activeIcon: "images/TabBar/winners_active.svg",
      location: "/winners",
    ),
    _TabItem(
      label: "common.tabbar.me",
      icon: "images/TabBar/me.svg",
      activeIcon: "images/TabBar/me_active.svg",
      location: "/me",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
     int currentIndex = _tabs.indexWhere(
      (tab) => location.startsWith(tab.location),
    );
    if (currentIndex == -1) currentIndex = 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          context.go(_tabs[index].location);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: context.fgBrandPrimary,
        unselectedItemColor: context.fgQuinary400,
        selectedLabelStyle: TextStyle(
          fontSize: context.text2xs,
          fontWeight: FontWeight.w600,
        ),
        items: _tabs.asMap().entries.map((entry) {
          final tab = entry.value;
          return BottomNavigationBarItem(
            icon: SvgPicture.asset(
              tab.icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                context.fgQuinary400,
                BlendMode.srcIn,
              ),
            ),
            activeIcon: SvgPicture.asset(
              tab.activeIcon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                context.fgBrandPrimary,
                BlendMode.srcIn,
              ),
            ),
            label: tab.label.tr(),
          );
        }).toList(),
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => KeepAliveWrapperState();
}

class KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// define a class to hold tab item data
class _TabItem {
  final String label;
  final String icon;
  final String activeIcon;
  final String location;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.location,
  });
}
