import 'package:flutter/cupertino.dart';
import 'package:flutter_app/components/base_scaffold.dart';

import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class PaymentPage extends ConsumerStatefulWidget{
  final PagePaymentParams params;
  const PaymentPage({super.key, required this.params});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage>{
  @override
  Widget build(BuildContext context) {
    print('PaymentPage params: ${widget.params}');
    return BaseScaffold(
      title: 'checkout',
      body: Center(
        child: Text('payment'),
      ),
    );
  }
}