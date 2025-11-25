import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductGroupPage extends ConsumerStatefulWidget{
  final String? treasureId;
  const ProductGroupPage ({super.key, this.treasureId});

  @override
  ConsumerState<ProductGroupPage> createState() => _ProductGroupPageState();
}

class _ProductGroupPageState  extends ConsumerState<ProductGroupPage>{

  @override
  Widget build(BuildContext context) {

    final treasureId = widget.treasureId;

    return BaseScaffold(
      title: 'draw-team'.tr(),
      body: Center(
        child: Text('Product Group Page for treasureId: $treasureId'),
      ),
    );
  }
}