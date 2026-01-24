// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_category_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductCategoryItem _$ProductCategoryItemFromJson(Map<String, dynamic> json) =>
    ProductCategoryItem(
      name: json['name'] as String,
      id: (json['id'] as num).toInt(),
    );

Map<String, dynamic> _$ProductCategoryItemToJson(
        ProductCategoryItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
    };
