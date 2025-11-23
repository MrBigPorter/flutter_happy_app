
import 'package:json_annotation/json_annotation.dart';

part 'product_category_item.g.dart';

@JsonSerializable()
class ProductCategoryItem {
  final String name;
  final int id;

  ProductCategoryItem({
      required this.name,
      required this.id,
  });

  factory ProductCategoryItem.fromJson(Map<String, dynamic> json) => _$ProductCategoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$ProductCategoryItemToJson(this);

  @override
  String toString() => toJson().toString();
}
