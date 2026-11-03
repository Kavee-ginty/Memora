import 'package:flutter/material.dart';

import '../../../../design_system/components/dialog.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/radii.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../design_system/tokens/typography.dart';
import '../../application/ingestion_flow_controller.dart';

/// One selected source with its queued/uploading/processing/ready/unsupported/
/// failed state, byte size and remove confirmation (UI/UX §9.9).
class SourceTile extends StatelessWidget {
  const SourceTile({
    super.key,
    required this.source,
    this.onRetry,
    this.onRemove,
  });

  final LocalSource source;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final bool isProblem =
        source.status == LocalSourceState.unsupported ||
        source.status == LocalSourceState.failed;

    return Container(
      padding: const EdgeInsets.all(MemoraSpacing.space12),
      decoration: BoxDecoration(
        color: MemoraColors.surfaceCanvas,
        borderRadius: MemoraRadii.compactCard,
        border: Border.all(
          color: isProblem
              ? MemoraColors.feedbackCritical
              : MemoraColors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  _iconFor(source.mediaType),
                  color: isProblem
                      ? MemoraColors.feedbackCritical
                      : MemoraColors.brandBlue,
                ),
              ),
              const SizedBox(width: MemoraSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      source.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MemoraTypography.bodyStrong,
                    ),
                    const SizedBox(height: MemoraSpacing.space4),
                    Text(
                      '${formatSourceSize(source.byteSize)} · ${_statusLabel(source)}',
                      style: MemoraTypography.metadata,
                    ),
                  ],
                ),
              ),
              if (onRetry != null)
                IconButton(
                  onPressed: onRetry,
                  tooltip: 'Retry ${source.name}',
                  icon: const Icon(Icons.refresh),
                  color: MemoraColors.brandBlue,
                ),
              if (onRemove != null)
                IconButton(
                  onPressed: () => _confirmRemove(context),
                  tooltip: 'Remove ${source.name}',
                  icon: const Icon(Icons.close),
                  color: MemoraColors.textSecondary,
                ),
            ],
          ),
          if (source.status == LocalSourceState.uploading) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space8),
            LinearProgressIndicator(
              value: source.progress,
              minHeight: 6,
              borderRadius: MemoraRadii.pill,
              color: MemoraColors.brandBlue,
              backgroundColor: MemoraColors.surfaceOcean,
              semanticsLabel: 'Uploading ${source.name}',
              semanticsValue: '${(source.progress * 100).round()} percent',
            ),
          ],
          if (isProblem && source.failure != null) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space8),
            Text(
              source.failure!.message,
              style: MemoraTypography.metadata.copyWith(
                color: MemoraColors.feedbackCritical,
              ),
            ),
            if (source.failure!.nextAction != null)
              Text(
                source.failure!.nextAction!,
                style: MemoraTypography.metadata,
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MemoraDialog(
          title: 'Remove file?',
          message:
              'This file will be removed from this material. You can add it '
              'again before extracting concepts.',
          primaryActionLabel: 'Remove',
          isDestructive: true,
          onPrimaryAction: () => Navigator.of(dialogContext).pop(true),
          secondaryActionLabel: 'Keep file',
          onSecondaryAction: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );
    if (remove == true) onRemove?.call();
  }
}

String _statusLabel(LocalSource source) {
  return switch (source.status) {
    LocalSourceState.queued => 'Queued',
    LocalSourceState.uploading =>
      'Uploading ${(source.progress * 100).round()}%',
    LocalSourceState.processing => 'Processing',
    LocalSourceState.ready => 'Ready',
    LocalSourceState.unsupported => 'Unsupported',
    LocalSourceState.failed => 'Failed',
  };
}

IconData _iconFor(String mediaType) {
  if (mediaType == 'application/pdf') return Icons.picture_as_pdf_outlined;
  return Icons.image_outlined;
}

/// Formats a byte count without pretending to know page counts.
String formatSourceSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    final kilobytes = bytes / 1024;
    return '${kilobytes.toStringAsFixed(kilobytes >= 10 ? 0 : 1)} KB';
  }
  final megabytes = bytes / (1024 * 1024);
  return '${megabytes.toStringAsFixed(1)} MB';
}
