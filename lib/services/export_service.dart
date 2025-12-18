import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../core/utils/log_service.dart';

/// Servicio de exportación de datos
/// 
/// Proporciona funcionalidad para exportar datos financieros
/// a diferentes formatos (CSV, PDF) para análisis externo.
class ExportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  // ============ Exportación CSV ============

  /// Exporta gastos a formato CSV
  Future<String?> exportExpensesToCsv(List<Expense> expenses) async {
    try {
      // Crear filas de datos
      List<List<dynamic>> rows = [
        ['Fecha', 'Categoría', 'Subcategoría', 'Monto', 'Nota', 'Acción Rápida'],
      ];

      for (final expense in expenses) {
        rows.add([
          _dateFormat.format(expense.date),
          expense.category,
          expense.subcategory,
          expense.amount.toStringAsFixed(2),
          expense.note ?? '',
          expense.isQuickAction ? 'Sí' : 'No',
        ]);
      }

      // Convertir a CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/gastos_$timestamp.csv';
      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      LogService.error('Error al exportar a CSV', e, null, 'ExportService');
      return null;
    }
  }



  // ============ Exportación PDF ============

  /// Exporta gastos a formato PDF
  Future<String?> exportExpensesToPdf(
    List<Expense> expenses,
    double totalExpenses,
  ) async {
    try {
      final pdf = pw.Document();

      // Agrupar gastos por categoría
      final Map<String, double> categoryTotals = {};
      for (final expense in expenses) {
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Encabezado
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Reporte de Gastos',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Información general
              pw.Text(
                'Periodo: ${_dateFormat.format(expenses.first.date)} - ${_dateFormat.format(expenses.last.date)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Total de gastos: ${expenses.length}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Monto total: ${_currencyFormat.format(totalExpenses)}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),

              // Resumen por categorías
              pw.Header(
                level: 1,
                child: pw.Text('Resumen por Categorías'),
              ),
              pw.TableHelper.fromTextArray(
                headers: ['Categoría', 'Monto'],
                data: categoryTotals.entries.map((entry) {
                  return [entry.key, _currencyFormat.format(entry.value)];
                }).toList(),
              ),
              pw.SizedBox(height: 20),

              // Lista detallada de gastos
              pw.Header(
                level: 1,
                child: pw.Text('Detalle de Gastos'),
              ),
              pw.TableHelper.fromTextArray(
                headers: ['Fecha', 'Categoría', 'Subcategoría', 'Monto', 'Nota'],
                data: expenses.map((expense) {
                  return [
                    _dateFormat.format(expense.date),
                    expense.category,
                    expense.subcategory,
                    _currencyFormat.format(expense.amount),
                    expense.note ?? '-',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerLeft,
                },
              ),
            ];
          },
        ),
      );

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/reporte_gastos_$timestamp.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      LogService.error('Error al exportar a PDF', e, null, 'ExportService');
      return null;
    }
  }



  // ============ Compartir Archivos ============

  /// Comparte un archivo exportado
  Future<void> shareFile(String filePath, String mimeType) async {
    try {
      final xFile = XFile(filePath);
      await SharePlus.instance.share(ShareParams(files: [xFile]));
    } catch (e) {
      LogService.error('Error al compartir archivo', e, null, 'ExportService');
    }
  }


}
