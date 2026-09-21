import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// AppEmptyState / AppErrorState — the two states every dynamic screen needs
/// ============================================================================
///
/// AUDIT NOTE:
/// Before this audit the app had no shared state widgets. Screens showed
/// either a bare `Text("No leads found")` centred on a blank page, or nothing
/// at all — and on an API failure they showed the EMPTY state, which told the
/// user "you have no reviews" when the truth was "the request failed".
/// Those two situations are now visually and semantically distinct, and the
/// error state carries a Retry that re-invokes the screen's own existing
/// fetch method.
/// ----------------------------------------------------------------------------

/// Empty — the request succeeded and there genuinely is no data yet.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// When true the widget fills its parent and centres itself; when false it
  /// sizes to its content (useful inside a scrolling column).
  final bool expand;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3,
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppTheme.spaceXl),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );

    if (!expand) return content;
    return _CenteredSafely(child: content);
  }
}

/// Centres [child] in whatever slot it is given.
///
/// AUDIT NOTE — THIS DELIBERATELY DOES NOT SCROLL, AND DOES NOT USE
/// `LayoutBuilder`. Both were tried and both broke:
///
///   1. `Center(child: SingleChildScrollView(child: content))`
///      throws "Vertical viewport was given unbounded height" the moment the
///      state is placed in an unbounded slot such as a `SliverToBoxAdapter`.
///
///   2. Wrapping the decision in a `LayoutBuilder` — "scroll only when the
///      constraints are bounded" — looks like the fix but is worse. It throws
///      `LayoutBuilder does not support returning intrinsic dimensions`
///      inside `SliverFillRemaining(hasScrollBody: false)`, which measures its
///      child's intrinsic height. That assertion cascades into
///      `Null check operator used on a null value` in the viewport's layout,
///      paint AND semantics passes. `SliverFillRemaining` is exactly how
///      ReviewsPage hosts these states, so this path is live.
///
/// A plain `Align` behaves correctly in all three slot kinds: it shrink-wraps
/// under unbounded constraints, centres under bounded ones, and forwards
/// intrinsic queries to its child. Scrolling is the surrounding scroll view's
/// job — every call site is already inside one (a `ListView`, or a
/// `CustomScrollView` via `SliverFillRemaining`), so tall content on a short
/// screen still scrolls, just one level up.
///
/// Covered by test/layout_safety_test.dart, which pumps these states in all
/// three slot kinds.
class _CenteredSafely extends StatelessWidget {
  final Widget child;
  const _CenteredSafely({required this.child});

  @override
  Widget build(BuildContext context) => Center(child: child);
}

/// Error — something went wrong. Never shows a raw exception to the user;
/// pass the exception through [AppErrorState.messageFor] to get safe copy.
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final Future<void> Function()? onRetry;
  final bool expand;

  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message =
        "We couldn't load this information.\nPlease try again.",
    this.retryLabel = 'Try Again',
    this.onRetry,
    this.expand = true,
  });

  /// Converts any thrown object into user-facing copy.
  ///
  /// Raw `SocketException: Failed host lookup …` / `FormatException` /
  /// stack traces must never reach the UI, so everything unrecognised
  /// collapses to a single generic sentence.
  static String messageFor(Object? error) {
    if (error is SocketException) {
      return 'No internet connection.\nCheck your network and try again.';
    }
    if (error is TimeoutException) {
      return 'The request took too long.\nPlease try again.';
    }
    if (error is HttpException) {
      return "We couldn't reach the server.\nPlease try again.";
    }
    if (error is FormatException) {
      return 'We received an unexpected response.\nPlease try again.';
    }
    return "We couldn't load this information.\nPlease try again.";
  }

  /// Copy for a specific HTTP status code returned by the existing APIs.
  static String messageForStatus(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return 'Your session has expired.\nPlease log in again.';
    }
    if (statusCode == 404) {
      return "We couldn't find this information.";
    }
    if (statusCode >= 500) {
      return 'The server is not responding right now.\nPlease try again in a moment.';
    }
    return "We couldn't load this information.\nPlease try again.";
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.errorTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.h3),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppTheme.spaceXl),
            _RetryButton(label: retryLabel, onRetry: onRetry!),
          ],
        ],
      ),
    );

    if (!expand) return content;
    return _CenteredSafely(child: content);
  }
}

/// Retry button that shows its own spinner while the retry future is running,
/// so a slow retry cannot be tapped twice.
class _RetryButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onRetry;

  const _RetryButton({required this.label, required this.onRetry});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onRetry();
    } finally {
      // Guard against setState-after-dispose if the screen was popped while
      // the retry was in flight.
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.refresh_rounded, size: 18),
      label: Text(widget.label),
    );
  }
}

/// ---------------------------------------------------------------------------
/// AsyncStateView — one widget that renders the whole
/// loading → data | empty | error decision tree.
///
/// Screens keep their own state fields and their own API calls; this only
/// standardises WHICH widget is shown for each combination, so no screen can
/// accidentally show a blank page again.
/// ---------------------------------------------------------------------------
class AsyncStateView extends StatelessWidget {
  final bool isLoading;
  final Object? error;
  final bool isEmpty;

  /// Skeleton shown while [isLoading]. Falls back to a centred spinner only if
  /// a screen has no matching skeleton.
  final Widget loading;

  /// What to show when the request failed.
  final Widget? errorView;

  /// What to show when the request succeeded but returned nothing.
  final Widget empty;

  /// The real content.
  final WidgetBuilder builder;

  final Future<void> Function()? onRetry;

  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.loading,
    required this.empty,
    required this.builder,
    this.error,
    this.errorView,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return loading;
    if (error != null) {
      return errorView ??
          AppErrorState(
            message: AppErrorState.messageFor(error),
            onRetry: onRetry,
          );
    }
    if (isEmpty) return empty;
    return builder(context);
  }
}