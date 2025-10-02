import 'package:flutter/cupertino.dart';

/// 行高（倍数）
extension LeadingTokensX on BuildContext {
  // 细到粗：3xs < 2xs < xs < sm < md < lg/normal < xl < 2xl
  double get leading3xs => 1.05;   // 极紧（原 1.00，略上调以避免裁切）
  double get leading2xs => 1.10;   // 非常紧
  double get leadingXs  => 1.20;   // 很紧（自定义，介于 tight 与 snug 之间）
  double get leadingSm  => 1.25;   // ≈ Tailwind tight
  double get leadingMd  => 1.375;  // ≈ Tailwind snug
  double get leadingLg  => 1.50;   // ≈ Tailwind normal
  double get leadingNormal => 1.50; // 同义别名，更语义化
  double get leadingXl  => 1.625;  // ≈ Tailwind relaxed
  double get leading2xl => 2.00;   // ≈ Tailwind loose
}

/// 让写法更顺手（可选）
extension TextStyleLeadingX on TextStyle {
  TextStyle lh(double h) => copyWith(height: h);
}