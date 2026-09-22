@Tags(['preview'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:happy_weds_vendors/widgets/app_shimmer.dart';

/// ============================================================================
/// Icon preview — a contact sheet, not an assertion
/// ============================================================================
///
/// Icon names say nothing about how a glyph actually looks, and three rounds of
/// picking them by name were rejected on sight. This renders candidates to a
/// PNG so the choice can be made by looking rather than guessing.
///
/// Run with:
///   flutter test --update-goldens --run-skipped test/icon_preview_test.dart
///
/// It is tagged `preview` and skipped by dart_test.yaml, because it loads
/// fonts from absolute local paths and would fail on any other machine. It is
/// a tool, not a regression test.
/// ----------------------------------------------------------------------------
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Widget tests render everything in Ahem, which draws every glyph as a
    // filled box — the first run of this produced a sheet of empty squares.
    // Each font has to be loaded by hand.
    Future<void> load(String family, String path) async {
      final file = File(path);
      if (!file.existsSync()) {
        // ignore: avoid_print
        print('MISSING FONT: $path');
        return;
      }
      final loader = FontLoader(family)
        ..addFont(
          file.readAsBytes().then((b) => ByteData.view(b.buffer)),
        );
      await loader.load();
    }

    final pubCache =
        '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache\\hosted\\pub.dev';

    // An IconData with a `fontPackage` resolves its family as
    // `packages/<pkg>/<family>` — loading it under the bare family name
    // silently does nothing and every glyph stays a box.
    await load('packages/iconsax_flutter/FlutterIconsax',
        '$pubCache\\iconsax_flutter-1.0.1\\fonts\\FlutterIconsax.ttf');
    // The font_subset fixture is a trimmed test font with almost no glyphs.
    // This is the one Flutter actually ships.
    await load('MaterialIcons',
        r'C:\src\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf');
    await load('Roboto',
        r'C:\src\flutter\bin\cache\dart-sdk\bin\resources\devtools\assets\fonts\Roboto\Roboto-Regular.ttf');
  });

  Widget sheet(String heading, List<(String, IconData)> icons) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (label, icon) in icons)
                    SizedBox(
                      width: 150,
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon,
                                size: 20, color: const Color(0xFF00509D)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(label,
                                style: const TextStyle(fontSize: 10),
                                maxLines: 2),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('current storefront picks', (tester) async {
    tester.view.physicalSize = const Size(700, 620);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(sheet('STOREFRONT — current', const [
      ('Business\nbriefcase', Iconsax.briefcase),
      ('Basic Info\ninfo_circle', Iconsax.info_circle),
      ('FAQ\nmessage_question', Iconsax.message_question),
      ('Contact\ncall', Iconsax.call),
      ('Location\nlocation', Iconsax.location),
      ('Photos\ngallery', Iconsax.gallery),
      ('360\nd_rotate', Iconsax.d_rotate),
      ('Videos\nvideo', Iconsax.video),
      ('Preferred\nprofile_2user', Iconsax.profile_2user),
      ('Social\nglobal', Iconsax.global),
      ('Facilities\nelement_3', Iconsax.element_3),
      ('Menus\nmenu_board', Iconsax.menu_board),
      ('Promotions\ndiscount_shape', Iconsax.discount_shape),
      ('Policies\nshield_tick', Iconsax.shield_tick),
      ('Slots\ncalendar', Iconsax.calendar),
      ('Pricing\nIcons.currency_rupee', Icons.currency_rupee_rounded),
    ]));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/icons_storefront.png'),
    );
  });

  testWidgets('alternatives worth comparing', (tester) async {
    tester.view.physicalSize = const Size(700, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(sheet('ALTERNATIVES', const [
      ('business\nbuildings_2', Iconsax.buildings_2),
      ('business\nbuilding_4', Iconsax.building_4),
      ('business\nshop', Iconsax.shop),
      ('info\ninfo_circle', Iconsax.info_circle),
      ('info\nnote_2', Iconsax.note_2),
      ('info\ndocument_text', Iconsax.document_text),
      ('faq\nmessages_2', Iconsax.messages_2),
      ('faq\nsms_star', Iconsax.sms_star),
      ('contact\ncall_calling', Iconsax.call_calling),
      ('contact\nprofile_circle', Iconsax.profile_circle),
      ('location\nlocation_tick', Iconsax.location_tick),
      ('location\nmap', Iconsax.map),
      ('location\nmap_1', Iconsax.map_1),
      ('photos\ngallery_favorite', Iconsax.gallery_favorite),
      ('photos\nimage', Iconsax.image),
      ('360\nrotate_left', Iconsax.rotate_left),
      ('360\nd_cube_scan', Iconsax.d_cube_scan),
      ('video\nvideo_play', Iconsax.video_play),
      ('video\nvideo_circle', Iconsax.video_circle),
      ('people\npeople', Iconsax.people),
      ('people\nprofile_tick', Iconsax.profile_tick),
      ('social\nlink_2', Iconsax.link_2),
      ('social\nshare', Iconsax.share),
      ('facilities\ncategory', Iconsax.category),
      ('facilities\nsetting_4', Iconsax.setting_4),
      ('menus\nreserve', Iconsax.reserve),
      ('promo\ntag_2', Iconsax.tag_2),
      ('promo\npercentage_square', Iconsax.percentage_square),
      ('promo\nticket_discount', Iconsax.ticket_discount),
      ('policies\ndocument_text_1', Iconsax.document_text_1),
      ('policies\nshield_search', Iconsax.shield_search),
      ('slots\ncalendar_1', Iconsax.calendar_1),
      ('slots\ncalendar_tick', Iconsax.calendar_tick),
      ('pricing\nmoney_3', Iconsax.money_3),
      ('pricing\nempty_wallet', Iconsax.empty_wallet),
      ('pricing\nreceipt_item', Iconsax.receipt_item),
      ('pricing\ntag', Iconsax.tag),
    ]));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/icons_alternatives.png'),
    );
  });

  testWidgets('weight comparison: base vs _copy', (tester) async {
    tester.view.physicalSize = const Size(700, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(sheet('BASE (left of pair) vs _COPY', const [
      ('base briefcase', Iconsax.briefcase),
      ('COPY briefcase', Iconsax.briefcase_copy),
      ('base call', Iconsax.call),
      ('COPY call', Iconsax.call_copy),
      ('base location', Iconsax.location),
      ('COPY location', Iconsax.location_copy),
      ('base gallery', Iconsax.gallery),
      ('COPY gallery', Iconsax.gallery_copy),
      ('base calendar', Iconsax.calendar),
      ('COPY calendar', Iconsax.calendar_copy),
      ('base shield_tick', Iconsax.shield_tick),
      ('COPY shield_tick', Iconsax.shield_tick_copy),
      ('base money_3', Iconsax.money_3),
      ('COPY money_3', Iconsax.money_3_copy),
      ('base video', Iconsax.video),
      ('COPY video', Iconsax.video_copy),
    ]));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/icons_weights.png'),
    );
  });

  testWidgets('proposed: outline everywhere', (tester) async {
    tester.view.physicalSize = const Size(700, 560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(sheet('PROPOSED — outline (_copy) + rupee', const [
      ('Business', Iconsax.briefcase_copy),
      ('Basic Info', Iconsax.info_circle_copy),
      ('FAQ', Iconsax.message_question_copy),
      ('Contact', Iconsax.call_copy),
      ('Location', Iconsax.location_copy),
      ('Photos', Iconsax.gallery_copy),
      ('360 View', Iconsax.d_rotate_copy),
      ('Videos', Iconsax.video_copy),
      ('Preferred', Iconsax.profile_2user_copy),
      ('Social', Iconsax.global_copy),
      ('Facilities', Iconsax.element_3_copy),
      ('Menus', Iconsax.menu_board_copy),
      ('Promotions', Iconsax.discount_shape_copy),
      ('Policies', Iconsax.shield_tick_copy),
      ('Slots', Iconsax.calendar_copy),
      ('Pricing RUPEE', Icons.currency_rupee_rounded),
      ('--- DRAWER ---', Iconsax.shop_copy),
      ('Payments', Iconsax.card_copy),
      ('Store', Iconsax.shopping_bag_copy),
      ('Get Review', Iconsax.message_favorite_copy),
      ('Rate', Iconsax.star_copy),
      ('Logout', Iconsax.logout_copy),
    ]));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/icons_proposed.png'),
    );
  });

  testWidgets('stats skeleton', (tester) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(backgroundColor: Colors.white, body: StatsShimmer()),
    ));
    // Shimmer animates forever, so pump a fixed frame rather than settling.
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/shimmer_stats.png'),
    );
  });
}
