import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_weds_vendors/utils/subcategory_selection.dart';

/// The Primary Subcategory multi-select on Basic Information.
///
/// The cases that matter most are the ones asserting the OTHER storefront
/// screens keep sending exactly what they sent before the multi-select
/// existed — those screens only ever track the primary id, and a wrong value
/// there would reassign the vendor's category on an unrelated save.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fromService', () {
    test('reads the joined list with the primary first', () {
      final ids = SubcategorySelection.fromService({
        'vendor_subcategory_id': 7,
        'subcategories': [
          {'id': 3, 'name': 'A'},
          {'id': 7, 'name': 'B'},
          {'id': 9, 'name': 'C'},
        ],
      });

      expect(ids, [7, 3, 9]);
    });

    test('falls back to the primary when no join rows came back', () {
      expect(
        SubcategorySelection.fromService({'vendor_subcategory_id': 4}),
        [4],
      );
    });

    test('keeps a primary that is missing from the joined list', () {
      final ids = SubcategorySelection.fromService({
        'vendor_subcategory_id': 5,
        'subcategories': [
          {'id': 8, 'name': 'A'},
        ],
      });

      expect(ids, [5, 8]);
    });

    test('tolerates string ids and a null payload', () {
      expect(
        SubcategorySelection.fromService({
          'vendor_subcategory_id': '2',
          'subcategories': [
            {'id': '6'},
          ],
        }),
        [2, 6],
      );
      expect(SubcategorySelection.fromService(null), isEmpty);
    });
  });

  group('payload', () {
    test('a single pick stays an int, as the old payloads were', () {
      expect(SubcategorySelection.payload([4]), 4);
    });

    test('several picks become the comma list the backend expects', () {
      expect(SubcategorySelection.payload([7, 3, 9]), '7,3,9');
    });

    test('nothing selected sends nothing', () {
      expect(SubcategorySelection.payload([]), isNull);
    });
  });

  group('payloadForPrimary — the other storefront screens', () {
    test('sends the stored extras when the primary matches', () async {
      SharedPreferences.setMockInitialValues({
        'vendor_subcategory_id': 7,
        'vendor_subcategory_ids': ['7', '3'],
      });

      expect(await SubcategorySelection.payloadForPrimary(7), '7,3');
    });

    test('ignores a stored list belonging to a different primary', () async {
      // Left over from another vendor or another service. Attaching it would
      // add subcategories nobody picked.
      SharedPreferences.setMockInitialValues({
        'vendor_subcategory_id': 5,
        'vendor_subcategory_ids': ['5', '11'],
      });

      expect(await SubcategorySelection.payloadForPrimary(7), 7);
    });

    test('sends the bare primary when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await SubcategorySelection.payloadForPrimary(7), 7);
    });

    test('an existing install sends the same int it always sent', () async {
      // The state every current vendor upgrades into: the old single-id key
      // is there, the multi-select list is not. Nothing about their saves may
      // change until they pick a second subcategory themselves.
      SharedPreferences.setMockInitialValues({'vendor_subcategory_id': 7});

      final value = await SubcategorySelection.payloadForPrimary(7);
      expect(value, 7);
      expect(value, isA<int>(), reason: 'must not become the string "7"');
    });

    test('one pick saved from the new screen still sends an int', () async {
      SharedPreferences.setMockInitialValues({});
      await SubcategorySelection.save([7]);

      final value = await SubcategorySelection.payloadForPrimary(7);
      expect(value, 7);
      expect(value, isA<int>());
    });

    test('a null primary still sends null', () async {
      SharedPreferences.setMockInitialValues({
        'vendor_subcategory_id': 7,
        'vendor_subcategory_ids': ['7', '3'],
      });

      expect(await SubcategorySelection.payloadForPrimary(null), isNull);
    });
  });

  group('save / load', () {
    test('round-trips the selection with the primary first', () async {
      SharedPreferences.setMockInitialValues({});
      await SubcategorySelection.save([7, 3, 9]);

      expect(await SubcategorySelection.load(), [7, 3, 9]);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('vendor_subcategory_id'), 7);
    });

    test('drops a list that no longer covers the primary', () async {
      // Contact Details and Facilities write the primary key by themselves.
      // If one of them moved it, the list left behind is an older selection
      // and must not be merged back into the next save.
      SharedPreferences.setMockInitialValues({
        'vendor_subcategory_id': 9,
        'vendor_subcategory_ids': ['7', '3'],
      });

      expect(await SubcategorySelection.load(), [9]);
      expect(await SubcategorySelection.payloadForPrimary(9), 9);
    });

    test('load falls back to a primary written by an older build', () async {
      SharedPreferences.setMockInitialValues({'vendor_subcategory_id': 4});

      expect(await SubcategorySelection.load(), [4]);
    });

    test('saving nothing clears the list', () async {
      SharedPreferences.setMockInitialValues({
        'vendor_subcategory_id': 7,
        'vendor_subcategory_ids': ['7', '3'],
      });
      await SubcategorySelection.save([]);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('vendor_subcategory_ids'), isNull);
    });
  });
}
