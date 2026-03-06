import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/kyc_information_confirm_page.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/upload_progress_dialog.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/providers/kyc_provider.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_config.dart';
import 'package:flutter_app/utils/camera/services/liveness_service.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/components/select_id_type.dart';
import 'package:flutter_app/utils/camera/services/unified_kyc_cuard.dart';
import 'package:flutter_app/app/routes/app_router.dart';

part 'kyc_verify_logic.dart';
part 'kyc_verify_ui.dart';

class KycVerifyPage extends ConsumerStatefulWidget {
  const KycVerifyPage({super.key});

  @override
  ConsumerState<KycVerifyPage> createState() => _KycVerifyPageState();
}

class _KycVerifyPageState extends ConsumerState<KycVerifyPage> with KycVerifyLogic {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'kyc-verify'.tr(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 140.h,
          ),
          child: const _StepList(),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        onStartPressed: _onStartKycPressed,
      ),
    );
  }
}