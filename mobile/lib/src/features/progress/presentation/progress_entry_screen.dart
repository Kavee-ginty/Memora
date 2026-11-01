import 'package:flutter/material.dart';

import '../../../design_system/components/app_header.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/mora.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Minimal honest root host for the Progress tab until T16.
class ProgressEntryScreen extends StatelessWidget {
  const ProgressEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: const MemoraHeader.root(title: 'Progress'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space24,
            vertical: MemoraSpacing.space24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const MoraPlacement(
                state: MoraState.think,
                size: 96,
                isDecorative: true,
              ),
              const SizedBox(height: MemoraSpacing.space24),
              Semantics(
                header: true,
                child: const Text(
                  'Seabed and Reef Progress',
                  textAlign: TextAlign.center,
                  style: MemoraTypography.pageTitle,
                ),
              ),
              const SizedBox(height: MemoraSpacing.space12),
              const Text(
                'Continuous seabed growth, memory retention metrics, and reef recovery projections will be available in milestone T16.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: MemoraColors.textSecondary,
                ),
              ),
              const SizedBox(height: MemoraSpacing.space24),
              const MemoraCard(
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF0072B2)),
                    SizedBox(width: MemoraSpacing.space12),
                    Expanded(
                      child: Text(
                        'Your learning progress and completed daily missions will contribute to your Physics reef growth.',
                        style: MemoraTypography.metadata,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
