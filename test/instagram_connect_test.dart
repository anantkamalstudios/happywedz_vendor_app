import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_weds_vendors/Screens/instagram_connect_screen.dart';

/// ============================================================================
/// Instagram Connect
/// ============================================================================
///
/// With no token in SharedPreferences the screen never reaches the network, so
/// the disconnected state and the sign-in prompt can be driven without stubbing
/// HTTP. The connected state needs a real token and is not covered here.
/// ----------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScreen(WidgetTester tester, {Size? size}) async {
    tester.view.physicalSize = size ?? const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: InstagramConnectScreen()));
    await tester.pumpAndSettle();
  }

  group('InstagramGlyph', () {
    testWidgets('renders the bundled Instagram mark', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InstagramGlyph(size: 24))),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/instagram.png');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a missing asset falls back instead of throwing',
        (tester) async {
      // The drawer row would otherwise show a grey exception box.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InstagramGlyph(size: 24))),
      );
      final image = tester.widget<Image>(find.byType(Image));

      expect(image.errorBuilder, isNotNull);
      final fallback = image.errorBuilder!(
        tester.element(find.byType(Image)),
        'boom',
        null,
      );
      expect(fallback, isA<Widget>());
    });
  });

  group('the screen', () {
    testWidgets('shows the disconnected state and a Connect button',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Not connected'), findsOneWidget);
      expect(find.text('Connect Instagram'), findsOneWidget);
      expect(find.text('Disconnect'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('asks the vendor to log in when there is no token',
        (tester) async {
      await pumpScreen(tester);

      expect(
        find.textContaining('Please log in again'),
        findsOneWidget,
      );
    });

    testWidgets('explains what connecting does', (tester) async {
      await pumpScreen(tester);

      expect(find.text('What connecting does'), findsOneWidget);
      // The browser hand-off is the part a vendor will not expect, so it has
      // to be stated on screen.
      expect(find.textContaining('opens in your browser'), findsOneWidget);
    });

    testWidgets('holds together on a small phone', (tester) async {
      await pumpScreen(tester, size: const Size(320, 600));

      expect(find.text('Connect Instagram'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('holds together at a large text size', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const InstagramConnectScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
