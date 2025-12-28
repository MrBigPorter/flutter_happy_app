import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/theme_provider.dart';

enum SettingRowType {
  normal,
  kyc,
  darkModeSwitch,
  notificationSwitch,
  language,
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
      type: SettingRowType.normal,
    ),
    RowItem(
      icon: Icons.document_scanner,
      title: 'common.kyc',
      type: SettingRowType.kyc,
    ),
    RowItem(
      icon: Icons.location_city,
      title: 'common.setting.address',
      type: SettingRowType.normal,
    ),
    RowItem(
      icon: Icons.lock,
      title: 'common.setting.password',
      type: SettingRowType.normal,
    ),
    RowItem(
      icon: Icons.work,
      title: 'common.work.order',
      type: SettingRowType.normal,
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
    RowItem(
      icon: Icons.notifications,
      title: 'common.notifications',
      type: SettingRowType.notificationSwitch,
    ),
  ];

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
    switch (type) {
      case SettingRowType.normal:
      // TODO: 你自己按 row 的 title 做路由映射
        break;

      case SettingRowType.kyc:
        final isAuthenticated =
        ref.read(authProvider.select((v) => v.isAuthenticated));

        if (!isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('common.please_login'.tr())),
          );
          return;
        }

        // 你原本是 /me/kyc/verify，这里保持不变
        appRouter.push('/me/kyc/verify');
        break;

      case SettingRowType.darkModeSwitch:
      // switch 不走 tap
        break;

      case SettingRowType.notificationSwitch:
      // switch 不走 tap
        break;

      case SettingRowType.language:
        _showLangSheet(context);
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

        final rawStatus = ref.watch(
          luckyProvider.select((v) => v.userInfo?.kycStatus),
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

      case SettingRowType.normal:
        return null;
    }
  }
}

/// ✅ 这里我直接收 KycStatusEnum，避免你 label 枚举改来改去导致编译炸
class _KycRight extends StatelessWidget {
  final KycStatusEnum status;

  const _KycRight({required this.status});

  String _labelText(BuildContext context, KycStatusEnum s) {
    // 如果你有 i18n key，可以换成 tr()
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
    // 你后端如果有 5 autoRejected，这里也兜底（如果你 enum 没定义会编译不过）
    // ignore: dead_code
      default:
        return 'Unknown';
    }
  }

  Color _labelColor(BuildContext context, KycStatusEnum s) {
    switch (s) {
      case KycStatusEnum.draft:
        return context.textSecondary700;
      case KycStatusEnum.reviewing:
        return context.textPrimary900;
      case KycStatusEnum.rejected:
        return context.textErrorPrimary600;
      case KycStatusEnum.needMore:
        return context.textWarningPrimary600;
      case KycStatusEnum.approved:
      // 你之前用 utilityGreen50 可能太浅，我换成更像“成功文本色”
      // 如果你项目没有这个 token，就把它改回 textPrimary900 或 utilityGreen50
        return (context as dynamic).textSuccessPrimary600 ?? context.textPrimary900;
    // ignore: dead_code
      default:
        return context.textSecondary700;
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
    return SizedBox(
      height: 120.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              backgroundColor: context.buttonPrimaryErrorBg,
              width: double.infinity,
              height: 43.h,
              radius: 8.r,
              onPressed: () {
                ref.read(authProvider.notifier).logout();
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
            SizedBox(height: 4.h),
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