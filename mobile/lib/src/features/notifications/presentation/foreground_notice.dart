import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routing/app_router.dart';

import '../application/deep_link_controller.dart';
import '../application/push_registration_controller.dart';
import '../domain/deep_link_coordinator.dart';
import '../domain/notification_intent.dart';
import '../domain/notification_message.dart';
import 'notification_copy.dart';

/// Whether the current route is an active answer that must never be
/// interrupted (Flow §13.2, D11): mission item, feedback or explanation
/// surfaces beneath a mission, and the quiz.
bool _isActiveAnswerRoute(String? currentPath) {
  if (currentPath == null) {
    return false;
  }
  // Mission previews are safe; only item/feedback/explanation surfaces
  // beneath a mission are active answers.
  if (currentPath.startsWith('/missions/') &&
      !currentPath.endsWith('/preview')) {
    return true;
  }
  return currentPath.startsWith('/quiz');
}

/// Reader for the current route path from the application router, resolved
/// at call time so route changes are always observed (a cached value could
/// hide an active-answer route reached after the first read). Widget tests
/// override it to simulate routes.
final currentRoutePathProvider = Provider<String? Function()>((ref) {
  final router = ref.watch(appRouterProvider);
  return () {
    try {
      return router.routerDelegate.currentConfiguration.last.matchedLocation;
    } on Exception catch (_) {
      return null;
    }
  };
});

/// Renders one non-blocking foreground notice above the app (UI/UX §6.6):
/// visible long enough to read, announced politely, tap consumes the intent
/// through the deep-link coordinator, dismissal changes nothing.
///
/// Notices arriving while an active answer is on screen (D11) queue and
/// surface only after the route leaves the answer surface.
typedef RoutePathReader = String? Function();

class ForegroundNoticeHost extends ConsumerStatefulWidget {
  final Widget child;

  /// Optional override for reading the current route path; production uses
  /// [currentRoutePathProvider] (router-backed). Widget tests inject a
  /// mutable reader to simulate route changes.
  final RoutePathReader? routePathReader;

  const ForegroundNoticeHost({
    super.key,
    required this.child,
    this.routePathReader,
  });

  @override
  ConsumerState<ForegroundNoticeHost> createState() =>
      _ForegroundNoticeHostState();
}

class _ForegroundNoticeHostState extends ConsumerState<ForegroundNoticeHost> {
  static const Duration _visibleDuration = Duration(seconds: 6);

  StreamSubscription<NotificationMessage>? _foregroundSubscription;
  final List<NotificationMessage> _queue = <NotificationMessage>[];
  NotificationMessage? _visible;
  Timer? _visibleTimer;

  @override
  void initState() {
    super.initState();
    _foregroundSubscription = ref
        .read(notificationGatewayProvider)
        .foregroundMessages()
        .listen(_enqueue);
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _visibleTimer?.cancel();
    super.dispose();
  }

  String? _currentPath() {
    final RoutePathReader reader =
        widget.routePathReader ?? ref.read(currentRoutePathProvider);
    return reader();
  }

  void _enqueue(NotificationMessage message) {
    if (!mounted) {
      return;
    }
    if (_isActiveAnswerRoute(_currentPath())) {
      _queue.add(message);
      return;
    }
    if (_visible != null) {
      _queue.add(message);
      return;
    }
    _show(message);
  }

  void _show(NotificationMessage message) {
    setState(() => _visible = message);
    _visibleTimer?.cancel();
    _visibleTimer = Timer(_visibleDuration, () {
      if (mounted && identical(_visible, message)) {
        setState(() => _visible = null);
        _drainQueue();
      }
    });
  }

  void _drainQueue() {
    if (!mounted || _visible != null || _queue.isEmpty) {
      return;
    }
    if (_isActiveAnswerRoute(_currentPath())) {
      return;
    }
    _show(_queue.removeAt(0));
  }

  Future<void> _onTap(NotificationMessage message) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _visible = null);
    final decision = await ref
        .read(deepLinkControllerProvider.notifier)
        .handleTapData(message.data);
    // Brief fallback explanations surface after the navigation (Flow §13.1:
    // invalid links "resolve to the stable parent with a brief explanation").
    final explanation = decision.explanationLocKey;
    if (explanation != null && messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          key: const ValueKey('notice_explanation'),
          content: Text(NotificationCopy.forLocKey(explanation)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    _drainQueue();
  }

  void _onDismiss() {
    // Dismissal leaves underlying state unchanged (Flow §13.2): the intent
    // is neither consumed nor navigated; the notice simply closes.
    setState(() => _visible = null);
    _drainQueue();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final visible = _visible;

    // Route changes rebuild this host (it sits inside the router); drain a
    // queued notice once the route has left an active-answer surface.
    if (_queue.isNotEmpty && _visible == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _drainQueue();
        }
      });
    }

    return Stack(
      children: <Widget>[
        widget.child,
        if (visible != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Semantics(
                liveRegion: true,
                child: AnimatedSlide(
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: reducedMotion ? Offset.zero : const Offset(0, -0.05),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _copyFor(visible),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            key: const ValueKey('notice_tap'),
                            onPressed: () => _onTap(visible),
                            child: const Text('Open'),
                          ),
                          IconButton(
                            key: const ValueKey('notice_dismiss'),
                            tooltip: 'Dismiss notification',
                            onPressed: _onDismiss,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _copyFor(NotificationMessage message) {
    final intent = NotificationIntent.parse(message.data);
    return intent == null
        ? NotificationCopy.forLocKey(DeepLinkExplanations.malformedLink)
        : NotificationCopy.forIntent(intent);
  }
}
