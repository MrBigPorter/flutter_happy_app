import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/me_components/voucher.dart';
import 'package:flutter_app/app/page/me_components/voucher_list.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage>{


  Future<void> _onRefresh() async {
    ref.read(luckyProvider.notifier).updateWalletBalance();
  }

  @override
  Widget build(BuildContext context) {
    
    // check if user is authenticated
    var isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );
    final balance = ref.watch(luckyProvider.select((s) => s.balance));

    return BaseScaffold(
      showBack: false,
      elevation: 0,
      body: LuckyCustomMaterialIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: platformScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.only(top: 16.w, left: 16.w, right: 16.w),
                  child: isAuthenticated ? _LoginTopArea() : _UnLoginTopArea(),
                ),
              ),
            ),
            if (isAuthenticated) ...[
              SliverToBoxAdapter(
                child: const RepaintBoundary(child: VoucherList()),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 8.w,)),
            ],
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: _OrderArea(),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 8.w,),
            ),
            SliverToBoxAdapter(
              child: RepaintBoundary(child: _WalletArea(balance: balance)),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 8.w,)),
            SliverToBoxAdapter(child: RepaintBoundary(child: _MenuArea())),
            SliverToBoxAdapter(child: SizedBox(height: 8.w,)),

          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String text;
  final Widget icon;
  final String path;

  const _MenuItem({required this.text, required this.icon, required this.path});
}

