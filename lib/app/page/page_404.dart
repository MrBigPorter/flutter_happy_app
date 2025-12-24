import 'package:flutter/cupertino.dart';
import 'package:flutter_app/components/base_scaffold.dart';

class Page404 extends StatelessWidget{
  const Page404({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Center(
        child: Text(
          '404\nPage Not Found',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}