import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectIdType extends StatelessWidget{
  final List<KycIdTypes> options;
  const SelectIdType({super.key, required this.options});
  @override
  Widget build(BuildContext context) {

    final maxHeight = MediaQuery.of(context).size.height * 0.4;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      child:  ListView.separated(
        itemCount: options.length,
        separatorBuilder: (context, index) => Divider(height: 1.h,color: context.borderSecondary,),
        itemBuilder: (context, index) {
          final option = options[index];
          return ListTile(
            contentPadding: EdgeInsets.all(0),
            title: Text(
              option.typeName,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: context.textPrimary900),
            ),
            trailing: Icon(Icons.chevron_right, size: 24.sp, color: context.fgTertiary600),
            onTap: () {
              Navigator.of(context).pop(option);
            },
          );
        },
      ),
    );
  }
}

