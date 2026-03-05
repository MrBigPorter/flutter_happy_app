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
  profile,
  kyc,
  address,
  darkModeSwitch,
  notificationSwitch,
  language,
}

class RowItem {
  final IconData icon;
  final String title;
  final SettingRowType type;

  const RowItem({required this.icon, required this.title, required this.type});
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
    // Only fetch KYC status if authenticated to avoid 401 errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isAuthenticated) {
        ref.refresh(kycMeProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "common.setting".tr(),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        separatorBuilder: (_, __) =>
            Divider(height: 1.h, color: context.borderSecondary),
        itemCount: items.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: _SettingRowWidget(item: items[index]),
        ),
      ),
      bottomNavigationBar: const _BottomNavigationBar(),
    );
  }
}

class _SettingRowWidget extends ConsumerWidget {
  final RowItem item;

  const _SettingRowWidget({required this.item});

  void _handleTap(BuildContext context, WidgetRef ref, SettingRowType type) {
    // Auth Guard for specific actions.
    if ([
      SettingRowType.profile,
      SettingRowType.address,
      SettingRowType.kyc,
    ].contains(type)) {
      if (!ref.read(authProvider).isAuthenticated) {
        appRouter.push('/login');
        return;
      }
    }

    switch (type) {
      case SettingRowType.profile:
        RadixToast.info("Feature coming soon");
        break;
      case SettingRowType.address:
        RadixSheet.show(builder: (context, close) => const AddressList());
        break;
      case SettingRowType.kyc:
        final kycStatus = ref.read(kycMeProvider).valueOrNull?.kycStatus ?? 0;
        final statusCode = KycStatusEnum.fromStatus(kycStatus);
        if (statusCode == KycStatusEnum.draft) {
          appRouter.push('/me/kyc/verify');
        } else {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const KycStatusPage()));
        }
        break;
      case SettingRowType.language:
        _showLangSheet(context);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context, ref, item.type),
        child: _RowContent(item: item),
      ),
    );
  }

  // Simplified language picker.
  Future<void> _showLangSheet(BuildContext context) async {
    final cur = context.locale.languageCode;
    final picked = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'en'),
            child: Text(cur == 'en' ? 'English ✓' : 'English'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'tl'),
            child: Text(cur == 'tl' ? 'Tagalog ✓' : 'Tagalog'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text('common.cancel'.tr()),
        ),
      ),
    );
    if (picked != null && picked != cur)
      await context.setLocale(Locale(picked));
  }
}

class _RowContent extends ConsumerWidget {
  final RowItem item;

  const _RowContent({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final right = _buildRight(context, ref, item.type);
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
        SizedBox(width: 10.w),
        Icon(Icons.chevron_right, color: context.fgSecondary700, size: 24.w),
      ],
    );
  }

  Widget? _buildRight(
    BuildContext context,
    WidgetRef ref,
    SettingRowType type,
  ) {
    switch (type) {
      case SettingRowType.kyc:
        if (!ref.watch(authProvider).isAuthenticated)
          return Text(
            'Login to view',
            style: TextStyle(color: context.textSecondary700, fontSize: 14.sp),
          );
        final status = KycStatusEnum.fromStatus(
          ref.watch(kycMeProvider).valueOrNull?.kycStatus ?? 0,
        );
        return _KycStatusLabel(status: status);
      case SettingRowType.language:
        return Text(
          context.locale.languageCode == 'en' ? 'English' : 'Tagalog',
          style: TextStyle(color: context.textSecondary700, fontSize: 14.sp),
        );
      case SettingRowType.darkModeSwitch:
        return CupertinoSwitch(
          value: ref.watch(themeModeProvider) == ThemeMode.dark,
          onChanged: (_) =>
              ref.read(themeModeProvider.notifier).toggleThemeMode(),
        );
      default:
        return null;
    }
  }
}

class _KycStatusLabel extends StatelessWidget {
  final KycStatusEnum status;

  const _KycStatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      KycStatusEnum.draft: context.textErrorPrimary600,
      KycStatusEnum.approved: context.utilityGreen200,
    };
    return Text(
      status.name,
      style: TextStyle(
        color: colors[status] ?? context.utilityGray200,
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _BottomNavigationBar extends ConsumerWidget {
  const _BottomNavigationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              backgroundColor: auth.isAuthenticated
                  ? context.buttonPrimaryErrorBg
                  : context.utilityBrand500,
              width: double.infinity,
              height: 48.h,
              radius: 8.r,
              onPressed: () => auth.isAuthenticated
                  ? ref.read(authProvider.notifier).logout()
                  : appRouter.push('/login'),
              child: Text(
                auth.isAuthenticated
                    ? 'common.logout'.tr()
                    : 'common.login'.tr(),
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
              style: TextStyle(color: context.textPrimary900, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
}
