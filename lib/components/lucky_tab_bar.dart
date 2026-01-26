import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/motion/motion_ext.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../ui/chat/providers/conversation_provider.dart';

class LuckyTabBar extends ConsumerWidget {
  final Widget child;

  const LuckyTabBar({super.key, required this.child});

  // 1. 修改配置：使用 Flutter 自带图标 (IconData)
  static const List<_TabItem> _tabs = [
    _TabItem(
      label: "common.tabbar.home",
      icon: Icons.home_outlined, // 首页-未选中
      activeIcon: Icons.home, // 首页-选中
      location: "/home",
    ),
    _TabItem(
      label: "common.tabbar.product",
      icon: Icons.shopping_bag_outlined, // 商品-未选中
      activeIcon: Icons.shopping_bag, // 商品-选中
      location: "/product",
    ),
    //  替换 Winners -> Chat (使用气泡图标)
    _TabItem(
      label: "common.tabbar.chat",
      icon: Icons.chat_bubble_outline, // 聊天-未选中
      activeIcon: Icons.chat_bubble, // 聊天-选中
      location: "/conversations",
    ),
    _TabItem(
      label: "common.tabbar.me",
      icon: Icons.person_outline, // 我的-未选中
      activeIcon: Icons.person, // 我的-选中
      location: "/me",
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(
      authProvider.select((value) => value.isAuthenticated),
    );
    final String location = GoRouterState.of(context).uri.toString();
    int currentIndex = _tabs.indexWhere(
      (tab) => location.startsWith(tab.location),
    );
    if (currentIndex == -1) currentIndex = 0;

    // 2. 监听总未读数
    final totalUnread = isAuthenticated
        ? ref.watch(
            conversationListProvider.select(
              (asyncList) =>
                  asyncList.valueOrNull?.fold<int>(
                    0,
                    (sum, item) => sum + item.unreadCount,
                  ) ??
                  0, // 如果正在加载或数据为空，则返回 0
            ),
          )
        : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: SizedBox(
        child: BottomNavigationBar(
          backgroundColor: context.bgPrimary,
          currentIndex: currentIndex,
          onTap: (index) => context.go(_tabs[index].location),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: context.fgBrandPrimary,
          unselectedItemColor: context.fgQuinary400,
          selectedFontSize: 10.sp,
          unselectedFontSize: 10.sp,
          unselectedLabelStyle: TextStyle(
            fontSize: context.text2xs,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          selectedLabelStyle: TextStyle(
            fontSize: context.text2xs,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          items: _tabs.asMap().entries.map((entry) {
            final tab = entry.value;
            final index = entry.key;
            final isActive = currentIndex == index;
            final isChatTab = tab.location == '/conversations';

            // 3. 修改渲染逻辑：使用 Icon 组件替代 SvgPicture
            Widget iconWidget = Icon(
              isActive ? tab.activeIcon : tab.icon, // 选中用实心，未选中用空心
              size: 24.w,
              color: isActive ? context.fgBrandPrimary : context.fgQuinary400,
            );

            // 选中动画
            if (isActive) {
              iconWidget = iconWidget.wiggleOnTap();
            }

            // 4. 红点 Badge 逻辑 (保持不变)
            if (isChatTab && totalUnread > 0) {
              iconWidget = Stack(
                clipBehavior: Clip.none,
                children: [
                  iconWidget,
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.bgPrimary,
                          width: 1.5,
                        ),
                      ),
                      constraints: BoxConstraints(minWidth: 16.w),
                      child: Center(
                        child: Text(
                          totalUnread > 99 ? '99+' : '$totalUnread',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return BottomNavigationBarItem(
              icon: iconWidget,
              label: tab.label.tr(),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// 5. 修改数据模型：把 String 改为 IconData
class _TabItem {
  final String label;
  final IconData icon; // 改了这里
  final IconData activeIcon; // 改了这里
  final String location;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.location,
  });
}
