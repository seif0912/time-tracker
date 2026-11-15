import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const lightCard = [
    BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const lightButton = [
    BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const darkCard = [
    BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const darkButton = [
    BoxShadow(color: Color(0x30000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}
