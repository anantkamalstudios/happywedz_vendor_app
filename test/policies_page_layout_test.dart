import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_weds_vendors/Storefront/PoliciesPage.dart';

/// ============================================================================
/// Policies & Terms — layout regression tests
/// ============================================================================
///
/// The screen was rebuilt visually (tinted page, per-policy cards with icons
/// and hints, pinned action bar). Nothing about its loading, autosave or save
/// logic changed, so what needs pinning is the layout: four stacked cards and a
/// bottom bar have to survive a small phone without an overflow stripe.
///
/// With no credentials in SharedPreferences the page skips its network fetch,
/// which is what makes it testable without stubbing HTTP.
/// ----------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    double bottomPadding = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          // `padding.bottom` is the system navigation bar. `viewInsets` would
          // be the keyboard — SafeArea reads padding, so that is what a
          // 3-button nav bar has to be simulated with.
          data: MediaQuery.of(context)
              .copyWith(padding: EdgeInsets.only(bottom: bottomPadding)),
          child: child!,
        ),
        home: const PoliciesPage(),
      ),
    );
    // Let the async credential load finish and the form replace the skeleton.
    await tester.pumpAndSettle();
  }

  /// A 3-button navigation bar is around 48dp tall.
  const navBar = 48.0;

  testWidgets('renders the four policy fields on a small phone',
      (tester) async {
    await pumpAt(tester, const Size(320, 600));

    for (final label in const [
      'Cancellation Policy',
      'Refund Policy',
      'Payment Terms',
      'Terms & Conditions',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label is missing');
    }

    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('both actions stay reachable at the bottom', (tester) async {
    await pumpAt(tester, const Size(320, 600));

    expect(find.text('Save Policies'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // The action bar is pinned outside the scroll view, so it is on screen
    // without scrolling — that is the point of moving it there.
    final save = tester.getRect(find.text('Save Policies'));
    expect(save.bottom, lessThanOrEqualTo(600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolls to the last field without overflowing', (tester) async {
    await pumpAt(tester, const Size(320, 600));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    // An overflow stripe surfaces as a FlutterError from the paint phase.
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives a short, wide window', (tester) async {
    await pumpAt(tester, const Size(720, 360));
    expect(tester.takeException(), isNull);
  });

  // --------------------------------------------------------------------------
  // Edge to edge. `targetSdk = 36` means Android 15+ draws this app behind the
  // navigation bar, and the opt-out was removed in Android 16. A bar pinned to
  // the bottom of the body therefore needs SafeArea or it sits under the
  // 3-button navigation keys — which is exactly what a vendor reported.
  // --------------------------------------------------------------------------

  testWidgets('the Save button clears the navigation bar', (tester) async {
    await pumpAt(tester, const Size(320, 640), bottomPadding: navBar);

    final save = tester.getRect(find.text('Save Policies'));
    expect(
      save.bottom,
      lessThanOrEqualTo(640 - navBar),
      reason: 'Save is under the navigation bar',
    );
  });

  testWidgets('the action bar still fills the strip behind it',
      (tester) async {
    await pumpAt(tester, const Size(320, 640), bottomPadding: navBar);

    // SafeArea sits INSIDE the bar's Container, so the bar's own background
    // reaches the bottom of the screen rather than leaving a gap above the
    // navigation keys.
    final bar = find.ancestor(
      of: find.text('Save Policies'),
      matching: find.byType(Container),
    );
    expect(tester.getRect(bar.last).bottom, 640);
  });

  testWidgets('nothing changes when there is no navigation bar',
      (tester) async {
    await pumpAt(tester, const Size(320, 640));

    final save = tester.getRect(find.text('Save Policies'));
    expect(save.bottom, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });
}
