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

// Coupon and Modal providers
import 'package:flutter_app/core/providers/coupon_provider.dart';
import 'package:flutter_app/ui/modal/index.dart';


import 'package:flutter_app/core/services/customer_service/customer_service_helper.dart';

// Link to the UI part file
part 'me_page_ui.dart';


/// Main Profile Page (Me Page)
class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isAuthenticated) {
        ref.read(walletProvider.notifier).fetchBalance();
      }
    });
  }

  /// Pull-to-refresh action: Fetches all the latest user data
  Future<void> _onRefresh() async {
    if (!ref.read(authProvider).isAuthenticated) return;

    await ref.read(walletProvider.notifier).fetchBalance();
    await ref.refresh(myCouponsByStatusProvider(0).future);

  }

  @override
  Widget build(BuildContext context) {



    // Check if user is authenticated
    final isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );
    // Watch wallet balance state
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
            // ... 这里保留你原来的 slivers 代码完全不变 ...
            // 1. Top Area: Avatar & Basic Info
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                  child: isAuthenticated ? _LoginTopArea() : _UnLoginTopArea(),
                ),
              ),
            ),

            // 2. Vouchers Area (Only visible if logged in)
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

            // 4. Asset / Wallet Management Card
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _WalletArea(balance: balance),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),

            // 5. Core Menu Card (Grid)
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _MenuArea(isAuthenticated: isAuthenticated),
                ),
              ),
            ),

            // Bottom padding
            SliverToBoxAdapter(child: SizedBox(height: 40.h)),
          ],
        ),
      ),
    );
  }
}