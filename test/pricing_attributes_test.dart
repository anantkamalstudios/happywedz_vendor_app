import 'package:flutter_test/flutter_test.dart';

import 'package:happy_weds_vendors/utils/pricing_attributes.dart';

/// ============================================================================
/// Pricing & Packages — what a save is allowed to touch
/// ============================================================================
///
/// The values below are real ones pulled from the live API, because the bugs
/// these pin only show up on migrated vendors:
///
///   service 10 → PriceRange: "Rs. 35,000"            (no dash at all)
///   service 2  → PriceRange: "Rs. Price on Request"  (not a number)
///   service 1  → PriceRange: "Rs. 40,000 - 65,000"   (dash, but not numeric)
///   service 98343 → price_range: {min: "22000", max: "35000"}  (website-saved)
///
/// The screen used to rebuild `PriceRange` as "$min - $max" on every save, so
/// opening Pricing and pressing Save turned the first two into " - ".
/// ----------------------------------------------------------------------------
void main() {
  Map<String, dynamic> merge({
    Map<String, dynamic>? attributes,
    String starting = '',
    String min = '',
    String max = '',
    String description = '',
    String serverPriceRange = '',
    String? photoPackage,
    String? photoVideoPackage,
    String? brochureBase64,
    String? brochureName,
  }) {
    return PricingAttributes.merge(
      attributes: attributes ?? {},
      starting: starting,
      min: min,
      max: max,
      description: description,
      serverPriceRange: serverPriceRange,
      photoPackage: photoPackage,
      photoVideoPackage: photoVideoPackage,
      brochureBase64: brochureBase64,
      brochureName: brochureName,
    );
  }

  group('PriceRange is never destroyed', () {
    test('free text survives a save with both inputs empty', () {
      final out = merge(
        attributes: {'PriceRange': 'Rs. Price on Request'},
        serverPriceRange: 'Rs. Price on Request',
      );

      expect(out['PriceRange'], 'Rs. Price on Request');
      expect(out['PriceRange'], isNot(' - '));
    });

    test('a dashless price survives too', () {
      final out = merge(
        attributes: {'PriceRange': 'Rs. 35,000'},
        serverPriceRange: 'Rs. 35,000',
      );

      expect(out['PriceRange'], 'Rs. 35,000');
    });

    test('only one of the two inputs filled still keeps the server value', () {
      final out = merge(min: '2000', serverPriceRange: 'Rs. 35,000');

      expect(out['PriceRange'], 'Rs. 35,000');
      expect(out['price_range'], {'min': '2000', 'max': ''});
    });

    test('both filled rebuilds the display string', () {
      final out = merge(
        min: '22000',
        max: '35000',
        serverPriceRange: 'Rs. Price on Request',
      );

      expect(out['PriceRange'], '22000 - 35000');
      expect(out['price_range'], {'min': '22000', 'max': '35000'});
    });
  });

  group('starting_price', () {
    test('a blank box drops the key instead of saving 0', () {
      final out = merge(attributes: {'starting_price': 5000});

      expect(out.containsKey('starting_price'), isFalse);
      expect(out['starting_price'], isNot(0));
    });

    test('a number is stored as a number', () {
      expect(merge(starting: '5000')['starting_price'], 5000);
    });

    test('migrated text is kept rather than collapsed to 0', () {
      expect(merge(starting: 'Rs. 40,000')['starting_price'], 'Rs. 40,000');
    });
  });

  group('optional text keys', () {
    test('a description is trimmed and stored', () {
      expect(
        merge(description: '  Taxes extra  ')['pricing_description'],
        'Taxes extra',
      );
    });

    test('clearing the description removes the key', () {
      final out = merge(attributes: {'pricing_description': 'old'});
      expect(out.containsKey('pricing_description'), isFalse);
    });
  });

  group('package prices belong to Photographers and Pre Wedding Shoot', () {
    test('null leaves an existing value untouched', () {
      final out = merge(
        attributes: {
          'photo_package_price': 'Rs. 40,000',
          'photo_video_package_price': '65,000',
        },
      );

      expect(out['photo_package_price'], 'Rs. 40,000');
      expect(out['photo_video_package_price'], '65,000');
    });

    test('a value is written when the type does show them', () {
      final out = merge(photoPackage: '24000', photoVideoPackage: '40000');

      expect(out['photo_package_price'], '24000');
      expect(out['photo_video_package_price'], '40000');
    });

    test('an empty box clears the key for a type that shows them', () {
      final out = merge(
        attributes: {'photo_package_price': '24000'},
        photoPackage: '',
      );

      expect(out.containsKey('photo_package_price'), isFalse);
    });
  });

  group('unrelated attributes are carried through', () {
    test('other keys are left exactly as they were', () {
      final out = merge(
        attributes: {'about_us': 'hello', 'available_slots': []},
        min: '1',
        max: '2',
      );

      expect(out['about_us'], 'hello');
      expect(out['available_slots'], isEmpty);
    });

    test('the input map is not mutated', () {
      final original = <String, dynamic>{'starting_price': 5000};
      merge(attributes: original);

      expect(original['starting_price'], 5000);
    });
  });

  group('pricing brochure', () {
    test('an image is stored inline with its name', () {
      final out = merge(
        brochureBase64: 'data:image/jpeg;base64,AAAA',
        brochureName: 'rates.jpg',
      );

      expect(out['pricing_brochure_base64'], 'data:image/jpeg;base64,AAAA');
      expect(out['pricing_brochure_name'], 'rates.jpg');
    });

    test('a PDF keeps only its name — the column cannot hold one', () {
      final out = merge(brochureBase64: null, brochureName: 'rates.pdf');

      expect(out.containsKey('pricing_brochure_base64'), isFalse);
      expect(out['pricing_brochure_name'], 'rates.pdf');
    });

    test('removing it clears both keys', () {
      final out = merge(
        attributes: {
          'pricing_brochure_base64': 'data:image/jpeg;base64,AAAA',
          'pricing_brochure_name': 'rates.jpg',
        },
      );

      expect(out.containsKey('pricing_brochure_base64'), isFalse);
      expect(out.containsKey('pricing_brochure_name'), isFalse);
    });

    test('the server-side url is never touched', () {
      // It is written server side; the website only ever sends base64 + name.
      final out = merge(
        attributes: {'pricing_brochure_url': 'https://cdn/rates.jpg'},
        brochureBase64: 'data:image/jpeg;base64,AAAA',
        brochureName: 'rates.jpg',
      );

      expect(out['pricing_brochure_url'], 'https://cdn/rates.jpg');
    });
  });

  group('brochureType', () {
    test('base64 decides first', () {
      expect(
        PricingAttributes.brochureType(
            base64: 'data:image/jpeg;base64,AA', name: 'weird.pdf'),
        'image',
      );
    });

    test('a name ending in .pdf is a pdf', () {
      expect(PricingAttributes.brochureType(name: 'rates.PDF'), 'pdf');
    });

    test('any other name is treated as an image', () {
      expect(PricingAttributes.brochureType(name: 'rates.png'), 'image');
    });

    test('nothing at all is null', () {
      expect(PricingAttributes.brochureType(), isNull);
      expect(PricingAttributes.brochureType(base64: '', name: ''), isNull);
    });
  });

  group('readRange', () {
    test('prefers the structured pair', () {
      final range = PricingAttributes.readRange({
        'price_range': {'min': '22000', 'max': '35000'},
        'PriceRange': 'something else entirely',
      });

      expect(range.min, '22000');
      expect(range.max, '35000');
    });

    test('falls back to splitting the display string', () {
      final range =
          PricingAttributes.readRange({'PriceRange': 'Rs. 40,000 - 65,000'});

      expect(range.min, 'Rs. 40,000');
      expect(range.max, '65,000');
    });

    test('a dashless value yields nothing rather than a half parse', () {
      final range =
          PricingAttributes.readRange({'PriceRange': 'Rs. Price on Request'});

      expect(range.min, '');
      expect(range.max, '');
    });

    test('extra dashes keep their tail', () {
      final range = PricingAttributes.readRange({'PriceRange': '1-2-3'});

      expect(range.min, '1');
      expect(range.max, '2-3');
    });

    test('an empty pair falls through to the display string', () {
      final range = PricingAttributes.readRange({
        'price_range': {'min': '', 'max': ''},
        'PriceRange': '100 - 200',
      });

      expect(range.min, '100');
      expect(range.max, '200');
    });

    test('nothing at all is empty, not a crash', () {
      final range = PricingAttributes.readRange({});

      expect(range.min, '');
      expect(range.max, '');
    });
  });
}
