import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../api_services/crm_api.dart';
import '../../utils/common_app_bar.dart';

/// Shows a CRM quotation / invoice / receipt PDF with share, print and save —
/// the app's version of the web opening the PDF in a new tab.
class CrmPdfScreen extends StatefulWidget {
  final String title;

  /// One of `CrmApi.quotationPdf / invoicePdf / receiptPdf`.
  final String path;

  const CrmPdfScreen({super.key, required this.title, required this.path});

  @override
  State<CrmPdfScreen> createState() => _CrmPdfScreenState();
}

class _CrmPdfScreenState extends State<CrmPdfScreen> {
  late final Future<Uint8List> _pdf = CrmApi().downloadPdf(widget.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: widget.title),
      body: FutureBuilder<Uint8List>(
        future: _pdf,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snap.error is CrmException
                      ? (snap.error as CrmException).message
                      : 'Could not open the file.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return PdfPreview(
            build: (_) async => snap.data!,
            pdfFileName:
                '${widget.title.replaceAll(RegExp(r'[^\w-]+'), '-')}.pdf',
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}
