import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/me_components/voucher.dart';
import 'package:flutter_app/app/page/me_components/voucher_list.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/core/store/wallet_store.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 1. Import the coupon provider
import 'package:flutter_app/core/providers/coupon_provider.dart';
import 'package:flutter_app/ui/modal/index.dart';

const String kOfficialServiceId = '666888';

class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  Future<void> _onRefresh() async {
    await ref.read(walletProvider.notifier).fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );
    final balance = ref.watch(walletProvider);

    return BaseScaffold(
      showBack: false,
      elevation: 0,
      backgroundColor: context.bgSecondary,
      body: LuckyCustomMaterialIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: platformScrollPhysics(),
          slivers: [
            // 1. Top Area: Avatar & Basic Info
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                  child: isAuthenticated ? _LoginTopArea() : _UnLoginTopArea(),
                ),
              ),
            ),

            if (isAuthenticated) ...[
              const SliverToBoxAdapter(
                child: RepaintBoundary(child: VoucherList()),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            ],

            // 3. Order Management Card
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _OrderArea(),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),

            // 4. Asset Management Card
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _WalletArea(balance: balance),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),

            // 5. Core Menu Card
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _MenuArea(),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 40.h)),
          ],
        ),
      ),
    );
  }
}

// ===================== Sub-component: Logged-in Top Area =====================
class _LoginTopArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Avatar(),
      SizedBox(height: 16.h),
      const Voucher(),
    ],
  );
}

class _Avatar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final String nickname = user?.nickname ?? "User";
    final String displayNickname = nickname.length > 15
        ? "${nickname.substring(0, 15)}..."
        : nickname;
    final String userId = user?.id ?? "---";

    return Row(
      children: [
        Container(
          width: 64.w,
          height: 64.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/images/Avatar01.png', fit: BoxFit.cover),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, $displayNickname",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6.h),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: userId));
                  RadixToast.success("ID Copied");
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: context.alphaBlack5,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "ID: ${userId.substring(0, 10).toUpperCase()}",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textSecondary700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.copy_rounded,
                        size: 12.w,
                        color: context.textSecondary700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================== Sub-component: Unlogged Top Area =====================
class _UnLoginTopArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'login.tip'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 24.h),
          Button(
            width: double.infinity,
            height: 48.h,
            onPressed: () => appRouter.push('/login'),
            child: Text(
              'common.login_register'.tr(),
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Sub-component: Order Area =====================
class _OrderArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'common.my.orders'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary900,
                ),
              ),
              GestureDetector(
                onTap: () => appRouter.push('/order/list'),
                child: Row(
                  children: [
                    Text(
                      'common.view.all.order'.tr(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textSecondary700,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16.w,
                      color: context.textSecondary700,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOrderItem(
                context,
                CupertinoIcons.creditcard,
                'To Pay',
                onTap: () => appRouter.push('/order/list?status=unpaid'),
              ),
              _buildOrderItem(
                context,
                CupertinoIcons.cube_box,
                'To Ship',
                onTap: () => appRouter.push('/order/list?status=paid'),
              ),
              _buildOrderItem(
                context,
                Icons.local_shipping_outlined,
                'To Receive',
                onTap: () => appRouter.push('/order/list?status=shipped'),
              ),
              _buildOrderItem(
                context,
                Icons.assignment_return_outlined,
                'Refund',
                onTap: () => appRouter.push('/order/list?status=refunded'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
      BuildContext context,
      IconData icon,
      String label, {
        required VoidCallback onTap,
      }) =>
      InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 28.w, color: context.fgPrimary900),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: context.textPrimary900,
              ),
            ),
          ],
        ),
      );
}

// ===================== Sub-component: Wallet Area =====================
class _WalletArea extends StatelessWidget {
  final Balance balance;

  const _WalletArea({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'common.wallet'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildBalanceCard(
                context,
                title: 'common.balance'.tr(),
                value: balance.realBalance,
                actionText: 'Top Up',
                onTap: () => appRouter.push('/me/wallet/deposit'),
              ),
              SizedBox(width: 12.w),
              _buildBalanceCard(
                context,
                title: 'common.treasureCoins'.tr(),
                value: balance.coinBalance,
                actionText: 'Details',
                onTap: () => appRouter.push('/me/wallet'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, {
        required String title,
        required double value,
        required String actionText,
        required VoidCallback onTap,
      }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: context.alphaBlack5,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.textSecondary700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10.w,
                    color: context.textSecondary700,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                FormatHelper.formatCurrency(value),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                actionText,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textBrandPrimary900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== Sub-component: 9-Grid Menu =====================
class _MenuArea extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<({String text, Widget icon, VoidCallback onTap})> menuItems = [
      (
      text: 'common.withdraw'.tr(),
      icon: Icon(
        Icons.account_balance_wallet_outlined,
        size: 26.w,
        color: context.fgSecondary700,
      ),
      onTap: () => appRouter.push('/me/wallet/withdraw'),
      ),
      (
      text: 'common.customer.service'.tr(),
      icon: Icon(
        Icons.headset_mic_outlined,
        size: 26.w,
        color: context.fgSecondary700,
      ),
      onTap: () => appRouter.push('/chat/room/$kOfficialServiceId'),
      ),
      (
      text: 'common.faq'.tr(),
      icon: _buildIcon(context, 'assets/images/faq.svg'),
      onTap: () => appRouter.push('/faq'),
      ),
      (
      text: 'common.setting'.tr(),
      icon: _buildIcon(context, 'assets/images/setting.svg'),
      onTap: () => appRouter.push('/setting'),
      ),
      // 2. Integrated Redeem Action using RadixModal
      (
      text: 'Redeem',
      icon: Icon(
        CupertinoIcons.gift,
        size: 26.w,
        color: context.fgSecondary700,
      ),
      onTap: () {
        final TextEditingController controller = TextEditingController();

        RadixModal.show(
          title: 'Redeem Promo Code',
          confirmText: 'Redeem',
          cancelText: 'Cancel',
          builder: (ctx, close) {
            return Padding(
              padding: EdgeInsets.only(top: 8.w, bottom: 4.w),
              child: CupertinoTextField(
                controller: controller,
                placeholder: 'Enter code (e.g. LUCKY2026)',
                textCapitalization: TextCapitalization.characters,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.bgSecondary,
                  border: Border.all(color: context.borderPrimary),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary900,
                ),
              ),
            );
          },
          onConfirm: (close) async {
            final code = controller.text.trim();
            if (code.isEmpty) return;

            try {
              // 1. 等待 API 结果 (此时 RadixModal 内部自动有 Loading 效果)
              final message = await ref.read(couponActionProvider.notifier).redeem(code);

              close();

              // 3. 关完之后再弹 Toast，这样不会引起 UI 状态机的并发冲突
              RadixToast.success(message);

            } catch (e) {
              // 进到这里说明确实是网络或后端报错了
              debugPrint('Redeem failed: $e');
              RadixToast.error('Invalid or expired code');
            }
          },
        );
      },
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 24.h,
          crossAxisSpacing: 8.w,
          childAspectRatio: 0.85,
        ),
        itemCount: menuItems.length,
        itemBuilder: (ctx, i) => InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            menuItems[i].onTap();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              menuItems[i].icon,
              SizedBox(height: 10.h),
              Text(
                menuItems[i].text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary900,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, String asset) => SvgPicture.asset(
    asset,
    width: 26.w,
    height: 26.w,
    colorFilter: ColorFilter.mode(context.fgSecondary700, BlendMode.srcIn),
  );
}