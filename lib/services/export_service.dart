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
        'Phone',
        'Amount',
        'Type',
        'Purpose',
        'UTR Number',
        'Payment Status',
        'Created At',
        'Proof URL',
      ],
      ...donations.map((d) => [
            d.donorName,
            d.village,
            d.donorPhone ?? '',
            d.amount,
            d.type,
            d.purpose,
            d.utrNumber ?? '',
            d.paymentStatus,
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

  Future<void> shareDonationReceiptText(DonationModel donation) async {
    final dateStr =
        '${donation.createdAt.day.toString().padLeft(2, '0')}/${donation.createdAt.month.toString().padLeft(2, '0')}/${donation.createdAt.year}';
    final receiptNumber = donation.id.length > 8
        ? donation.id.substring(0, 8).toUpperCase()
        : (donation.id.isNotEmpty ? donation.id.toUpperCase() : 'REC-${DateTime.now().millisecondsSinceEpoch % 10000}');

    final buffer = StringBuffer();
    buffer.writeln('🚩 *श्री अखंड हरिनाम सप्ताह समिती* 🚩');
    buffer.writeln('चिंचोली-भोसे');
    buffer.writeln('═════════════════════════');
    buffer.writeln('📜 *देणगी पावती (Donation Receipt)*');
    buffer.writeln('पावती क्र: #$receiptNumber');
    buffer.writeln('तारीख: $dateStr');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 *देणगीदार:* ${donation.donorName}');
    buffer.writeln('🏡 *गाव:* ${donation.village}');
    if (donation.donorPhone != null && donation.donorPhone!.isNotEmpty) {
      buffer.writeln('📱 *मोबाईल:* ${donation.donorPhone}');
    }
    buffer.writeln('💰 *रक्कम:* ₹${donation.amount.toStringAsFixed(0)}');
    buffer.writeln('💳 *प्रकार:* ${donation.type}');
    buffer.writeln('🎯 *उद्देश:* ${donation.purpose}');
    if (donation.utrNumber != null && donation.utrNumber!.isNotEmpty) {
      buffer.writeln('🔢 *UPI UTR / Ref:* ${donation.utrNumber}');
      buffer.writeln('🛡️ *स्थिती:* ${donation.isVerified ? "स्वीकृत ✓" : "पडताळणी प्रलंबित ⏳"}');
    }
    if (donation.itemDescription != null &&
        donation.itemDescription!.isNotEmpty) {
      buffer.writeln('📦 *वस्तू तपशील:* ${donation.itemDescription}');
    }
    buffer.writeln('✍️ *नोंदणीकर्ता:* ${donation.addedByName}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🙏 *आपल्या सहकार्याबद्दल मनःपूर्वक धन्यवाद!*');
    buffer.writeln('🚩 *पुंडलिक वरदा हरी विठ्ठल, श्री ज्ञानदेव तुकाराम!*');

    await Share.share(
      buffer.toString(),
      subject: 'देणगी पावती - ${donation.donorName}',
    );
  }

  Future<void> exportSingleDonationPdf(DonationModel donation) async {
    final doc = pw.Document();
    final receiptNumber = donation.id.length > 8
        ? donation.id.substring(0, 8).toUpperCase()
        : (donation.id.isNotEmpty ? donation.id.toUpperCase() : 'REC-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final dateStr =
        '${donation.createdAt.day.toString().padLeft(2, '0')}/${donation.createdAt.month.toString().padLeft(2, '0')}/${donation.createdAt.year}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.orange, width: 2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Shri Akhand Harinam Saptah',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepOrange,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Chincholi-Bhose',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.orange),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt No: #$receiptNumber',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: $dateStr'),
                ],
              ),
              pw.SizedBox(height: 14),
              _pdfRow('Donor Name:', donation.donorName),
              _pdfRow('Village:', donation.village),
              if (donation.donorPhone != null && donation.donorPhone!.isNotEmpty)
                _pdfRow('Mobile:', donation.donorPhone!),
              _pdfRow('Amount:', 'Rs. ${donation.amount.toStringAsFixed(0)}'),
              _pdfRow('Payment Type:', donation.type),
              _pdfRow('Purpose:', donation.purpose),
              if (donation.itemDescription != null &&
                  donation.itemDescription!.isNotEmpty)
                _pdfRow('Item Details:', donation.itemDescription!),
              _pdfRow('Received By:', donation.addedByName),
              pw.Spacer(),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Thank you for your noble contribution!',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Authorized Signature',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/receipt_${donation.donorName.replaceAll(' ', '_')}_$receiptNumber.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([XFile(filePath)], text: 'Donation Receipt');
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
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
