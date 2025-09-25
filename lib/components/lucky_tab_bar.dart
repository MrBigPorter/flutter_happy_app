import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/me_page.dart';
import 'package:flutter_app/app/page/product_detail_page.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/tw/tw_metrics.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/page/home_page.dart';
import '../app/page/winners_page.dart';

class LuckyTabBar extends StatefulWidget {
   const LuckyTabBar({super.key});
   @override
   State<LuckyTabBar>  createState() => _LuckyTabBarState();
}

class _LuckyTabBarState extends State<LuckyTabBar> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    KeepAliveWrapper(child: HomePage(id: '',)),
    KeepAliveWrapper(child: ProductDetailPage(id: '')),
    KeepAliveWrapper(child: WinnersPage() ),
    KeepAliveWrapper(child: MePage() ),
  ];


  final List<_TabItem> _tabs = const  [
    _TabItem(
      label: "Home",
      icon: "images/TabBar/home.svg",
      activeIcon: "images/TabBar/home_active.svg",
    ),
    _TabItem(
      label: "Product",
      icon: "images/TabBar/product.svg",
      activeIcon: "images/TabBar/product_active.svg",
    ),
    _TabItem(
      label: "Winners",
      icon: "images/TabBar/winners.svg",
      activeIcon: "images/TabBar/winners_active.svg",
    ),
    _TabItem(
      label: "Me",
      icon: "images/TabBar/me.svg",
      activeIcon: "images/TabBar/me_active.svg",
    ),
  ];
  @override
  Widget build(BuildContext content){
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(()=> _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor:content.foregroundFgBrandPrimary,
        unselectedItemColor: content.foregroundFgQuinary400 ,
        selectedLabelStyle: TextStyle(
          fontSize: content.text2xs,
          fontWeight: FontWeight.w600,
        ),
        items: _tabs.asMap().entries.map((entry){
          final tab = entry.value;
          return BottomNavigationBarItem(
            icon: SvgPicture.asset(
              tab.icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(content.foregroundFgQuinary400 ?? Color(#a3a7ae as int), BlendMode.srcIn),
            ),
            activeIcon: SvgPicture.asset(
              tab.activeIcon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(content.foregroundFgBrandPrimary ?? Color(#fc7701 as int), BlendMode.srcIn),
            ),
            label: tab.label,
          );
        }).toList()
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key,required this.child});

  @override
  State<KeepAliveWrapper> createState() => KeepAliveWrapperState();
}

class KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin{
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

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
