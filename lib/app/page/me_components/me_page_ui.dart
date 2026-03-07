part of 'me_page.dart';

/// Displays user avatar and active vouchers when authenticated
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

/// Displays user avatar, nickname, and copyable ID
class _Avatar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final String nickname = user?.nickname ?? "User";
    final String displayNickname = nickname.length > 15
        ? "${nickname.substring(0, 15)}..."
        : nickname;

    final String userId = user?.id ?? "---";
    final String displayId = userId.length > 10 ? userId.substring(0, 10) : userId;

    return Row(
      children: [
        // Avatar Image Box
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
        // User Info Column
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
              // Copyable User ID Badge
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

/// Displays a login prompt when the user is not authenticated
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

/// Displays e-commerce style order statuses
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
          // Header Row
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
          // Status Items Row
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

  /// Helper to build individual order status icons
  Widget _buildOrderItem(
    BuildContext context,
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) => InkWell(
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

/// Displays user balance and treasure coins with quick action buttons
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
                onTap: () =>
                    RadixToast.info('Treasure Coins details coming soon!'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to build balance cards (Real balance / Coins)
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

// ===================== Sub-component: Grid Menu =====================

/// Grid layout for additional tools (Withdraw, History, Support, Settings, Redeem)
class _MenuArea extends ConsumerWidget {

  final bool isAuthenticated;

  const _MenuArea({required this.isAuthenticated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defines the grid items and their respective actions
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
      // NEW: Deposit History Entry
      (
        text: 'common.deposit.history'.tr(),
        icon: Icon(
          Icons.history_outlined,
          size: 26.w,
          color: context.fgSecondary700,
        ),
        onTap: () =>
            appRouter.push('/me/wallet/transaction/record?tab=deposit'),
      ),
      // NEW: Withdraw History Entry
      (
        text: 'common.withdraw.history'.tr(),
        icon: Icon(
          Icons.receipt_long_outlined,
          size: 26.w,
          color: context.fgSecondary700,
        ),
        onTap: () =>
            appRouter.push('/me/wallet/transaction/record?tab=withdraw'),
      ),
      (
        text: 'common.customer.service'.tr(),
        icon: Icon(
          Icons.headset_mic_outlined,
          size: 26.w,
          color: context.fgSecondary700,
        ),
        onTap: () async {
          if(!isAuthenticated) {
            appRouter.push('/login');
            return;
          }
          CustomerServiceHelper.startChat();
        },
      ),
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
                // Wait for API result while RadixModal handles loading state
                final message = await ref
                    .read(couponActionProvider.notifier)
                    .redeem(code);

                close();
                RadixToast.success(message);
              } catch (e) {
                debugPrint('Redeem failed: $e');
                RadixToast.error('Invalid or expired code');
              }
            },
          );
        },
      ),
      (
        text: 'common.setting'.tr(),
        icon: _buildIcon(context, 'assets/images/setting.svg'),
        onTap: () => appRouter.push('/setting'),
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

  /// Helper to build SVG icons consistently
  Widget _buildIcon(BuildContext context, String asset) => SvgPicture.asset(
    asset,
    width: 26.w,
    height: 26.w,
    colorFilter: ColorFilter.mode(context.fgSecondary700, BlendMode.srcIn),
  );
}
