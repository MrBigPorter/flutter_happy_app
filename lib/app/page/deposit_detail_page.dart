
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/components/base_scaffold.dart';

class WinnerDetailPage extends StatelessWidget {
  final String winnerId;

  const WinnerDetailPage({super.key, required this.winnerId});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      showBack: true,
      body: Center(
        child: Text('Details for winner ID: $winnerId'),
      ),
    );
  }
}