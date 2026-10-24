import 'package:flutter/material.dart';

/// Memora corner radius tokens as defined in Memora UI/UX Design Specification Section 4.4.
abstract final class MemoraRadii {
  // Numeric radius values
  static const double primaryCardValue = 24.0;
  static const double controlValue = 16.0;
  static const double compactCardValue = 16.0;
  static const double chipValue = 12.0;
  static const double pillValue = 999.0;
  static const double dialogValue = 24.0;
  static const double sheetValue = 24.0;

  // BorderRadius helpers
  static const BorderRadius primaryCard = BorderRadius.all(
    Radius.circular(primaryCardValue),
  );
  static const BorderRadius control = BorderRadius.all(
    Radius.circular(controlValue),
  );
  static const BorderRadius compactCard = BorderRadius.all(
    Radius.circular(compactCardValue),
  );
  static const BorderRadius chip = BorderRadius.all(Radius.circular(chipValue));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(pillValue));
  static const BorderRadius dialog = BorderRadius.all(
    Radius.circular(dialogValue),
  );
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(sheetValue),
  );
}
