import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

void showMemoraToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
  Widget? icon,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      backgroundColor: MemoraColors.textPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: MemoraRadii.compactCard,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space24,
        vertical: MemoraSpacing.space16,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space16,
        vertical: MemoraSpacing.space12,
      ),
      content: Semantics(
        liveRegion: true,
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              IconTheme(
                data: const IconThemeData(
                  color: MemoraColors.brandAqua,
                  size: 20,
                ),
                child: icon,
              ),
              const SizedBox(width: MemoraSpacing.space12),
            ],
            Expanded(
              child: Text(
                message,
                style: MemoraTypography.body.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
