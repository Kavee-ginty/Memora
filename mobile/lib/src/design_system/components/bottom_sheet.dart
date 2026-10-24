import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class MemoraBottomSheet extends StatelessWidget {
  const MemoraBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.showCloseButton = true,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Widget? action;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final double maxSheetHeight = MediaQuery.sizeOf(context).height * 0.90;

    return Semantics(
      namesRoute: true,
      scopesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Container(
          decoration: const BoxDecoration(color: MemoraColors.surfaceCanvas, borderRadius: MemoraRadii.sheet),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: MemoraSpacing.space12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: MemoraColors.borderDefault, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MemoraSpacing.space24,
                  MemoraSpacing.space16,
                  MemoraSpacing.space16,
                  MemoraSpacing.space12,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(title, style: MemoraTypography.sectionTitle),
                          if (subtitle != null) ...<Widget>[
                            const SizedBox(height: MemoraSpacing.space4),
                            Text(subtitle!, style: MemoraTypography.metadata),
                          ],
                        ],
                      ),
                    ),
                    if (showCloseButton)
                      Semantics(
                        button: true,
                        label: 'Close sheet',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          color: MemoraColors.textPrimary,
                          tooltip: 'Close',
                          constraints: const BoxConstraints(
                            minWidth: MemoraSpacing.minTouchTarget,
                            minHeight: MemoraSpacing.minTouchTarget,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable body
              Flexible(
                child: SingleChildScrollView(padding: const EdgeInsets.all(MemoraSpacing.space24), child: child),
              ),
              // Sticky bottom action if provided
              if (action != null) ...<Widget>[
                const Divider(height: 1),
                Padding(padding: const EdgeInsets.all(MemoraSpacing.space16), child: action!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showMemoraBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  String? subtitle,
  Widget? action,
  bool showCloseButton = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return MemoraBottomSheet(
        title: title,
        subtitle: subtitle,
        action: action,
        showCloseButton: showCloseButton,
        child: child,
      );
    },
  );
}
