import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/daily_log.dart';
import '../../core/models/egg_sale.dart';
import '../../core/models/expense.dart';
import '../../shared/widgets/shared_widgets.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _generating = false;

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final db = DatabaseHelper.instance;
      final logs = await db.getDailyLogsByDateRange(_startDate, _endDate);
      final sales = await db.getEggSalesByDateRange(_startDate, _endDate);
      final expenses = await db.getExpensesByDateRange(_startDate, _endDate);

      final pdfBytes = await _buildPdf(logs, sales, expenses);
      final dir = await getApplicationDocumentsDirectory();
      final fmt = DateFormat('yyyyMMdd');
      final file = File(
          '${dir.path}/davefarm_${fmt.format(_startDate)}_${fmt.format(_endDate)}.pdf');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: file.path.split('/').last,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<Uint8List> _buildPdf(
    List<DailyLog> logs,
    List<EggSale> sales,
    List<Expense> expenses,
  ) async {
    final pdf = pw.Document();
    final fmt = DateFormat('MMM d, yyyy');
    final dfmt = DateFormat('yyyy-MM-dd');

    final totalGoodEggs = logs.fold(0, (s, l) => s + l.goodEggs);
    final totalBrokenEggs = logs.fold(0, (s, l) => s + l.brokenEggs);
    final totalDeadBirds = logs.fold(0, (s, l) => s + l.deadBirds);
    final totalSales =
        sales.fold(0.0, (s, e) => s + e.totalPrice);
    final totalExpenses =
        expenses.fold(0.0, (s, e) => s + e.amount);
    final netProfit = totalSales - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Dave Farm Report',
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      '${fmt.format(_startDate)} — ${fmt.format(_endDate)}',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey600)),
                ],
              ),
              pw.Text('Generated: ${dfmt.format(DateTime.now())}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey500)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Summary
          pw.Text('Summary',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _summaryTable({
            'Good Eggs': totalGoodEggs.toString(),
            'Broken Eggs': totalBrokenEggs.toString(),
            'Dead Birds': totalDeadBirds.toString(),
            'Total Sales': 'ETB ${totalSales.toStringAsFixed(2)}',
            'Total Expenses': 'ETB ${totalExpenses.toStringAsFixed(2)}',
            'Net Profit':
                'ETB ${netProfit.toStringAsFixed(2)}',
          }),
          pw.SizedBox(height: 20),

          // Daily Logs table
          if (logs.isNotEmpty) ...[
            pw.Text('Daily Production Logs',
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _dataTable(
              headers: ['Date', 'Flock', 'Good', 'Broken', 'Dead'],
              rows: logs
                  .map((l) => [
                        dfmt.format(l.date),
                        l.flockId.substring(0, 8),
                        '${l.goodEggs}',
                        '${l.brokenEggs}',
                        '${l.deadBirds}',
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Egg Sales table
          if (sales.isNotEmpty) ...[
            pw.Text('Egg Sales',
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _dataTable(
              headers: ['Date', 'Customer', 'Qty', 'Unit', 'Total'],
              rows: sales
                  .map((s) => [
                        dfmt.format(s.date),
                        s.customerName,
                        '${s.quantity}',
                        s.unitPrice.toStringAsFixed(2),
                        s.totalPrice.toStringAsFixed(2),
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Expenses table
          if (expenses.isNotEmpty) ...[
            pw.Text('Expenses',
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _dataTable(
              headers: ['Date', 'Category', 'Amount', 'Notes'],
              rows: expenses
                  .map((e) => [
                        dfmt.format(e.date),
                        e.category.value,
                        e.amount.toStringAsFixed(2),
                        e.notes ?? '-',
                      ])
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _summaryTable(Map<String, String> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: data.entries
          .map((e) => pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(e.key,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(e.value),
                ),
              ]))
          .toList(),
    );
  }

  pw.Widget _dataTable(
      {required List<String> headers, required List<List<String>> rows}) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                  ))
              .toList(),
        ),
        ...rows.map((row) => pw.TableRow(
              children: row
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(cell,
                            style: const pw.TextStyle(fontSize: 9)),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Report')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(children: [
                      Icon(Icons.date_range_rounded, color: Colors.white54),
                      SizedBox(width: 8),
                      Text('Select Date Range',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ]),
                    const SizedBox(height: 12),
                    DatePickerTile(
                      label: 'Start Date',
                      date: _startDate,
                      onChanged: (d) => setState(() => _startDate = d),
                    ),
                    const Divider(height: 1),
                    DatePickerTile(
                      label: 'End Date',
                      date: _endDate,
                      onChanged: (d) => setState(() => _endDate = d),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_rounded),
              label:
                  Text(_generating ? 'Generating…' : 'Generate & Share PDF'),
            ),
            const SizedBox(height: 16),
            const Text(
              'The PDF will be saved locally and shared via your messaging apps.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
