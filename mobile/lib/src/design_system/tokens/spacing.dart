/// Memora spacing tokens and layout metrics as defined in Memora UI/UX Design Specification Section 5.
abstract final class MemoraSpacing {
  // Spacing scale: 4, 8, 12, 16, 24, 32, 48
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Responsive layout breakpoints and bounds
  static const double narrowBreakpoint = 360.0;
  static const double tabletBreakpoint = 768.0;

  static const double gutterNarrow = 16.0;
  static const double gutterStandard = 24.0;

  static const double maxContentWidthMobile = 560.0;
  static const double maxContentWidthTablet = 720.0;

  // Touch target minimums (UIX-030)
  static const double minTouchTarget = 48.0;
  static const double absoluteMinTouchTarget = 24.0;

  /// Returns the horizontal gutter padding for a given viewport width.
  static double gutterForWidth(double width) {
    if (width < narrowBreakpoint) {
      return gutterNarrow;
    }
    return gutterStandard;
  }

  /// Returns the maximum content constraint for a given viewport width.
  static double maxContentWidthFor(double width) {
    if (width >= tabletBreakpoint) {
      return maxContentWidthTablet;
    }
    return maxContentWidthMobile;
  }
}
