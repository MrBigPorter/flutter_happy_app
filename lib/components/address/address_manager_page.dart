import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddressManagerPage extends ConsumerStatefulWidget {

  final VoidCallback? onClose;

  const AddressManagerPage({super.key, this.onClose});

  @override
  ConsumerState<AddressManagerPage> createState() => _AddressManagerPageState();
}

class _AddressManagerPageState extends ConsumerState<AddressManagerPage> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableScaffold(
        heroTag: 'add-address-manager',
        onDismiss: (){
          if(widget.onClose != null){
            widget.onClose!();
          }
        },
        bodyBuilder: (context, scrollController, physics){
          return SingleChildScrollView(
            controller: scrollController,
            physics: physics,
            padding: EdgeInsets.zero,
            child: Material(
              child: Column(
                children: [

                ],
              ),
            ),
          );
        },
    );
  }
}