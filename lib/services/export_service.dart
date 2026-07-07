import 'dart:io';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/donation_model.dart';

class ExportService {
  Future<void> exportDonationsCSV(List<DonationModel> donations) async {
    final rows = <List<dynamic>>[
      [
        'Donor Name',
        'Village',
        'Amount',
        'Type',
        'Purpose',
        'Created At',
        'Proof URL',
      ],
      ...donations.map((d) => [
            d.donorName,
            d.village,
            d.amount,
            d.type,
            d.purpose,
            d.createdAt.toIso8601String(),
            d.proofImageUrl ?? '',
          ]),
    ];

    final csvString = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/donations_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(filePath);
    await file.writeAsString(csvString, encoding: utf8);

    await Share.shareXFiles([XFile(filePath)], text: 'Donations CSV');
  }

  Future<void> exportDonationsPDF(List<DonationModel> donations) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Donations Report',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Generated: ${DateTime.now().toString()}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Donor',
                'Village',
                'Amount',
                'Type',
                'Purpose',
              ],
              data: donations
                  .map(
                    (d) => [
                      d.donorName,
                      d.village,
                      d.amount.toStringAsFixed(0),
                      d.type,
                      d.purpose,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/donations_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([XFile(filePath)], text: 'Donations PDF');
  }
}
