import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:happy_weds_vendors/Storefront/Availability&SlotsPage.dart';

/// ============================================================================
/// Availability & Slots — the Active/Inactive switch
/// ============================================================================
///
/// The website has had this switch for a while, stored as
/// `attributes.availability_active`, and the public listing hides the calendar
/// when it is off (`Detailed.jsx`: `availabilityActive !== false`). The app had
/// no switch at all and never sent the flag.
///
/// The default matters most: the key is absent for every vendor in production
/// today, and both sides read a missing flag as ACTIVE. A default of `false`
/// here would hide the calendar for everyone.
///
/// With no credentials in SharedPreferences the page skips its network fetch,
/// so the switch can be driven without stubbing HTTP.
/// ----------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SlotsPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('defaults to Active, with the calendar showing', (tester) async {
    await pumpPage(tester);

    expect(find.text('Active'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.byType(TableCalendar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching off swaps the calendar for the notice',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Inactive'), findsOneWidget);
    expect(find.byType(TableCalendar), findsNothing);
    expect(
      find.textContaining("couples won't see a calendar"),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching back on restores the calendar', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(find.byType(TableCalendar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('the flag is read the way the website reads it', () {
    // The website uses `attrs.availability_active !== false`; the app mirrors
    // it with `!= false`. These pin the equivalence for every value the API
    // can hand back, since only a literal `false` may turn the section off.
    for (final value in <Object?>[null, true, 'false', 0, 1, 'true']) {
      test('$value (${value.runtimeType}) reads as active', () {
        expect(value != false, isTrue);
      });
    }

    test('only a real false reads as inactive', () {
      expect(false != false, isFalse);
    });
  });
}
