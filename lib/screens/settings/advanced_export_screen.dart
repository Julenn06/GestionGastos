import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../services/investment_service.dart';
import '../../core/theme/app_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

/// Pantalla de Exportación Avanzada
/// 
/// Permite exportar datos a PDF con gráficos o Excel con múltiples hojas
class AdvancedExportScreen extends StatefulWidget {
  const AdvancedExportScreen({super.key});

  @override
  State<AdvancedExportScreen> createState() => _AdvancedExportScreenState();
}

class _AdvancedExportScreenState extends State<AdvancedExportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedFormat = 'pdf';
  bool _includeCharts = true;
  bool _includeInvestments = true;
  bool _includeStatistics = true;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportación Avanzada'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selector de formato
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Formato de Exportación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedFormat = 'pdf'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedFormat == 'pdf'
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _selectedFormat == 'pdf'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: _selectedFormat == 'pdf'
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'PDF',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Documento con gráficos',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedFormat = 'excel'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedFormat == 'excel'
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _selectedFormat == 'excel'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: _selectedFormat == 'excel'
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Excel',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Hoja de cálculo',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rango de fechas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Período',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectStartDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Desde', style: TextStyle(fontSize: 12)),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_startDate),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectEndDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hasta', style: TextStyle(fontSize: 12)),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_endDate),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Última semana'),
                        selected: false,
                        onSelected: (_) {
                          setState(() {
                            _startDate = DateTime.now().subtract(const Duration(days: 7));
                            _endDate = DateTime.now();
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Último mes'),
                        selected: false,
                        onSelected: (_) {
                          setState(() {
                            _startDate = DateTime.now().subtract(const Duration(days: 30));
                            _endDate = DateTime.now();
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Último año'),
                        selected: false,
                        onSelected: (_) {
                          setState(() {
                            _startDate = DateTime.now().subtract(const Duration(days: 365));
                            _endDate = DateTime.now();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Opciones de contenido
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contenido a Incluir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFormat == 'pdf') ...[
                    CheckboxListTile(
                      title: const Text('Gráficos'),
                      subtitle: const Text('Incluir visualizaciones'),
                      value: _includeCharts,
                      onChanged: (value) {
                        setState(() => _includeCharts = value ?? true);
                      },
                    ),
                  ],
                  CheckboxListTile(
                    title: const Text('Inversiones'),
                    subtitle: const Text('Incluir datos de inversiones'),
                    value: _includeInvestments,
                    onChanged: (value) {
                      setState(() => _includeInvestments = value ?? true);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Estadísticas'),
                    subtitle: const Text('Incluir resumen estadístico'),
                    value: _includeStatistics,
                    onChanged: (value) {
                      setState(() => _includeStatistics = value ?? true);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón de exportar
          FilledButton.icon(
            onPressed: _isExporting ? null : _export,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(
              _isExporting
                  ? 'Generando...'
                  : 'Exportar ${_selectedFormat.toUpperCase()}',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);

    try {
      if (_selectedFormat == 'pdf') {
        await _exportToPDF();
      } else {
        await _exportToExcel();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToPDF() async {
    final expenseService = context.read<ExpenseService>();
    final investmentService = context.read<InvestmentService>();

    // Obtener datos
    final expenses = await expenseService.getExpensesByDateRange(_startDate, _endDate);
    final investments = _includeInvestments
        ? investmentService.investments
        : [];

    // Crear PDF
    final pdf = pw.Document();

    // Página principal
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Título
          pw.Header(
            level: 0,
            child: pw.Text(
              'Reporte Financiero',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Período: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Resumen
          if (_includeStatistics) ...[
            pw.Header(level: 1, text: 'Resumen'),
            pw.SizedBox(height: 10),
            _buildSummarySection(expenses, investments),
            pw.SizedBox(height: 20),
          ],

          // Tabla de gastos
          pw.Header(level: 1, text: 'Detalle de Gastos'),
          pw.SizedBox(height: 10),
          _buildExpenseTable(expenses),
          pw.SizedBox(height: 20),

          // Inversiones
          if (_includeInvestments && investments.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Inversiones'),
            pw.SizedBox(height: 10),
            _buildInvestmentTable(investments),
          ],
        ],
      ),
    );

    // Guardar y compartir
    await _savePdfAndShare(pdf, 'reporte_financiero');
  }

  pw.Widget _buildSummarySection(List<dynamic> expenses, List<dynamic> investments) {
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalInvested = investments.fold<double>(0, (sum, i) => sum + i.amountInvested);
    final totalCurrentValue = investments.fold<double>(0, (sum, i) => sum + i.currentValue);
    final profitLoss = totalCurrentValue - totalInvested;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSummaryRow('Total Gastos:', '€${totalExpenses.toStringAsFixed(2)}'),
          pw.SizedBox(height: 8),
          _buildSummaryRow('Total Invertido:', '€${totalInvested.toStringAsFixed(2)}'),
          pw.SizedBox(height: 8),
          _buildSummaryRow('Valor Actual:', '€${totalCurrentValue.toStringAsFixed(2)}'),
          pw.SizedBox(height: 8),
          _buildSummaryRow(
            'Beneficio/Pérdida:',
            '€${profitLoss.toStringAsFixed(2)}',
            color: profitLoss >= 0 ? PdfColors.green : PdfColors.red,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildExpenseTable(List<dynamic> expenses) {
    if (expenses.isEmpty) {
      return pw.Text('No hay gastos en este período');
    }

    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
      },
      headers: ['Fecha', 'Categoría', 'Monto', 'Nota'],
      data: expenses.map((expense) {
        return [
          DateFormat('dd/MM/yy').format(expense.date),
          expense.category,
          '€${expense.amount.toStringAsFixed(2)}',
          expense.note ?? '-',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildInvestmentTable(List<dynamic> investments) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      headers: ['Nombre', 'Tipo', 'Invertido', 'Valor Actual', 'Ganancia'],
      data: investments.map((inv) {
        final profit = inv.currentValue - inv.amountInvested;
        return [
          inv.name,
          inv.type,
          '€${inv.amountInvested.toStringAsFixed(2)}',
          '€${inv.currentValue.toStringAsFixed(2)}',
          '€${profit.toStringAsFixed(2)}',
        ];
      }).toList(),
    );
  }

  Future<void> _savePdfAndShare(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.pdf');
    await file.writeAsBytes(bytes);

    final xFile = XFile(file.path);
    await SharePlus.instance.share(ShareParams(files: [xFile], subject: 'Reporte Financiero'));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generado correctamente'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _exportToExcel() async {
    final expenseService = context.read<ExpenseService>();
    final investmentService = context.read<InvestmentService>();

    // Crear libro Excel
    final workbook = excel_pkg.Excel.createExcel();

    // Hoja de gastos
    _addExpensesSheet(workbook, await expenseService.getExpensesByDateRange(_startDate, _endDate));

    // Hoja de inversiones
    if (_includeInvestments) {
      _addInvestmentsSheet(workbook, investmentService.investments);
    }

    // Hoja de resumen
    if (_includeStatistics) {
      _addSummarySheet(
        workbook,
        await expenseService.getExpensesByDateRange(_startDate, _endDate),
        investmentService.investments,
      );
    }

    // Eliminar hoja por defecto
    workbook.delete('Sheet1');

    // Guardar y compartir
    await _saveExcelAndShare(workbook, 'reporte_financiero');
  }

  void _addExpensesSheet(excel_pkg.Excel workbook, List<dynamic> expenses) {
    final sheet = workbook['Gastos'];

    // Encabezados
    sheet.appendRow([
      excel_pkg.TextCellValue('Fecha'),
      excel_pkg.TextCellValue('Categoría'),
      excel_pkg.TextCellValue('Subcategoría'),
      excel_pkg.TextCellValue('Monto'),
      excel_pkg.TextCellValue('Nota'),
    ]);

    // Datos
    for (final expense in expenses) {
      sheet.appendRow([
        excel_pkg.TextCellValue(DateFormat('dd/MM/yyyy').format(expense.date)),
        excel_pkg.TextCellValue(expense.category),
        excel_pkg.TextCellValue(expense.subcategory),
        excel_pkg.DoubleCellValue(expense.amount),
        excel_pkg.TextCellValue(expense.note ?? '-'),
      ]);
    }
  }

  void _addInvestmentsSheet(excel_pkg.Excel workbook, List<dynamic> investments) {
    final sheet = workbook['Inversiones'];

    sheet.appendRow([
      excel_pkg.TextCellValue('Nombre'),
      excel_pkg.TextCellValue('Tipo'),
      excel_pkg.TextCellValue('Plataforma'),
      excel_pkg.TextCellValue('Invertido'),
      excel_pkg.TextCellValue('Valor Actual'),
      excel_pkg.TextCellValue('Ganancia'),
      excel_pkg.TextCellValue('Fecha'),
    ]);

    for (final inv in investments) {
      final profit = inv.currentValue - inv.amountInvested;
      sheet.appendRow([
        excel_pkg.TextCellValue(inv.name),
        excel_pkg.TextCellValue(inv.type),
        excel_pkg.TextCellValue(inv.platform ?? '-'),
        excel_pkg.DoubleCellValue(inv.amountInvested),
        excel_pkg.DoubleCellValue(inv.currentValue),
        excel_pkg.DoubleCellValue(profit),
        excel_pkg.TextCellValue(DateFormat('dd/MM/yyyy').format(inv.dateInvested)),
      ]);
    }
  }

  void _addSummarySheet(excel_pkg.Excel workbook, List<dynamic> expenses, List<dynamic> investments) {
    final sheet = workbook['Resumen'];

    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalInvested = investments.fold<double>(0, (sum, i) => sum + i.amountInvested);
    final totalCurrentValue = investments.fold<double>(0, (sum, i) => sum + i.currentValue);
    final profitLoss = totalCurrentValue - totalInvested;

    sheet.appendRow([
      excel_pkg.TextCellValue('Métrica'),
      excel_pkg.TextCellValue('Valor'),
    ]);

    sheet.appendRow([
      excel_pkg.TextCellValue('Período Desde'),
      excel_pkg.TextCellValue(DateFormat('dd/MM/yyyy').format(_startDate)),
    ]);

    sheet.appendRow([
      excel_pkg.TextCellValue('Período Hasta'),
      excel_pkg.TextCellValue(DateFormat('dd/MM/yyyy').format(_endDate)),
    ]);

    sheet.appendRow([
      excel_pkg.TextCellValue('Total Gastos'),
      excel_pkg.DoubleCellValue(totalExpenses),
    ]);

    sheet.appendRow([
      excel_pkg.TextCellValue('Total Invertido'),
      excel_pkg.DoubleCellValue(totalInvested),
    ]);

    sheet.appendRow([
      excel_pkg.TextCellValue('Valor Actual Inversiones'),
      excel_pkg.DoubleCellValue(totalCurrentValue),
    ]);

    sheet.appendRow([
      excel_pkg.TextCellValue('Beneficio/Pérdida'),
      excel_pkg.DoubleCellValue(profitLoss),
    ]);
  }

  Future<void> _saveExcelAndShare(excel_pkg.Excel workbook, String filename) async {
    final bytes = workbook.encode();
    if (bytes == null) {
      throw Exception('Error al generar archivo Excel');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.xlsx');
    await file.writeAsBytes(bytes);

    final xFile = XFile(file.path);
    await SharePlus.instance.share(ShareParams(files: [xFile], subject: 'Reporte Financiero Excel'));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel generado correctamente'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
