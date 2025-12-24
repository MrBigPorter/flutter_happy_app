import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/base/modal_theme.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

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
  final String? subTitle;
  final SettingRowType type;
  final VoidCallback onTap;

  RowItem({
    required this.icon,
    required this.title,
    this.subTitle,
    required this.type,
    required this.onTap,
  });
}

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState {
  @override
  Widget build(BuildContext context) {
    final items = <RowItem>[
      RowItem(
        icon: Icons.person,
        title: 'common.edit.profile',
        type: SettingRowType.normal,
        subTitle: '',
        onTap: () {
          // Navigate to profile page
        },
      ),
      RowItem(
        icon: Icons.document_scanner,
        title: 'common.kyc',
        type: SettingRowType.kyc,
        subTitle: '',
        onTap: () {
          appRouter.push('/me/kyc/verify');
        },
      ),
      RowItem(
        icon: Icons.location_city,
        title: 'common.setting.address',
        type: SettingRowType.normal,
        subTitle: '',
        onTap: () {
          // Navigate to phone settings page
        },
      ),
      RowItem(
        icon: Icons.lock,
        title: 'common.setting.password',
        type: SettingRowType.normal,
        subTitle: '',
        onTap: () {
          // Navigate to change password page
        },
      ),
      RowItem(
        icon: Icons.work,
        title: 'common.work.order',
        type: SettingRowType.normal,
        subTitle: '',
        onTap: () {
          // Navigate to change phone page
        },
      ),
      RowItem(
        icon: Icons.language,
        title: 'common.setting.language',
        type: SettingRowType.language,
        subTitle: '',
        onTap: () {
          showCupertinoModalPopup(
              context: context,
              builder: (context)=> CupertinoActionSheet(
                actions: [
                  CupertinoActionSheetAction(
                    onPressed: () {
                      context.setLocale(Locale('en'));
                      Navigator.of(context).pop();
                    },
                    child: Text('English'),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () {
                      context.setLocale(Locale('tl'));
                      Navigator.of(context).pop();
                    },
                    child: Text('Tagalog'),
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('common.cancel'.tr()),
                ),
              )
          );
        },
      ),
      RowItem(
        icon: Icons.dark_mode,
        title: 'common.setting.mode',
        type: SettingRowType.darkModeSwitch,
        subTitle: '',
        onTap: () {
          // Navigate to theme settings page
        },
      ),
      RowItem(
        icon: Icons.notifications,
        title: 'common.notifications',
        type: SettingRowType.notificationSwitch,
        subTitle: '',
        onTap: () {
          // Navigate to notifications settings page
        },
      ),
    ];

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
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }
}

class _SettingRowWidget extends ConsumerWidget {
  final RowItem item;

  const _SettingRowWidget({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      child: InkWell(
        onTap: item.onTap,
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

    return Material(
      child: InkWell(
        child: Row(
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
            SizedBox(width: 10.w),
            Icon(
              Icons.chevron_right,
              color: context.fgSecondary700,
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildRight(
    BuildContext context,
    WidgetRef ref,
    SettingRowType type,
  ) {
    switch (type) {
      case SettingRowType.kyc:
        final status = ref.watch(
          luckyProvider.select((value) => value.userInfo?.kycStatus),
        );
        return _KycRight(status: KycStatusEnum.fromStatus(status ?? 0).label);
      case SettingRowType.darkModeSwitch:
        final themeMode = ref.watch(themeModeProvider);
        final isDarkMode = themeMode == ThemeMode.dark;
        print('themeMode: $isDarkMode');
        return CupertinoSwitch(
          value: isDarkMode,
          onChanged: (bool value) {
            ref.read(themeModeProvider.notifier).toggleThemeMode();
          },
        );
      case SettingRowType.notificationSwitch:
        return CupertinoSwitch(
          value: false,
          onChanged: (bool value) {

          },
        );
      case SettingRowType.language:
        return Text(
          context.locale.languageCode == 'en' ? 'English' : '中文',
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


class _KycRight extends StatelessWidget {
  final KycStatusLabel status;

  const _KycRight({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case KycStatusLabel.draft:
        color = context.textSecondary700;
        break;
      case KycStatusLabel.reviewing:
        color = context.textPrimary900;
        break;
      case KycStatusLabel.rejected:
        color = context.textErrorPrimary600;
        break;
      case KycStatusLabel.needMore:
        color = context.textWarningPrimary600;
        break;
      case KycStatusLabel.approved:
        color = context.utilityGreen50;
        break;
    }
    return Text(
      status.name.toString(),
      style: TextStyle(color: color, fontSize: 14.sp),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                // Handle logout action
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
