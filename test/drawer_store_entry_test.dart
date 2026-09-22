import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_weds_vendors/Screens/drawer.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

/// ============================================================================
/// Drawer — the Store entry
/// ============================================================================
///
/// The website's header links "Shop" straight at the store subdomain with
/// target="_blank" (`Header.jsx`), so there is nothing in-app to route to and
/// the row hands off to the browser instead.
///
/// What is worth pinning is the destination and the position: the row was
/// asked for directly below Instagram Connect.
/// ----------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpDrawer(
    WidgetTester tester, {
    Size size = const Size(400, 900),
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
        home: const Scaffold(drawer: BusinessDrawer(), body: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
  }

  test('the store constant points at the subdomain the website uses', () {
    expect(ApiConfig.storeUrl, 'https://store.happywedz.com');
  });

  testWidgets('the drawer has a Store row', (tester) async {
    await pumpDrawer(tester);

    expect(find.text('Store'), findsOneWidget);
    expect(find.byIcon(Iconsax.shopping_bag_copy), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store sits directly below Instagram Connect', (tester) async {
    await pumpDrawer(tester);

    final instagram = tester.getTopLeft(find.text('Instagram Connect')).dy;
    final store = tester.getTopLeft(find.text('Store')).dy;

    expect(store, greaterThan(instagram),
        reason: 'Store should come after Instagram Connect');
  });

  testWidgets('it is marked as leaving the app', (tester) async {
    await pumpDrawer(tester);

    // The row opens a browser rather than pushing a screen, so it carries the
    // external-link affordance instead of a chevron.
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text('Store'), matching: find.byType(ListTile)),
    );
    expect(tile.trailing, isNotNull);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });

  testWidgets('Storefront and Store stay distinct rows', (tester) async {
    await pumpDrawer(tester);

    // Easy to confuse: "Storefront" is the in-app editor, "Store" is the shop.
    expect(find.text('Storefront'), findsOneWidget);
    expect(find.text('Store'), findsOneWidget);
    expect(find.byIcon(Iconsax.shop_copy), findsOneWidget);
  });

  // --------------------------------------------------------------------------
  // Icons. The rows were bare glyphs in one blue, mixing filled and outlined
  // shapes, which read as unfinished next to the Instagram brand mark.
  // --------------------------------------------------------------------------

  /// Every row's leading widget, by row title.
  Finder leadingOf(WidgetTester tester, String row) {
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text(row), matching: find.byType(ListTile)),
    );
    return find.byWidget(tile.leading!);
  }

  const rows = [
    'Storefront',
    'Payments & Subscription',
    'Instagram Connect',
    'Store',
    'Get Client Review to You',
    'Rate on Playstore',
  ];

  testWidgets('every row sits in the same tile', (tester) async {
    await pumpDrawer(tester);

    for (final row in rows) {
      final size = tester.getSize(leadingOf(tester, row));
      expect(size.width, 38, reason: '$row tile is the wrong width');
      expect(size.height, 38, reason: '$row tile is the wrong height');
    }
  });

  testWidgets('the artwork inside each tile is the same size', (tester) async {
    await pumpDrawer(tester);

    // This is the check that matters, and the one the first version of this
    // test missed: the Instagram logo filled its whole 38px tile while every
    // Material glyph sat at 20px inside its own, so the brand row looked
    // oversized even though all six footprints measured identically.
    for (final row in rows) {
      final leading = leadingOf(tester, row);

      final icon = find.descendant(of: leading, matching: find.byType(Icon));
      final image = find.descendant(of: leading, matching: find.byType(Image));
      final artwork = icon.evaluate().isNotEmpty ? icon : image;

      expect(artwork, findsOneWidget, reason: '$row has no artwork');

      final size = tester.getSize(artwork);
      expect(size.width, inInclusiveRange(20, 22),
          reason: '$row artwork is ${size.width}px, out of step with the rest');
      expect(size.height, inInclusiveRange(20, 22),
          reason: '$row artwork is ${size.height}px, out of step with the rest');
    }
  });

  testWidgets('the Instagram logo no longer fills its tile', (tester) async {
    await pumpDrawer(tester);

    final leading = leadingOf(tester, 'Instagram Connect');
    final logo = find.descendant(of: leading, matching: find.byType(Image));

    expect(tester.getSize(logo).width, lessThan(38),
        reason: 'the logo should sit inside the tile, not be the tile');
  });

  // --------------------------------------------------------------------------
  // Header. It was `Colors.pink[100]` behind a cyan panel with black text,
  // while every other screen in the app runs a deep blue bar with white text.
  // --------------------------------------------------------------------------

  testWidgets('the header is the app blue, not pink or cyan', (tester) async {
    await pumpDrawer(tester);

    final decorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .toList();

    final gradients = decorations
        .map((d) => d.gradient)
        .whereType<LinearGradient>()
        .expand((g) => g.colors)
        .toList();

    expect(gradients, contains(const Color(0xFF00509D)),
        reason: 'the header should use the app primary');
    expect(gradients, contains(const Color(0xFF003F88)));

    final flats = decorations.map((d) => d.color).toList();
    expect(flats, isNot(contains(const Color(0xFFE0F7FA))),
        reason: 'the cyan panel should be gone');
    expect(flats, isNot(contains(Colors.pink[100])),
        reason: 'the pink fallback should be gone');
  });

  testWidgets('the header survives a large text size', (tester) async {
    // A locked 180px header clipped the email off the bottom here.
    for (final scale in const [1.3, 1.6, 2.0]) {
      await pumpDrawer(tester, size: const Size(360, 720), textScale: scale);
      expect(tester.takeException(), isNull,
          reason: 'header overflowed at ${scale}x');
    }
  });

  testWidgets('logout is separated from the menu rows', (tester) async {
    await pumpDrawer(tester);

    expect(find.text('Logout'), findsOneWidget);
    expect(find.byType(Divider), findsWidgets);
  });

  testWidgets('every glyph comes from the one icon set', (tester) async {
    await pumpDrawer(tester);

    // Material's stock glyphs read as a default template. Every row is on
    // the Iconsax OUTLINE set now (`_copy`) — the base names are the Bold
    // variant, which rendered as heavy filled blobs.
    expect(find.byIcon(Icons.reviews), findsNothing);
    expect(find.byIcon(Icons.star_rate), findsNothing);
    expect(find.byIcon(Icons.storefront_outlined), findsNothing);
    expect(find.byIcon(Icons.credit_card_outlined), findsNothing);

    expect(find.byIcon(Iconsax.message_favorite_copy), findsOneWidget);
    expect(find.byIcon(Iconsax.star_copy), findsOneWidget);
    expect(find.byIcon(Iconsax.card_copy), findsOneWidget);
    expect(find.byIcon(Iconsax.logout_copy), findsOneWidget);
  });
}
