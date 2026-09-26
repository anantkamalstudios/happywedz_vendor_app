import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:happy_weds_vendors/api_services/crm_api.dart';
import 'package:happy_weds_vendors/widgets/whatsapp_icon.dart';

/// ============================================================================
/// CRM → WhatsApp
/// ============================================================================
///
/// With a connected WhatsApp Business number the web posts to
/// `/vendor/crm/{quotations|invoices|payments}/:id/whatsapp` and the server
/// sends the template; without one it opens a wa.me chat. These pin the route
/// segments and the fallback link so the app keeps matching the web.
void main() {
  group('CrmDocType', () {
    test('maps each document to the web route segment', () {
      expect(CrmDocType.quotation.path, 'quotations');
      expect(CrmDocType.invoice.path, 'invoices');
      // Receipts are sent from the payment, as on the web.
      expect(CrmDocType.receipt.path, 'payments');
    });
  });

  group('CrmShare.whatsapp (fallback when not connected)', () {
    test('adds the 91 prefix to a 10-digit Indian number', () {
      expect(
        CrmShare.whatsapp('98765 43210', 'Hi').toString(),
        'https://wa.me/919876543210?text=Hi',
      );
    });

    test('drops a leading 0 and encodes the message', () {
      expect(
        CrmShare.whatsapp('09876543210', 'a & b').toString(),
        'https://wa.me/919876543210?text=a%20%26%20b',
      );
    });
  });

  testWidgets('WhatsAppIcon renders the WhatsApp logo in WhatsApp green', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WhatsAppIcon(size: 20))),
    );

    final icon = tester.widget<FaIcon>(find.byType(FaIcon));
    expect(icon.icon, FontAwesomeIcons.whatsapp.data);
    expect(icon.size, 20);
    expect(icon.color, WhatsAppIcon.green);
  });
}
