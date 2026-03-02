import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/providers/kyc_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../components/address/address_list.dart';
import '../../theme/theme_provider.dart';
import 'kyc_status_page.dart';

enum SettingRowType {
  profile,            // 个人资料
  kyc,                // 实名认证
  address,            // 地址管理
  darkModeSwitch,     // 黑夜模式
  notificationSwitch, // 消息通知
  language,           // 多语言设定
  normal,             // 普通选项（预留）
}

class RowItem {
  final IconData icon;
  final String title;
  final SettingRowType type;

  const RowItem({
    required this.icon,
    required this.title,
    required this.type,
  });
}

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  static const items = <RowItem>[
    RowItem(
      icon: Icons.person,
      title: 'common.edit.profile',
      type: SettingRowType.profile,
    ),
    RowItem(
      icon: Icons.document_scanner,
      title: 'common.kyc',
      type: SettingRowType.kyc,
    ),
    RowItem(
      icon: Icons.location_city,
      title: 'common.setting.address',
      type: SettingRowType.address,
    ),
    RowItem(
      icon: Icons.language,
      title: 'common.setting.language',
      type: SettingRowType.language,
    ),
    RowItem(
      icon: Icons.dark_mode,
      title: 'common.setting.mode',
      type: SettingRowType.darkModeSwitch,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 每次进入设置页面，刷新 KYC 状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(kycMeProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "common.setting".tr(),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        separatorBuilder: (_, __) => Divider(
          height: 1.h,
          color: context.borderSecondary,
          thickness: 1.h,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: _SettingRowWidget(item: item),
          );
        },
      ),
      bottomNavigationBar: const _BottomNavigationBar(),
    );
  }
}

class _SettingRowWidget extends ConsumerWidget {
  final RowItem item;

  const _SettingRowWidget({required this.item});

  void _handleTap(BuildContext context, WidgetRef ref, SettingRowType type) {
    if (type == SettingRowType.profile || type == SettingRowType.address || type == SettingRowType.kyc) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      if (!isAuthenticated) {
         appRouter.push('/login');
        return;
      }
    }

    switch (type) {
      case SettingRowType.profile:
      // 个人资料暂未完成，优雅拦截
        RadixToast.info("Profile editing coming soon!");
        break;

      case SettingRowType.address:
        RadixSheet.show(
          builder: (context, close) => const AddressList(),
        );
        break;

      case SettingRowType.kyc:
      // 简化 KYC 逻辑，直接取 valueOrNull 安全判定
        final kycStatus = ref.read(kycMeProvider).valueOrNull?.kycStatus ?? 0;
        final statusCode = KycStatusEnum.fromStatus(kycStatus);

        if (statusCode == KycStatusEnum.draft) {
          appRouter.push('/me/kyc/verify');
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const KycStatusPage(),
            ),
          );
        }
        break;

      case SettingRowType.darkModeSwitch:
      case SettingRowType.notificationSwitch:
      // switch 不走 tap
        break;

      case SettingRowType.language:
        _showLangSheet(context);
        break;
        case SettingRowType.normal:
        // 预留普通选项的点击事件
        break;
    }
  }

  Future<void> _showLangSheet(BuildContext context) async {
    final cur = context.locale.languageCode;

    final picked = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetCtx, 'en'),
            child: Text(cur == 'en' ? 'English  ✓' : 'English'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetCtx, 'tl'),
            child: Text(cur == 'tl' ? 'Tagalog  ✓' : 'Tagalog'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetCtx),
          child: Text('common.cancel'.tr()),
        ),
      ),
    );

    if (picked != null && picked != cur) {
      await context.setLocale(Locale(picked));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clickable = item.type != SettingRowType.darkModeSwitch &&
        item.type != SettingRowType.notificationSwitch;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: clickable ? () => _handleTap(context, ref, item.type) : null,
        child: _RowItemWidget(item: item),
      ),
    );
  }
}

class _RowItemWidget extends ConsumerWidget {
  final RowItem item;

