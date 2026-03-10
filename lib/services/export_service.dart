import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExportService {
  static final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  static final _dateFormat = DateFormat('dd MMM yyyy');
  
  static Future<File> exportToPDF({
    required List<Expense> expenses,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
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
            child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Period: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryBox('Income', totalIncome, PdfColors.green),
              _buildSummaryBox('Expense', totalExpense, PdfColors.red),
              _buildSummaryBox('Balance', totalIncome - totalExpense, PdfColors.blue),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Category', 'Type', 'Amount', 'Note'],
            data: expenses.map((e) => [
              _dateFormat.format(e.date),
              e.category,
              e.type.name.toUpperCase(),
              _currencyFormat.format(e.amount),
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
  
  static pw.Widget _buildSummaryBox(String label, double amount, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_currencyFormat.format(amount)),
        ],
      ),
    );
  }
  
  static Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }
}
