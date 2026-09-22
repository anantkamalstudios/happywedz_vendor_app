import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// ============================================================================
/// Storefront section icons
/// ============================================================================
///
/// The Storefront menu ran on Material's stock glyphs, which read as a default
/// template next to the drawer's Iconsax rows. Worse, Pricing & Packages used
/// `Icons.attach_money` — a DOLLAR sign on an app whose vendors are all priced
/// in rupees.
///
/// `StoreFront` itself needs a vendorId, a live `vendorAccessProvider` and a
/// network fetch to pump, so this pins the icon choices at the source level
/// instead: the exact glyphs, read out of the file. That is enough to stop the
/// dollar sign — or a stray Material glyph — coming back unnoticed.
/// ----------------------------------------------------------------------------
void main() {
  late String source;
  late String liveSection;

  setUpAll(() {
    source = File('lib/Storefront/StoreFront.dart').readAsStringSync();

    // The file keeps a large commented-out copy of an older build above the
    // real one, carrying the same titles AND the same old icon names. Dropping
    // commented lines first is what makes the search hit the live list — the
    // first draft of this test matched the dead copy and failed on icons that
    // had in fact been changed.
    final live = source
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');

    final start = live.indexOf('"title": "Business Details"');
    expect(start, greaterThan(0), reason: 'live menu list not found');
    liveSection = live.substring(start);
  });

  String iconFor(String title) {
    final at = liveSection.indexOf('"title": "$title"');
    expect(at, greaterThan(-1), reason: '$title is missing from the menu');

    final iconAt = liveSection.indexOf('"icon":', at);
    final line = liveSection.substring(iconAt, liveSection.indexOf(',', iconAt));
    return line.replaceFirst('"icon":', '').trim();
  }

  test('Pricing & Packages shows a rupee, not a dollar', () {
    // The whole point of the change.
    expect(iconFor('Pricing & Packages'), 'Icons.currency_rupee_rounded');
    expect(liveSection, isNot(contains('Icons.attach_money')));
  });

  test('every other section is on the Iconsax set', () {
    const expected = {
      'Business Details': 'Iconsax.briefcase_copy',
      'Basic Information': 'Iconsax.info_circle_copy',
      'FAQ': 'Iconsax.message_question_copy',
      'Contact Details': 'Iconsax.call_copy',
      'Location & Service Areas': 'Iconsax.location_copy',
      'Photos': 'Iconsax.gallery_copy',
      '360° View': 'Iconsax.d_rotate_copy',
      'Videos': 'Iconsax.video_copy',
      'Preferred Vendors': 'Iconsax.profile_2user_copy',
      'Social Network': 'Iconsax.global_copy',
      'Facilities & Features': 'Iconsax.element_3_copy',
      'Menus': 'Iconsax.menu_board_copy',
      'Promotions': 'Iconsax.discount_shape_copy',
      'Policies & Terms': 'Iconsax.shield_tick_copy',
      'Availability & Slots': 'Iconsax.calendar_copy',
    };

    expected.forEach((title, icon) {
      expect(iconFor(title), icon, reason: '$title is on the wrong icon');
    });
  });

  test('no stock Material glyph is left in the live menu', () {
    // The rupee is the one deliberate exception — Iconsax has no rupee glyph.
    final materialIcons = RegExp(r'"icon": (Icons\.[a-z_]+)')
        .allMatches(liveSection)
        .map((m) => m.group(1))
        .toSet();

    expect(materialIcons, {'Icons.currency_rupee_rounded'});
  });

  test('the icons named here actually exist', () {
    // A typo'd Iconsax name compiles as an error, but these are read from the
    // file as text, so assert the real constants resolve.
    expect(Iconsax.briefcase_copy, isA<IconData>());
    expect(Iconsax.d_rotate_copy, isA<IconData>());
    expect(Iconsax.element_3_copy, isA<IconData>());
    expect(Iconsax.menu_board_copy, isA<IconData>());
    expect(Iconsax.discount_shape_copy, isA<IconData>());
    expect(Iconsax.shield_tick_copy, isA<IconData>());
    expect(Icons.currency_rupee_rounded, isA<IconData>());
  });
}
