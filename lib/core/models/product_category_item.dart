
import 'package:json_annotation/json_annotation.dart';

part 'product_category_item.g.dart';

@JsonSerializable()
class ProductCategoryItem {
  @JsonKey(name: 'name')
  final String name;
  @JsonKey(name: 'products_category_id')
  final int productsCategoryId;

  ProductCategoryItem({
      required this.name,
      required this.productsCategoryId,
  });

  factory ProductCategoryItem.fromJson(Map<String, dynamic> json) => _$ProductCategoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$ProductCategoryItemToJson(this);

  @override
  String toString() => toJson().toString();
}