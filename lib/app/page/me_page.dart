import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/me_components/voucher.dart';
import 'package:flutter_app/app/page/me_components/voucher_list.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  @override
  Widget build(BuildContext context) {
    // check if user is authenticated
    final isAuthenticated = ref.watch(authProvider.select((s) => s.isAuthenticated));
    
    return BaseScaffold(
      showBack: false,
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // top login area
              if(isAuthenticated) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w,vertical: 16.w),
                  child: _LoginTopArea(),
                ),
                // voucher list area
                VoucherList(),
              ] else ...[
                // top no login area
                _UnLoginTopArea(),
              ],

              // wallet area
              _WalletArea(),
              // menu area
              _MenuArea(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.purple,
      alignment: Alignment.center,
      child: Text(
        'Menu Area',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class _WalletArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      color: Colors.orange,
      alignment: Alignment.center,
      child: Text(
        'Wallet Area',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class _LoginTopArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(),
          SizedBox(height: 4.w),
          Voucher(),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Image.asset(
              'assets/images/Avatar01.png',
              width: 48.w,
              height: 48.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text.rich(
                    style: TextStyle(
                      fontSize: context.textMd,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary900,
                      height: context.leadingMd,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                      text: "common.hello".tr(),
                      children: [
                        TextSpan(text: ","),
                        TextSpan(text: "porter"),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w,),
                  SvgPicture.asset(
                    'assets/images/copy.svg',
                    width: 15.w,
                    height: 15.w,
                    colorFilter: ColorFilter.mode(
                      context.fgPrimary900,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.w),
              Text(
                'common.active.raffle'.tr(namedArgs: {"number": "5"}),
                style: TextStyle(
                  fontSize: context.textXs,
                  fontWeight: FontWeight.w600,
                  color: context.textTertiary600,
                  height: context.leadingXs,
                ),
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  'assets/images/bell.svg',
                  width: 30.w,
                  height: 30.w,
                  colorFilter: ColorFilter.mode(
                    context.fgPrimary900,
                    BlendMode.srcIn,
                  ),
                ),
                Positioned(
                  right: 0.w,
                  top: 0.w,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(width: 8.w,),
        ],
      ),
    );
  }
}

/// Unlogin top area with login and register buttons
/// Used when user is not logged in
/// Contains a tip text and two buttons: login and register
/// The buttons navigate to the login and register pages respectively
class _UnLoginTopArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 28.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'login.tip'.tr(),
            style: TextStyle(
              fontSize: context.textSm,
              fontWeight: FontWeight.w600,
              color: context.textPrimary900,
              height: context.leadingSm,
            ),
          ),
          SizedBox(height: 12.w),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Button(
                width: 110,
                height: 40,
                onPressed: () => AppRouter.router.push('/login'),
                child: Text('common.login'.tr()),
              ),
              SizedBox(width: 8.w),
              Button(
                width: 110,
                height: 40,
                variant: ButtonVariant.secondary,
                onPressed: () => AppRouter.router.push('/register'),
                child: Text('common.register'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
