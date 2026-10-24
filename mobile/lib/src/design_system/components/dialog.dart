import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'button.dart';

class MemoraDialog extends StatelessWidget {
  const MemoraDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.isDestructive = false,
    this.icon,
  });

  final String title;
  final String message;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool isDestructive;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MemoraColors.surfaceCanvas,
      shape: const RoundedRectangleBorder(
        borderRadius: MemoraRadii.dialog,
        side: BorderSide(color: MemoraColors.borderDefault),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space24,
        vertical: MemoraSpacing.space24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(MemoraSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Align(alignment: Alignment.centerLeft, child: icon!),
                const SizedBox(height: MemoraSpacing.space16),
              ],
              Text(title, style: MemoraTypography.sectionTitle),
              const SizedBox(height: MemoraSpacing.space12),
              Text(
                message,
                style: MemoraTypography.body.copyWith(
                  color: MemoraColors.textSecondary,
                ),
              ),
              const SizedBox(height: MemoraSpacing.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (secondaryActionLabel != null) ...<Widget>[
                    Expanded(
                      child: MemoraButton(
                        label: secondaryActionLabel!,
                        variant: MemoraButtonVariant.tertiary,
                        onPressed:
                            onSecondaryAction ??
                            () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: MemoraSpacing.space12),
                  ],
                  Expanded(
                    child: MemoraButton(
                      label: primaryActionLabel,
                      variant: isDestructive
                          ? MemoraButtonVariant.destructive
                          : MemoraButtonVariant.primary,
                      onPressed: onPrimaryAction,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showMemoraDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required String primaryActionLabel,
  required VoidCallback onPrimaryAction,
  String? secondaryActionLabel,
  VoidCallback? onSecondaryAction,
  bool isDestructive = false,
  Widget? icon,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) {
      return MemoraDialog(
        title: title,
        message: message,
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        secondaryActionLabel: secondaryActionLabel,
        onSecondaryAction: onSecondaryAction,
        isDestructive: isDestructive,
        icon: icon,
      );
    },
  );
}