  const _RowItemWidget({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final right = _buildRight(context, ref, item.type);
    final showChevron = item.type != SettingRowType.darkModeSwitch &&
        item.type != SettingRowType.notificationSwitch;

    return Row(
      children: [
        Icon(item.icon, color: context.fgPrimary900, size: 24.w),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            item.title.tr(),
            style: TextStyle(
              color: context.textPrimary900,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (right != null) right,
        if (showChevron) ...[
          SizedBox(width: 10.w),
          Icon(
            Icons.chevron_right,
            color: context.fgSecondary700,
            size: 24.w,
          ),
        ]
      ],
    );
  }

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  Widget? _buildRight(
      BuildContext context,
      WidgetRef ref,
      SettingRowType type,
      ) {
    switch (type) {
      case SettingRowType.kyc:
        final isAuthenticated =
        ref.watch(authProvider.select((v) => v.isAuthenticated));
        if (!isAuthenticated) return null;

        final kycMeProviderData = ref.watch(kycMeProvider);
        final rawStatus = kycMeProviderData.maybeWhen(
          data: (data) => data?.kycStatus,
          orElse: () => null,
        );
        final statusCode = _toInt(rawStatus, fallback: 0);
        final statusEnum = KycStatusEnum.fromStatus(statusCode);

        return _KycRight(status: statusEnum);

      case SettingRowType.darkModeSwitch:
        final themeMode = ref.watch(themeModeProvider);
        final isDarkMode = themeMode == ThemeMode.dark;
        return CupertinoSwitch(
          value: isDarkMode,
          onChanged: (_) {
            ref.read(themeModeProvider.notifier).toggleThemeMode();
          },
        );

      case SettingRowType.notificationSwitch:
        return CupertinoSwitch(
          value: false,
          onChanged: (bool value) {
            // TODO
          },
        );

      case SettingRowType.language:
        return Text(
          context.locale.languageCode == 'en' ? 'English' : 'Tagalog',
          style: TextStyle(
            color: context.textSecondary700,
            fontSize: 14.sp,
          ),
        );

      case SettingRowType.profile:
      case SettingRowType.address:
      case SettingRowType.normal:
        return null;
    }
  }
}

class _KycRight extends StatelessWidget {
  final KycStatusEnum status;

  const _KycRight({required this.status});

  String _labelText(BuildContext context, KycStatusEnum s) {
    switch (s) {
      case KycStatusEnum.draft:
        return 'Draft';
      case KycStatusEnum.reviewing:
        return 'Reviewing';
      case KycStatusEnum.rejected:
        return 'Rejected';
      case KycStatusEnum.needMore:
        return 'Need more';
      case KycStatusEnum.approved:
        return 'Approved';
      default:
        return 'Unknown';
    }
  }

  Color _labelColor(BuildContext context, KycStatusEnum s) {
    switch (s) {
      case KycStatusEnum.draft:
        return context.textErrorPrimary600;
      case KycStatusEnum.reviewing:
        return context.utilityBrand200;
      case KycStatusEnum.rejected:
        return context.utilityError200;
      case KycStatusEnum.needMore:
        return context.utilityBlue200;
      case KycStatusEnum.approved:
        return context.utilityGreen200;
      default:
        return context.utilityGray200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _labelText(context, status);
    final color = _labelColor(context, status);

    return Text(
      text,
      style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.w600),
    );
  }
}

class _BottomNavigationBar extends ConsumerWidget {
  const _BottomNavigationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authProvider.select((v) => v.isAuthenticated));
    if (!isAuthenticated) return const SizedBox.shrink(); // 未登录不显示退出按钮

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              backgroundColor: context.buttonPrimaryErrorBg,
              width: double.infinity,
              height: 48.h, // 稍微拉高一点，点起来更舒服
              radius: 8.r,
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                appRouter.go('/'); // 退出后自动跳回首页
              },
              child: Text(
                'common.logout'.tr(),
                style: TextStyle(
                  color: context.textWhite,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'version 1.0.0',
              style: TextStyle(
                color: context.textPrimary900,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}