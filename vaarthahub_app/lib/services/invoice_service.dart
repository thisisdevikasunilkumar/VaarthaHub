import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class InvoiceService {
  static Future<void> generateInvoice({
    required Map<String, dynamic> booking,
    required Map<String, dynamic> reader,
  }) async {
    final pdf = pw.Document();

    final date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    
    // Using a standard font that supports common characters
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title
            pw.Center(
              child: pw.Text(
                'Bill of Supply',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
            ),
            pw.SizedBox(height: 20),

            // Header Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabelValue('Bill of Supply Number:', 'VH-${booking['bookingId']}'),
                    _buildLabelValue('Bill of Supply Date:', date),
                    _buildLabelValue('Order Number:', 'OD${booking['bookingId']}123456789'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabelValue('Nature of transaction:', 'INTRA'),
                    _buildLabelValue('Nature Of Supply:', 'Service'),
                  ],
                ),
              ],
            ),
            pw.Divider(),

            // Billed From / Billed To
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Billed From', style: pw.TextStyle(font: boldFont)),
                      pw.Text('VaarthaHub India Private Limited'),
                      pw.Text('ESR Warehousing and Logistic Park, B.No:3 & B.No:4,'),
                      pw.Text('Thrissur, Kerala - 680001, India'),
                      pw.Text('GSTIN : 32AABCV1234M1ZY'),
                      pw.Text('PAN : AABCV1234M'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Billed To', style: pw.TextStyle(font: boldFont)),
                      pw.Text(reader['fullName'] ?? 'Reader Name'),
                      pw.Text('${reader['houseName']}, ${reader['houseNo']}'),
                      pw.Text('${reader['landmark']}, ${reader['panchayatName']}'),
                      pw.Text('Kerala, India - ${reader['pincode']}'),
                      pw.Text('State : Kerala'),
                      pw.Text('State Code : IN-KL'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Particulars Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _tableCell('Particulars', isBold: true),
                    _tableCell('SAC', isBold: true),
                    _tableCell('Qty', isBold: true),
                    _tableCell('Price', isBold: true),
                    _tableCell('Total', isBold: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _tableCell('${booking['productName']} (${booking['year']})'),
                    _tableCell('996511'),
                    _tableCell(booking['quantity'].toString()),
                    _tableCell('RS. ${booking['unitPrice']}'),
                    _tableCell('RS. ${booking['totalAmount']}'),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Total Amount: RS. ${booking['totalAmount']}', style: pw.TextStyle(font: boldFont)),
                ],
              ),
            ),

            pw.SizedBox(height: 40),
            pw.Text(
              'I/we have taken registration under the CGST Act, 2017 and have exercised the option to pay tax on services of GTA in relation to transport of goods supplied by us from the Financial Year 2024-25 under forward charge and have not reverted to reverse charge mechanism.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Is the supply subject to reverse charge: No', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('Person Liable to pay tax: VaarthaHub India Private Limited', style: const pw.TextStyle(fontSize: 10)),
            
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Authorized Signatory', style: pw.TextStyle(font: boldFont)),
            ),
          ];
        },
      ),
    );

    // Show PDF preview / Download
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${booking['bookingId']}.pdf',
    );
  }

  static pw.Widget _buildLabelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }
}
