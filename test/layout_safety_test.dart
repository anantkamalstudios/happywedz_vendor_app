import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_weds_vendors/widgets/app_shimmer.dart';
import 'package:happy_weds_vendors/widgets/app_states.dart';

/// ============================================================================
/// Layout-safety regression tests
/// ============================================================================
///
/// AUDIT NOTE — THESE EXIST BECAUSE A REAL BUG SHIPPED.
///
/// The first version of the shared skeleton/state widgets assumed their parent
/// would always give them a bounded height. `ReviewsPage` puts its loading
/// skeleton inside a `SliverToBoxAdapter`, which imposes NO height limit, and
/// the inner `ListView` threw on a real device:
///
///     Vertical viewport was given unbounded height.
///     BoxConstraints forces an infinite height.
///     RenderBox was not laid out: _ShimmerFilter#3ab62 …
///     Null check operator used on a null value
///
/// One bad constraint produced ~30 cascading layout exceptions and took the
/// Reviews tab down. The analyzer cannot catch this — it is a runtime layout
/// contract — so it needs a test.
///
/// Each widget below is pumped in BOTH kinds of slot:
///   • bounded   — a normal `Scaffold` body,
///   • unbounded — inside a `SliverToBoxAdapter` in a `CustomScrollView`,
///     which is the precise arrangement that failed.
/// ----------------------------------------------------------------------------
void main() {
  /// Renders [child] with a definite height available (the common case).
  Future<void> pumpBounded(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );
  }

  /// Renders [child] with NO height limit — the arrangement that crashed.
  Future<void> pumpUnbounded(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [SliverToBoxAdapter(child: child)],
          ),
        ),
      ),
    );
  }

  /// Also exercise `SliverFillRemaining(hasScrollBody: false)`, which is how
  /// ReviewsPage hosts its empty and error states.
  Future<void> pumpFillRemaining(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverFillRemaining(hasScrollBody: false, child: child),
            ],
          ),
        ),
      ),
    );
  }

  /// Skeletons that are placed INSIDE SLIVERS by real screens. These carry no
  /// scroll view of their own, so they must survive every slot kind —
  /// including an unbounded one.
  final sliverSafeSkeletons = <String, Widget>{
    'ListShimmer': const ListShimmer(itemCount: 4, itemHeight: 150),
    'ListShimmer (no avatar)':
        const ListShimmer(itemCount: 5, showAvatar: false, itemHeight: 120),
    'GridShimmer': const GridShimmer(itemCount: 9),
    'GridShimmer (2-col)': const GridShimmer(itemCount: 6, crossAxisCount: 2),
  };

  /// Skeletons designed as a whole page body. They own a non-scrolling
  /// `SingleChildScrollView` so a tall skeleton on a short screen does not
  /// paint an overflow stripe; that means they need a height-bounded slot.
  final pageBodySkeletons = <String, Widget>{
    'FormShimmer': const FormShimmer(fields: 5),
    'HomeShimmer': const HomeShimmer(),
    'StatsShimmer': const StatsShimmer(),
    'ProfileShimmer': const ProfileShimmer(),
  };

  final allSkeletons = {...sliverSafeSkeletons, ...pageBodySkeletons};

  group('sliver-hosted skeletons survive an unbounded parent', () {
    // This is the exact arrangement that failed on device: ReviewsPage put
    // ListShimmer inside a SliverToBoxAdapter, the inner ListView had no
    // shrinkWrap, and it threw "Vertical viewport was given unbounded height"
    // followed by ~30 cascading "RenderBox was not laid out" errors.
    sliverSafeSkeletons.forEach((name, widget) {
      testWidgets('$name in a SliverToBoxAdapter', (tester) async {
        await pumpUnbounded(tester, widget);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull,
            reason: '$name threw when given unbounded height — this is the '
                'exact failure that took down the Reviews tab');
      });
    });
  });

  group('every skeleton works in a bounded parent', () {
    allSkeletons.forEach((name, widget) {
      testWidgets('$name in a Scaffold body', (tester) async {
        await pumpBounded(tester, widget);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$name threw when bounded');
      });
    });
  });

  group('page-body skeletons survive an intrinsic-measuring parent', () {
    // `SliverFillRemaining(hasScrollBody: false)` measures its child's
    // INTRINSIC height. Anything built on `LayoutBuilder` throws
    // "LayoutBuilder does not support returning intrinsic dimensions" here,
    // which then cascades into "Null check operator used on a null value" in
    // the viewport's layout, paint and semantics passes. This group is why
    // neither the skeletons nor the state widgets use `LayoutBuilder`.
    pageBodySkeletons.forEach((name, widget) {
      testWidgets('$name in SliverFillRemaining', (tester) async {
        await pumpFillRemaining(tester, widget);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull,
            reason: '$name threw when its intrinsic height was measured');
      });
    });
  });

  group('documented limitation', () {
    // A shrink-wrapped ListView/GridView cannot report an intrinsic height —
    // that is a Flutter constraint, not something these widgets can work
    // around. `ListShimmer`/`GridShimmer` therefore belong in a
    // `SliverToBoxAdapter`, never a `SliverFillRemaining`.
    //
    // This test asserts the limitation ON PURPOSE so it is recorded in the
    // suite rather than discovered on a device. If a future Flutter release
    // makes this work, this test fails and the limitation can be deleted from
    // the doc comments on both widgets.
    testWidgets(
        'ListShimmer in SliverFillRemaining still throws — use '
        'SliverToBoxAdapter instead', (tester) async {
      await pumpFillRemaining(tester, const ListShimmer(itemCount: 3));
      await tester.pump();
      expect(tester.takeException(), isNotNull,
          reason: 'if this now passes, Flutter gained intrinsic support for '
              'shrink-wrapped slivers — update the docs on ListShimmer');
    });
  });

  group('empty and error states survive both slot kinds', () {
    const empty = AppEmptyState(
      icon: Icons.star_outline_rounded,
      title: 'No reviews yet',
      message: 'When your clients leave a review it will appear here.',
    );
    final error = AppErrorState(
      title: "Couldn't load your reviews",
      message: 'Please try again.',
      onRetry: () async {},
    );

    testWidgets('AppEmptyState in a SliverToBoxAdapter', (tester) async {
      await pumpUnbounded(tester, empty);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('No reviews yet'), findsOneWidget);
    });

    testWidgets('AppEmptyState in SliverFillRemaining', (tester) async {
      await pumpFillRemaining(tester, empty);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('No reviews yet'), findsOneWidget);
    });

    testWidgets('AppErrorState in a SliverToBoxAdapter', (tester) async {
      await pumpUnbounded(tester, error);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text("Couldn't load your reviews"), findsOneWidget);
    });

    testWidgets('AppErrorState in SliverFillRemaining, Retry is tappable',
        (tester) async {
      var retried = false;
      await pumpFillRemaining(
        tester,
        AppErrorState(
          message: 'Please try again.',
          onRetry: () async => retried = true,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(retried, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('narrow screens do not overflow', () {
    // 320dp is the narrowest Android phone width still in the wild.
    testWidgets('ListShimmer at 320x600', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpBounded(tester, const ListShimmer(itemCount: 3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeShimmer at 320x600 (skeleton taller than viewport)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpBounded(tester, const HomeShimmer());
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull,
          reason: 'a skeleton taller than the viewport must scroll, '
              'not paint an overflow stripe');
    });
  });
}
