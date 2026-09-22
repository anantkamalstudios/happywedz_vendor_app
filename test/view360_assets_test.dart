import 'package:flutter_test/flutter_test.dart';

import 'package:happy_weds_vendors/utils/view360_assets.dart';

/// ============================================================================
/// 360° View — reading assets and sanitising the pasted link
/// ============================================================================
///
/// The website's `view360Helper.js` documents four different places a 360°
/// asset can sit, depending on how the record was last saved. No vendor in
/// production has any 360° data yet, so nothing here could be checked against
/// live values — these encode the shapes the helper says to expect.
///
/// The URL rules matter most: the value goes straight into a link the app
/// opens, and vendors can type anything into that box.
/// ----------------------------------------------------------------------------
void main() {
  group('safeUrl', () {
    test('accepts plain http and https links', () {
      expect(
        View360Assets.safeUrl('https://my.matterport.com/show/?m=abc'),
        'https://my.matterport.com/show/?m=abc',
      );
      expect(
        View360Assets.safeUrl('http://kuula.co/share/abc'),
        'http://kuula.co/share/abc',
      );
    });

    test('refuses anything that is not http(s)', () {
      // These would otherwise end up in a link the app launches.
      expect(View360Assets.safeUrl('javascript:alert(1)'), isNull);
      expect(View360Assets.safeUrl('data:text/html,<h1>hi'), isNull);
      expect(View360Assets.safeUrl('file:///etc/passwd'), isNull);
    });

    test('refuses text that is not a link at all', () {
      expect(View360Assets.safeUrl('my tour'), isNull);
      expect(View360Assets.safeUrl('www.example.com'), isNull);
      expect(View360Assets.safeUrl(''), isNull);
      expect(View360Assets.safeUrl(null), isNull);
    });

    test('strips the backticks a pasted link often arrives in', () {
      expect(
        View360Assets.safeUrl('`https://kuula.co/share/abc`'),
        'https://kuula.co/share/abc',
      );
    });

    test('treats the literal strings null and undefined as absent', () {
      expect(View360Assets.safeUrl('null'), isNull);
      expect(View360Assets.safeUrl('undefined'), isNull);
      expect(View360Assets.safeUrl('UNDEFINED'), isNull);
    });

    test('ignores a non-string value', () {
      expect(View360Assets.safeUrl(42), isNull);
      expect(View360Assets.safeUrl(['https://a.com']), isNull);
    });
  });

  group('videos', () {
    test('reads the top level string column', () {
      expect(
        View360Assets.videos({'view360_video': 'https://cdn/a.mp4'}),
        ['https://cdn/a.mp4'],
      );
    });

    test('reads a top level array', () {
      expect(
        View360Assets.videos({
          'view360_video': ['https://cdn/a.mp4', 'https://cdn/b.mp4'],
        }),
        ['https://cdn/a.mp4', 'https://cdn/b.mp4'],
      );
    });

    test('reads the copy inside attributes', () {
      expect(
        View360Assets.videos({
          'attributes': {'view360_video': 'https://cdn/c.mp4'},
        }),
        ['https://cdn/c.mp4'],
      );
    });

    test('the same video in two shapes is listed once', () {
      final videos = View360Assets.videos({
        'view360_video': 'https://cdn/a.mp4',
        'attributes': {'view360_video': 'https://cdn/a.mp4'},
      });

      expect(videos, ['https://cdn/a.mp4']);
    });

    test('unwraps entries that are objects carrying a url', () {
      expect(
        View360Assets.videos({
          'view360_video': [
            {'url': 'https://cdn/a.mp4'},
            {'path': 'https://cdn/b.mp4'},
          ],
        }),
        ['https://cdn/a.mp4', 'https://cdn/b.mp4'],
      );
    });

    test('junk entries are dropped, not returned', () {
      expect(
        View360Assets.videos({
          'view360_video': ['', 'null', 'undefined', 'https://cdn/a.mp4'],
        }),
        ['https://cdn/a.mp4'],
      );
    });

    test('a record with nothing is empty, not a crash', () {
      expect(View360Assets.videos({}), isEmpty);
      expect(View360Assets.videos(null), isEmpty);
      expect(View360Assets.videos({'attributes': 'not a map'}), isEmpty);
    });
  });

  group('images', () {
    test('still reads pano images saved before that tab was removed', () {
      // The website's upload tab for these is commented out, but older
      // records carry them and they must not vanish from the list.
      expect(
        View360Assets.images({'view360_image': 'https://cdn/pano.jpg'}),
        ['https://cdn/pano.jpg'],
      );
      expect(
        View360Assets.images({
          'attributes': {
            'view360_images': ['https://cdn/p1.jpg', 'https://cdn/p2.jpg'],
          },
        }),
        ['https://cdn/p1.jpg', 'https://cdn/p2.jpg'],
      );
    });
  });

  group('has', () {
    test('true for a video, an image, or a usable link', () {
      expect(View360Assets.has({'view360_video': 'https://cdn/a.mp4'}), isTrue);
      expect(View360Assets.has({'view360_image': 'https://cdn/p.jpg'}), isTrue);
      expect(
        View360Assets.has({
          'attributes': {'view360_url': 'https://kuula.co/share/abc'},
        }),
        isTrue,
      );
    });

    test('false for an empty record or an unusable link', () {
      expect(View360Assets.has({}), isFalse);
      expect(View360Assets.has(null), isFalse);
      expect(
        View360Assets.has({
          'attributes': {'view360_url': 'javascript:alert(1)'},
        }),
        isFalse,
      );
    });
  });
}
