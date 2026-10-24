import 'package:flutter/material.dart';

import 'colors.dart';

/// Memora elevation and border styling tokens as defined in Memora UI/UX Design Specification Section 4.4.
abstract final class MemoraElevations {
  static const BoxShadow subtleShadow = BoxShadow(
    color: Color(0x0A0B1A2C),
    blurRadius: 10,
    offset: Offset(0, 3),
    spreadRadius: 0,
  );

  static const List<BoxShadow> cardShadows = <BoxShadow>[subtleShadow];

  static const BorderSide defaultBorderSide = BorderSide(color: MemoraColors.borderDefault, width: 1.0);

  static const BorderSide focusBorderSide = BorderSide(color: MemoraColors.focus, width: 2.0);

  static const BorderSide selectedBorderSide = BorderSide(color: MemoraColors.brandPrimary, width: 2.0);
}