class _MenuArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<_MenuItem> menuItems = [
      _MenuItem(
        text: 'common.videos'.tr(),
        icon: SvgPicture.asset(
          'assets/images/video.svg',
          width: 24.w,
          height: 24.w,
          colorFilter: ColorFilter.mode(context.fgSecondary700, BlendMode.srcIn),
        ),
        path: '/guide',
      ),
      _MenuItem(
        text: 'common.check.in'.tr(),
        icon: SvgPicture.asset(
          'assets/images/calendar-check-01.svg',
          width: 24.w,
          height: 24.w,
          colorFilter: ColorFilter.mode(context.fgSecondary700, BlendMode.srcIn),
        ),
        path: '/me/sign-in',
      ),
      _MenuItem(
        text: 'common.invitefriends'.tr(),
        icon: SvgPicture.asset(
          'assets/images/share.svg',
          width: 24.w,
          height: 24.w,
          colorFilter: ColorFilter.mode(context.fgSecondary700, BlendMode.srcIn),
        ),
        path: '/me/invitefriends',
      ),
      // --- 修改点 1: 在九宫格增加提现入口 ---
      _MenuItem(
        text: 'common.withdraw'.tr(),
        icon: Icon(Icons.account_balance_rounded, size: 24.w, color: context.fgSecondary700),
        path: '/me/wallet/withdraw',
      ),
      _MenuItem(
        text: 'common.redeem.code'.tr(),
        icon: SvgPicture.asset(
          'assets/images/redemptionCode.svg',
          width: 24.w,
          height: 24.w,
          colorFilter: ColorFilter.mode(context.fgSecondary700, BlendMode.srcIn),
        ),
        path: '/me/wallet/treasure-coins/redeem',
      ),
      _MenuItem(
        text: 'common.setting'.tr(),
        icon: SvgPicture.asset(
          'assets/images/setting.svg',
          width: 24.w,
          height: 24.w,
          colorFilter: ColorFilter.mode(context.fgSecondary700, BlendMode.srcIn),
        ),
        path: '/setting',
      ),
      _MenuItem(
        text: 'common.faq'.tr(),
        icon: SvgPicture.asset(
          'assets/images/faq.svg',
          width: 24.w,
          height: 24.w,
          colorFilter: ColorFilter.mode(context.fgSecondary700, BlendMode.srcIn),
        ),
        path: '/faq',
      ),
      _MenuItem(
        text: 'common.workorder'.tr(),
        icon: SvgPicture.asset(
          'assets/images/workorder.svg',
          width: 24.w,
          height: 24.w,
          colorFilter: ColorFilter.mode(context.fgSecondary700, BlendMode.srcIn),
        ),
        path: '/setting/workorder',
      ),
    ];

    return Container(
      width: double.infinity,
      color: context.bgPrimary,
      alignment: Alignment.topLeft,
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 15.w, left: 15.w, right: 15.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 15.w,
          childAspectRatio: 1,
        ),
        children: menuItems.map((item) {
          return InkWell(
            onTap: () => appRouter.push(item.path),
            child: Column(
              children: [
                item.icon,
                SizedBox(height: 8.w),
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary900,
                    height: context.leadingXs,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WalletArea extends StatelessWidget {
  final Balance balance;

  const _WalletArea({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.bgPrimary,
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'common.wallet'.tr(),
                style: TextStyle(
                  fontSize: context.textSm,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                  height: context.leadingSm,
                ),
              ),
              Button(
                height: 40.w,
                variant: ButtonVariant.text,
                paddingX: 0,
                trailing: Icon(Icons.arrow_forward_ios, size: 12.w, color: context.textPrimary900),
                onPressed: () => appRouter.push('/me/wallet/treasure-coins/redeem'),
                child: Text(
                  'redemption.code'.tr(),
                  style: TextStyle(
                    fontSize: context.textSm,
                    fontWeight: FontWeight.w500,
                    height: context.leadingSm,
                    color: context.textPrimary900,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // --- 现金余额卡片 (增加提现入口) ---
              Expanded(
                child: InkWell(
                  onTap: () => appRouter.push('/me/wallet/transaction/record'),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: context.alphaBlack5,
                      borderRadius: BorderRadius.circular(context.radiusMd),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50.w, // 缩小宽度给按钮腾空间
                          child: Text(
                            'common.wallet'.tr(),
                            style: TextStyle(
                              fontSize: context.textXs,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary900,
                              height: context.leadingMd,
                            ),
                          ),
                        ),
                        Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              FormatHelper.formatWithCommasAndDecimals(balance.realBalance),
                              style: TextStyle(
                                fontSize: context.textXs,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary900,
                                height: context.leadingXs,
                              ),
                            ),
                            SizedBox(height: 6.w),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 充值
                                _smallActionBtn(context, 'common.topup'.tr(), context.textBrandPrimary900, () => appRouter.push('/me/wallet/deposit')),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // --- 金币余额卡片 ---
              Expanded(
                child: InkWell(
                  onTap: () => appRouter.push('/me/wallet'),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: context.alphaBlack5,
                      borderRadius: BorderRadius.circular(context.radiusMd),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50.w,
                          child: Text(
                            'common.treasureCoins'.tr(),
                            style: TextStyle(
                              fontSize: context.textXs,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary900,
                              height: context.leadingMd,
                            ),
                          ),
                        ),
                        Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              FormatHelper.formatWithCommasAndDecimals(balance.coinBalance),
                              style: TextStyle(
                                fontSize: context.textXs,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary900,
                                height: context.leadingXs,
                              ),
                            ),
                            SizedBox(height: 6.w),
                            _smallActionBtn(context, 'common.view'.tr(), context.textBrandPrimary900, () => appRouter.push('/me/wallet')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 辅助构建钱包卡片里的小操作按钮
  Widget _smallActionBtn(BuildContext context, String text, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: context.alphaBlack5,
          borderRadius: BorderRadius.circular(context.radiusMd),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
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

class _Avatar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(luckyProvider.select((s) => s.userInfo?.nickname));
    
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
            child: Image.asset('assets/images/Avatar01.png', width: 48.w, height: 48.w, fit: BoxFit.cover),
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
                      text: 'Hello',
                      children: [const TextSpan(text: ","), TextSpan(text: nickname?.substring(0,10) )],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SvgPicture.asset(
                    'assets/images/copy.svg',
                    width: 15.w,
                    height: 15.w,
                    colorFilter: ColorFilter.mode(context.fgPrimary900, BlendMode.srcIn),
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
          const Spacer(),
          GestureDetector(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  'assets/images/bell.svg',
                  width: 30.w,
                  height: 30.w,
                  colorFilter: ColorFilter.mode(context.fgPrimary900, BlendMode.srcIn),
                ),
                Positioned(
                  right: 0.w,
                  top: 0.w,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
    );
  }
}

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
                onPressed: () => appRouter.push('/login'),
                child: Text('common.login'.tr()),
              ),
              SizedBox(width: 8.w),
              Button(
                width: 110,
                height: 40,
                variant: ButtonVariant.secondary,
                onPressed: () => appRouter.push('/register'),
                child: Text('common.register'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.bgPrimary,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'common.my.orders'.tr(),
                style: TextStyle(
                  fontSize: context.textSm,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                  height: context.leadingSm,
                ),
              ),
              Button(
                variant: ButtonVariant.text,
                onPressed: () => appRouter.push('/order/list'),
                height: 20.w,
                paddingX: 0,
                trailing: Icon(Icons.arrow_forward_ios, size: 12.w, color: context.textPrimary900),
                child: Text(
                  'common.view.all.order'.tr(),
                  style: TextStyle(
                    fontSize: context.textSm,
                    fontWeight: FontWeight.w500,
                    height: context.leadingSm,
                    color: context.textPrimary900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderItem(context, icon: CupertinoIcons.creditcard, label: 'To Pay', onTap: () => appRouter.push('/order/list?status=unpaid')),
              _buildOrderItem(context, icon: CupertinoIcons.cube_box, label: 'To Ship', onTap: () => appRouter.push('/order/list?status=paid')),
              _buildOrderItem(context, icon: Icons.local_shipping_outlined, label: 'To Receive', onTap: () => appRouter.push('/order/list?status=paid')),
              _buildOrderItem(context, icon: CupertinoIcons.star_circle, label: 'To Rate', onTap: () => appRouter.push('/order/list?status=paid')),
              // --- 售后入口 ---
              _buildOrderItem(context, icon: Icons.assignment_return_outlined, label: 'Refund', onTap: () => appRouter.push('/order/list?status=refunded')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24.w, color: context.fgPrimary900),
          SizedBox(height: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: context.textPrimary900,
              height: context.leadingXs,
            ),
          ),
        ],
      ),
    );
  }
}