import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_weds_vendors/widgets/app_shimmer.dart';

/// ============================================================================
/// Statistics — the loading state
/// ============================================================================
///
/// `StatsShimmer` had existed in `app_shimmer.dart` since the shimmer work but
/// nothing ever used it: Statistics opened on a bare `CircularProgressIndicator`
/// centred in an empty page, which is what a vendor reported seeing before the
/// charts appeared.
///
/// The transient loading frame is NOT asserted against the live widget. With no
/// token in SharedPreferences `fetchDashboardData` returns on its first await
/// and flips `isLoading` before the route transition even finishes — probing
/// the tree at 400ms already finds the charts. Catching that window would mean
/// tuning a pump duration until it happened to land, which is the kind of test
/// that passes for the wrong reason. So the wiring is pinned at the source and
/// the skeleton itself is pinned as a widget.
/// ----------------------------------------------------------------------------
void main() {
  late String source;

  setUpAll(() {
    final raw = File('lib/Screens/StatsScreen.dart').readAsStringSync();
    // The file carries two large commented-out drafts of earlier versions,
    // both containing `CircularProgressIndicator`. Only live code counts.
    source = raw
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
  });

  test('the loading branch renders the skeleton', () {
    expect(source, contains('? const StatsShimmer()'));
  });

  test('no spinner is left in the live screen', () {
    expect(
      source,
      isNot(contains('CircularProgressIndicator')),
      reason: 'Statistics should never fall back to a bare spinner',
    );
  });

  testWidgets('the skeleton mirrors the real page', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatsShimmer()),
    ));
    // Shimmer animates forever, so pump a fixed frame rather than settling.
    await tester.pump(const Duration(milliseconds: 300));

    final boxes = tester.widgetList<ShimmerBox>(find.byType(ShimmerBox));

    // Three charts — Leads, Impressions, Profile Views — at the real 260px.
    expect(boxes.where((b) => b.height == 260).length, 3,
        reason: 'should mirror the three chart panels');

    // Three stat cards across the top.
    expect(boxes.where((b) => b.height == 106).length, 3,
        reason: 'should mirror the three stat cards');

    expect(tester.takeException(), isNull);
  });

  testWidgets('the skeleton holds together on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatsShimmer()),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}
