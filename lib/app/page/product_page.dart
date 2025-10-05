import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/featured_skeleton.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/components/tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/models/index.dart';
class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final categoryList = ref.watch(categoryProvider);
    final active = ref.watch(activeCategoryProvider);
    final products = ref.watch(productListProvider);

    return BaseScaffold(
      body: Column(
        children: [
          /// tabs category list
          categoryList.when(
              data: (data)=> Padding(
                padding: EdgeInsets.symmetric(vertical: 16.w),
                child: Tabs<ProductCategoryItem>(
                  data: data,
                  activeItem: active,
                  renderItem: (item) => Center(child: Text(item.name)),
                  onChangeActive: (item) => {
                    ref.read(activeCategoryProvider.notifier).state = item,
                  },
                ),
              ),
              error: (_,__)=> Tabs(data: [], activeItem: '', renderItem: (item)=> SizedBox.shrink(), onChangeActive: (item)=>{}),
              loading: ()=> Tabs(data: [], activeItem: '', renderItem: (item)=> SizedBox.shrink(), onChangeActive: (item)=>{}),
          ),
          // product list
          Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 16.w,right: 16.w,),
                child: products.when(
                    data: (list){
                      if(list.isEmpty) return Center(child: Text('No products') );
                       return GridView.builder(
                          padding: EdgeInsets.only(top:16.w,bottom: 20.w),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing:16.w,
                              crossAxisSpacing: 16.w,
                              childAspectRatio: 166.w/365.w
                          ),
                          itemBuilder: (context,index){
                            final item = list[index];
                            return ProductItem(
                                data: item,
                                imgHeight: 166,
                                imgWidth: 166,
                            );
                          },
                          itemCount: list.length,
                      );
                    },
                    error: (_,__)=> FeaturedSkeleton(),
                    loading: ()=> FeaturedSkeleton()
                ),
              )
          ),
        ],
      ),
      showBack: false,
    );
  }
}
