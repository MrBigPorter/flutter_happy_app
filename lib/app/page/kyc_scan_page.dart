import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KycScanPage extends ConsumerWidget{
  final KycIdTypes kycIdType;
  const KycScanPage({super.key, required this.kycIdType});
  
  

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    
    return BaseScaffold(
      title: 'KYC Scan Page',
      body: Center(
        child: Text('This is the KYC Scan Page'),
      ),
    );
  }
}