import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/tabs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final tabs = ["All", "Hot", "Tech", "Home", "Cash", "Other"];
  String active = "All";

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical:16.w),
            child: Tabs<String>(
                data: tabs,
                activeItem: active,
                renderItem: (item)=>Center(
                  child: Text(item),
                ),
                onChangeActive: (item)=>{
                  setState(() {
                    active = item;
                  })
                }
            ),
          )
        ],
      ),
      showBack: false,
    );
  }
}