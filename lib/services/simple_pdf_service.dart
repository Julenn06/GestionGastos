import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/investment.dart';
import '../core/utils/log_service.dart';

/// Servicio simple y directo de generación de PDFs
/// Sin portada, directo al grano con la información esencial
class SimplePdfService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '€',
    decimalDigits: 2,
  );

  /// Genera reporte simple de gastos
  Future<String?> generateExpenseReport({
    required List<Expense> expenses,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();
      final stats = await compute(_calculateExpenseStats, expenses);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            _buildHeader(
              'Reporte de Gastos',
              startDate != null && endDate != null
                  ? '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'
                  : 'Todos los gastos',
            ),
            pw.SizedBox(height: 16),

            // Resumen rápido
            _buildSummaryRow(
              'Total de gastos:',
              _currencyFormat.format(stats['total']),
            ),
            _buildSummaryRow(
              'Promedio diario:',
              _currencyFormat.format(stats['averageDaily']),
            ),
            _buildSummaryRow('Número de gastos:', '${expenses.length}'),
            _buildSummaryRow(
              'Categorías diferentes:',
              '${stats['categoriesCount']}',
            ),

            pw.SizedBox(height: 20),

            // Top categorías
            pw.Text(
              'Top Categorías',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildTopCategories(stats['topCategories']),

            pw.SizedBox(height: 20),

            // Tabla de gastos
            pw.Text(
              'Detalle de Gastos',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildExpenseTable(expenses),
          ],
        ),
      );

      return await _savePdf(pdf, 'gastos');
    } catch (e) {
      LogService.error(
        'Error generando PDF de gastos',
        e,
        null,
        'SimplePdfService',
      );
      return null;
    }
  }

  /// Genera reporte simple de inversiones
  Future<String?> generateInvestmentReport({
    required List<Investment> investments,
  }) async {
    try {
      final pdf = pw.Document();
      final stats = await compute(_calculateInvestmentStats, investments);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            _buildHeader('Reporte de Inversiones', 'Portfolio'),
            pw.SizedBox(height: 16),

            // Resumen
            _buildSummaryRow(
              'Total invertido:',
              _currencyFormat.format(stats['totalInvested']),
            ),
            _buildSummaryRow(
              'Valor actual:',
              _currencyFormat.format(stats['currentValue']),
            ),
            _buildSummaryRow(
              'Ganancia/Pérdida:',
              _currencyFormat.format(stats['profitLoss']),
            ),
            _buildSummaryRow('ROI:', '${stats['roi'].toStringAsFixed(2)}%'),

            pw.SizedBox(height: 20),

            // Tabla de inversiones
            pw.Text(
              'Detalle de Inversiones',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildInvestmentTable(investments),
          ],
        ),
      );

      return await _savePdf(pdf, 'inversiones');
    } catch (e) {
      LogService.error(
        'Error generando PDF de inversiones',
        e,
        null,
        'SimplePdfService',
      );
      return null;
    }
  }

  /// Genera reporte completo
  Future<String?> generateCompleteReport({
    required List<Expense> expenses,
    required List<Investment> investments,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();
      final expenseStats = await compute(_calculateExpenseStats, expenses);
      final investmentStats = await compute(
        _calculateInvestmentStats,
        investments,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            _buildHeader(
              'Reporte Financiero',
              startDate != null && endDate != null
                  ? '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'
                  : 'Completo',
            ),
            pw.SizedBox(height: 16),

            // Balance
            _buildBalanceBox(expenseStats, investmentStats),
            pw.SizedBox(height: 20),

            // GASTOS
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.grey200,
              child: pw.Text(
                'GASTOS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            _buildSummaryRow(
              'Total:',
              _currencyFormat.format(expenseStats['total']),
            ),
            _buildSummaryRow(
              'Promedio diario:',
              _currencyFormat.format(expenseStats['averageDaily']),
            ),
            pw.SizedBox(height: 12),
            _buildTopCategories(expenseStats['topCategories']),

            pw.SizedBox(height: 20),

            // INVERSIONES
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.grey200,
              child: pw.Text(
                'INVERSIONES',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            _buildSummaryRow(
              'Total invertido:',
              _currencyFormat.format(investmentStats['totalInvested']),
            ),
            _buildSummaryRow(
              'Valor actual:',
              _currencyFormat.format(investmentStats['currentValue']),
            ),
            _buildSummaryRow(
              'ROI:',
              '${investmentStats['roi'].toStringAsFixed(2)}%',
            ),

            pw.SizedBox(height: 20),

            // Detalle de gastos
            pw.Text(
              'Detalle de Gastos',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildExpenseTable(expenses),

            pw.SizedBox(height: 20),

            // Detalle de inversiones
            pw.Text(
              'Detalle de Inversiones',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildInvestmentTable(investments),
          ],
        ),
      );

      return await _savePdf(pdf, 'reporte_completo');
    } catch (e) {
      LogService.error(
        'Error generando PDF completo',
        e,
        null,
        'SimplePdfService',
      );
      return null;
    }
  }

  // ============ COMPONENTES ============

  pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          subtitle,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 1.5),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBalanceBox(
    Map<String, dynamic> expenseStats,
    Map<String, dynamic> investmentStats,
  ) {
    final balance =
        (investmentStats['currentValue'] as double) -
        (expenseStats['total'] as double);
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 1.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'BALANCE TOTAL',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            _currencyFormat.format(balance),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: balance >= 0 ? PdfColors.green : PdfColors.red,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopCategories(List<Map<String, dynamic>> categories) {
    const maxBarWidth = 300.0; // Ancho máximo de la barra
    return pw.Column(
      children: categories.take(5).map((cat) {
        final percentage = cat['percentage'] as double;
        final barWidth = maxBarWidth * (percentage / 100);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 100,
                child: pw.Text(
                  cat['name'] as String,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Container(
                width: maxBarWidth,
                height: 12,
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    width: barWidth,
                    height: 12,
                    color: PdfColors.blue,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 60,
                child: pw.Text(
                  _currencyFormat.format(cat['amount']),
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildExpenseTable(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return pw.Text('No hay gastos', style: const pw.TextStyle(fontSize: 9));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(55),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(55),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildCell('Fecha', isHeader: true),
            _buildCell('Categoría', isHeader: true),
            _buildCell('Subcategoría', isHeader: true),
            _buildCell('Monto', isHeader: true),
          ],
        ),
        ...expenses.map(
          (e) => pw.TableRow(
            children: [
              _buildCell(_dateFormat.format(e.date)),
              _buildCell(e.category),
              _buildCell(e.subcategory),
              _buildCell(_currencyFormat.format(e.amount)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInvestmentTable(List<Investment> investments) {
    if (investments.isEmpty) {
      return pw.Text(
        'No hay inversiones',
        style: const pw.TextStyle(fontSize: 9),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FixedColumnWidth(55),
        3: const pw.FixedColumnWidth(55),
        4: const pw.FixedColumnWidth(45),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildCell('Nombre', isHeader: true),
            _buildCell('Tipo', isHeader: true),
            _buildCell('Invertido', isHeader: true),
            _buildCell('Actual', isHeader: true),
            _buildCell('ROI %', isHeader: true),
          ],
        ),
        ...investments.map((inv) {
          final roi = inv.profitLossPercentage;
          return pw.TableRow(
            children: [
              _buildCell(inv.name),
              _buildCell(inv.type),
              _buildCell(_currencyFormat.format(inv.amountInvested)),
              _buildCell(_currencyFormat.format(inv.currentValue)),
              _buildCell('${roi.toStringAsFixed(1)}%'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ============ UTILIDADES ============

  Future<String?> _savePdf(pw.Document pdf, String baseName) async {
    try {
      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/${baseName}_$timestamp.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      LogService.error('Error guardando PDF', e, null, 'SimplePdfService');
      return null;
    }
  }

  // ============ CÁLCULOS ESTADÍSTICOS ============

  static Map<String, dynamic> _calculateExpenseStats(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return {
        'total': 0.0,
        'averageDaily': 0.0,
        'categoriesCount': 0,
        'topCategories': [],
      };
    }

    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final daysDiff =
        expenses.last.date.difference(expenses.first.date).inDays + 1;
    final averageDaily = total / daysDiff;

    final Map<String, double> categoryTotals = {};
    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategoriesList = topCategories
        .take(5)
        .map(
          (entry) => {
            'name': entry.key,
            'amount': entry.value,
            'percentage': (entry.value / total) * 100,
          },
        )
        .toList();

    return {
      'total': total,
      'averageDaily': averageDaily,
      'categoriesCount': categoryTotals.length,
      'topCategories': topCategoriesList,
    };
  }

  static Map<String, dynamic> _calculateInvestmentStats(
    List<Investment> investments,
  ) {
    if (investments.isEmpty) {
      return {
        'totalInvested': 0.0,
        'currentValue': 0.0,
        'profitLoss': 0.0,
        'roi': 0.0,
      };
    }

    final totalInvested = investments.fold<double>(
      0,
      (sum, i) => sum + i.amountInvested,
    );
    final currentValue = investments.fold<double>(
      0,
      (sum, i) => sum + i.currentValue,
    );
    final profitLoss = currentValue - totalInvested;
    final roi = totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0.0;

    return {
      'totalInvested': totalInvested,
      'currentValue': currentValue,
      'profitLoss': profitLoss,
      'roi': roi,
    };
  }
}
