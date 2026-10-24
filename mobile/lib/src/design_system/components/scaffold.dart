import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class MemoraScaffold extends StatelessWidget {
  const MemoraScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.offlineBanner,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.applyResponsiveGutter = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? offlineBanner;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool applyResponsiveGutter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? MemoraColors.surfaceSoft,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        top: appBar == null,
        bottom: bottomNavigationBar == null,
        child: Column(
          children: <Widget>[
            ?offlineBanner,
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = constraints.maxWidth;
                  final double gutter = applyResponsiveGutter
                      ? MemoraSpacing.gutterForWidth(width)
                      : 0.0;
                  final double maxContentWidth =
                      MemoraSpacing.maxContentWidthFor(width);

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: gutter),
                        child: body,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
