import 'package:flutter/cupertino.dart';

class PaymentPage extends StatefulWidget{
  const PaymentPage({super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>{
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Payment Page'),
      ),
      child: Center(
        child: Text('This is the Payment Page'),
      ),
    );
  }
}