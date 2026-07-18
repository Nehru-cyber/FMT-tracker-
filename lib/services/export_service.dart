import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExportService {
  static final _dateFormat = DateFormat('dd MMM yyyy');

  /// Load fonts that support all currency symbols (₹, $, €, £, ¥).
  static Future<pw.Font> _loadFont({bool bold = false}) async {
    try {
      if (bold) {
        return await PdfGoogleFonts.notoSansBold();
      }
      return await PdfGoogleFonts.notoSansRegular();
    } catch (_) {
      // Fallback: use Helvetica
      return bold ? pw.Font.helveticaBold() : pw.Font.helvetica();
    }
  }

  /// Get the currency symbol for PDF (fallback to text if font can't render).
  static String _safeCurrencySymbol(String symbol) {
    // These symbols are supported by most TTF fonts
    const supported = {'\$', '€', '£', '¥', '₹'};
    if (supported.contains(symbol)) return symbol;
    return symbol;
  }

  static Future<File> exportToPDF({
    required List<Expense> expenses,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String currencySymbol = '₹',
  }) async {
    final font = await _loadFont();
    final fontBold = await _loadFont(bold: true);

    final baseStyle = pw.TextStyle(font: font);
    final boldStyle = pw.TextStyle(font: fontBold, fontWeight: pw.FontWeight.bold);

    final symbol = _safeCurrencySymbol(currencySymbol);
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 2);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    double totalIncome = 0;
    double totalExpense = 0;

    for (final e in expenses) {
      if (e.type == ExpenseType.income) {
        totalIncome += e.amount;
      } else {
        totalExpense += e.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title, style: boldStyle.copyWith(fontSize: 24)),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Period: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
            style: baseStyle,
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryBox('Income', totalIncome, PdfColors.green, currencyFormat, baseStyle, boldStyle),
              _buildSummaryBox('Expense', totalExpense, PdfColors.red, currencyFormat, baseStyle, boldStyle),
              _buildSummaryBox('Balance', totalIncome - totalExpense, PdfColors.blue, currencyFormat, baseStyle, boldStyle),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Category', 'Type', 'Amount', 'Note'],
            headerStyle: boldStyle.copyWith(fontSize: 10),
            cellStyle: baseStyle.copyWith(fontSize: 9),
            data: expenses.map((e) => [
              _dateFormat.format(e.date),
              e.category,
              e.type.name.toUpperCase(),
              currencyFormat.format(e.amount),
              e.note,
            ]).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryBox(
    String label,
    double amount,
    PdfColor color,
    NumberFormat currencyFormat,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: boldStyle),
          pw.Text(currencyFormat.format(amount), style: baseStyle),
        ],
      ),
    );
  }

  static Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }
}

