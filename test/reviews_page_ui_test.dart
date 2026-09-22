import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_weds_vendors/Screens/ReviewScreen.dart';
import 'package:happy_weds_vendors/widgets/app_shimmer.dart';
import 'package:happy_weds_vendors/widgets/app_states.dart';

/// ============================================================================
/// My Reviews — the loading and empty states
/// ============================================================================
///
/// Only the UI changed here; the fetch, the reply call and the state they
/// write are untouched. What needed pinning is the two states that used to be
/// faked with hard-coded padding:
///
///     Padding(padding: EdgeInsets.only(top: 350), child: Center(...))
///
/// — a spinner pushed down by a number that only centred on one screen size.
/// Both now use the shared widgets, in the slots `layout_safety_test.dart`
/// says each one is allowed to sit in.
///
/// With no token in SharedPreferences the page returns before any request, so
/// the empty state renders without stubbing HTTP.
/// ----------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(400, 800),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const ReviewsPage(),
      ),
    );
  }

  testWidgets('shows a card-shaped skeleton while loading', (tester) async {
    // The very first frame, before the credential read resolves.
    await pumpPage(tester);

    expect(find.byType(ListShimmer), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('empty state invites the vendor to collect reviews',
      (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('No reviews yet'), findsOneWidget);
    expect(find.text('Collect reviews'), findsOneWidget);

    // The old copy was a bare grey line with no way forward.
    expect(find.text('No reviews available'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the header still names the screen', (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('My Reviews'), findsOneWidget);
    // The action that opens the collector is kept.
    expect(find.byTooltip('Collect reviews'), findsOneWidget);
  });

  testWidgets('empty state holds together on a small phone', (tester) async {
    await pumpPage(tester, size: const Size(320, 560));
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in const [1.3, 1.6, 2.0]) {
    testWidgets('empty state survives ${scale}x text', (tester) async {
      await pumpPage(tester, size: const Size(320, 640), textScale: scale);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the list is pullable to refresh', (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
