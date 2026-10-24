import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'button.dart';

class MemoraSkeleton extends StatefulWidget {
  const MemoraSkeleton({super.key, this.width, this.height = 16.0, this.borderRadius, this.shape = BoxShape.rectangle});

  const MemoraSkeleton.card({super.key, this.width, this.height = 120.0})
    : borderRadius = MemoraRadii.primaryCard,
      shape = BoxShape.rectangle;

  const MemoraSkeleton.text({super.key, this.width = double.infinity, this.height = 16.0})
    : borderRadius = MemoraRadii.chip,
      shape = BoxShape.rectangle;

  const MemoraSkeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = null,
      shape = BoxShape.circle;

  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  @override
  State<MemoraSkeleton> createState() => _MemoraSkeletonState();
}

class _MemoraSkeletonState extends State<MemoraSkeleton> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (disableAnimations) {
      _controller?.stop();
      _controller?.dispose();
      _controller = null;
      _animation = null;
    } else if (_controller == null) {
      _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);
      _animation = Tween<double>(
        begin: 0.35,
        end: 0.75,
      ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations = MediaQuery.disableAnimationsOf(context);

    final Widget skeletonBox = _animation != null && !disableAnimations
        ? AnimatedBuilder(
            animation: _animation!,
            builder: (BuildContext context, Widget? child) {
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: MemoraColors.borderDefault.withValues(alpha: _animation!.value),
                  shape: widget.shape,
                  borderRadius: widget.shape == BoxShape.circle ? null : widget.borderRadius,
                ),
              );
            },
          )
        : Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: MemoraColors.borderDefault.withValues(alpha: 0.5),
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle ? null : widget.borderRadius,
            ),
          );

    return Semantics(label: 'Loading...', child: skeletonBox);
  }
}

/// A loading container that renders skeletons and after 10 seconds shows a plain-language
/// recovery status with options to retry or leave (UIX-019).
class MemoraLoadingTimeoutView extends StatefulWidget {
  const MemoraLoadingTimeoutView({
    super.key,
    required this.skeleton,
    this.loadingMessage = 'Loading your learning content...',
    this.timeoutMessage = 'This is taking longer than expected. You can wait, retry, or return Home.',
    this.onRetry,
    this.onLeave,
    this.timeout = const Duration(seconds: 10),
  });

  final Widget skeleton;
  final String loadingMessage;
  final String timeoutMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onLeave;
  final Duration timeout;

  @override
  State<MemoraLoadingTimeoutView> createState() => _MemoraLoadingTimeoutViewState();
}

class _MemoraLoadingTimeoutViewState extends State<MemoraLoadingTimeoutView> {
  bool _hasTimedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, () {
      if (mounted) {
        setState(() {
          _hasTimedOut = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasTimedOut) {
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.all(MemoraSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.access_time_rounded, size: 40, color: MemoraColors.brandBlue),
              const SizedBox(height: MemoraSpacing.space16),
              Text(widget.timeoutMessage, style: MemoraTypography.body, textAlign: TextAlign.center),
              const SizedBox(height: MemoraSpacing.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (widget.onLeave != null) ...<Widget>[
                    Expanded(
                      child: MemoraButton(
                        label: 'Leave',
                        variant: MemoraButtonVariant.secondary,
                        onPressed: widget.onLeave,
                      ),
                    ),
                    const SizedBox(width: MemoraSpacing.space12),
                  ],
                  if (widget.onRetry != null)
                    Expanded(
                      child: MemoraButton(
                        label: 'Retry',
                        variant: MemoraButtonVariant.primary,
                        onPressed: () {
                          setState(() {
                            _hasTimedOut = false;
                          });
                          _startTimer();
                          widget.onRetry?.call();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        widget.skeleton,
        const SizedBox(height: MemoraSpacing.space16),
        Semantics(
          liveRegion: true,
          child: Text(
            widget.loadingMessage,
            style: MemoraTypography.metadata.copyWith(color: MemoraColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
