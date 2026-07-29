import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import 'auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

//-------------------- INVOICE PDF SERVICE --------------------
// Thermal-receipt style PDF: monospace font, dashed line separators.
class InvoicePdfService {
  //-------------------- SHOP DETAILS (customize here) --------------------
  static const String shopName = 'AL-HASEEB FOODS & BAKERS';
  static const String shopTagline = 'Taste & Quality You Can Trust';
  static const String shopPhone = 'Phone: 051X-XXXXXXX';
  static const String shopEmail = 'Email: alhaseeb@gmail.com';

  static const int lineWidth = 42;

  //-------------------- STRING PADDING HELPERS --------------------
  String _padRight(String s, int len) =>
      s.length >= len ? s.substring(0, len) : s.padRight(len);

  String _padLeft(String s, int len) =>
      s.length >= len ? s.substring(0, len) : s.padLeft(len);

  String _dashLine([int len = lineWidth]) => '-' * len;

  String _center(String s, [int len = lineWidth]) {
    if (s.length >= len) return s.substring(0, len);
    final totalPad = len - s.length;
    final left = totalPad ~/ 2;
    final right = totalPad - left;
    return ' ' * left + s + ' ' * right;
  }

  //-------------------- GENERATE PDF DOCUMENT --------------------
  Future<pw.Document> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final font = pw.Font.courier();

    // Resolve creator/staff name
    String staffName = 'Admin';
    if (invoice.createdBy.isNotEmpty) {
      try {
        final userData = await AuthService().getUserData(invoice.createdBy);
        if (userData != null && userData.name.isNotEmpty) {
          staffName = userData.name;
        }
      } catch (_) {}
    }

    //---------- BUILD RECEIPT TEXT LINES ----------
    final buffer = StringBuffer();

    buffer.writeln(_dashLine());
    buffer.writeln(_center(shopName));
    buffer.writeln(_center(shopTagline));
    buffer.writeln(_center(shopPhone));
    buffer.writeln(_center(shopEmail));
    buffer.writeln(_dashLine());
    buffer.writeln('Invoice No : ${invoice.invoiceNumber}');
    buffer.writeln('Date       : ${_formatDate(invoice.date)}');
    buffer.writeln('Customer   : ${invoice.customerName}');
    buffer.writeln(_dashLine());
    buffer.writeln(
      '${_padRight("Product", 16)}${_padLeft("Qty", 6)}${_padLeft("Price", 10)}${_padLeft("Total", 10)}',
    );
    buffer.writeln(_dashLine());

    for (var item in invoice.items) {
      buffer.writeln(
        '${_padRight(item.productName, 16)}${_padLeft("${item.quantity}", 6)}${_padLeft(item.price.toStringAsFixed(0), 10)}${_padLeft(item.total.toStringAsFixed(0), 10)}',
      );
    }

    final subTotal = invoice.totalAmount + invoice.discount - invoice.tax;
    if (invoice.discount > 0 || invoice.tax > 0) {
      buffer.writeln(
        '${_padRight("SUBTOTAL", 28)}${_padLeft("Rs.${subTotal.toStringAsFixed(0)}", 14)}',
      );
      if (invoice.discount > 0) {
        buffer.writeln(
          '${_padRight("DISCOUNT", 28)}${_padLeft("-Rs.${invoice.discount.toStringAsFixed(0)}", 14)}',
        );
      }
      if (invoice.tax > 0) {
        buffer.writeln(
          '${_padRight("TAX", 28)}${_padLeft("+Rs.${invoice.tax.toStringAsFixed(0)}", 14)}',
        );
      }
      buffer.writeln(_dashLine());
    }

    buffer.writeln(
      '${_padRight("TOTAL AMOUNT", 28)}${_padLeft("Rs.${invoice.totalAmount.toStringAsFixed(0)}", 14)}',
    );
    buffer.writeln(
      '${_padRight("PAID AMOUNT", 28)}${_padLeft("Rs.${invoice.amountPaid.toStringAsFixed(0)}", 14)}',
    );
    if (invoice.dueAmount > 0) {
      buffer.writeln(
        '${_padRight("REMAINING DUES", 28)}${_padLeft("Rs.${invoice.dueAmount.toStringAsFixed(0)}", 14)}',
      );
      if (invoice.dueDate != null) {
        buffer.writeln(
          '${_padRight("DUE DATE", 28)}${_padLeft(_formatDate(invoice.dueDate!), 14)}',
        );
      }
    }
    buffer.writeln(_dashLine());
    buffer.writeln(_center('Thank you for shopping.'));
    buffer.writeln(_center('Powered by $shopName'));

    //---------- ADD TO PDF PAGE ----------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // thermal receipt width
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Text(
            buffer.toString(),
            style: pw.TextStyle(font: font, fontSize: 9, lineSpacing: 2),
          );
        },
      ),
    );

    return pdf;
  }

  //-------------------- FORMAT DATE --------------------
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  //-------------------- SHARE / PRINT / SAVE (opens native share sheet) --------------------
  Future<void> sharePdf(InvoiceModel invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${invoice.invoiceNumber}.pdf',
    );
  }

  //-------------------- DOWNLOAD PDF TO DEVICE --------------------
  // Returns the saved file path (so caller can show it to the user)
  Future<String> downloadPdf(InvoiceModel invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    final bytes = await pdf.save();

    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final folder = Directory('${directory!.path}/Invoices');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final filePath = '${folder.path}/${invoice.invoiceNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  //-------------------- VIEW / PREVIEW PDF --------------------
  Future<void> viewPdf(InvoiceModel invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    final bytes = await pdf.save();

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${invoice.invoiceNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    await OpenFile.open(filePath);
  }

  //-------------------- PREVIEW + PRINT DIALOG --------------------
  Future<void> printPdf(InvoiceModel invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
