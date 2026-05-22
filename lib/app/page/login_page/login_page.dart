import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/providers/auth_provider.dart';
import 'package:flutter_app/core/services/test_mode_service.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/form/index.dart';
import 'package:flutter_app/utils/form/auth_forms/auth_forms.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_app/utils/time/countdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_app/utils/form/validation_messages.dart';

import 'package:flutter_app/core/services/auth/oauth_exception.dart';
import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';
import 'package:flutter_app/core/config/oauth_config.dart';

import 'package:flutter_app/app/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'login_page_logic.dart';
part 'login_page_ui.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with LoginPageLogic {
  @override
  Widget build(BuildContext context) {
    return buildUI(context);
  }
}
