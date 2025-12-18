import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/investment.dart';
import '../core/utils/log_service.dart';

/// Servicio profesional de generación de PDFs
/// 
/// Genera reportes financieros con diseño ultra profesional:
/// - Logo y branding corporativo
/// - Gráficos de pastel y barras
/// - Tablas con diseño moderno
/// - Colores y tipografía profesional
/// - Páginas numeradas con headers/footers
/// - Secciones organizadas con índice
class ProfessionalPdfService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  // Colores corporativos
  static final PdfColor primaryColor = PdfColor.fromHex('#00D09E');
  static final PdfColor secondaryColor = PdfColor.fromHex('#5B8DEE');
  static final PdfColor accentColor = PdfColor.fromHex('#FFB84D');
  static final PdfColor darkBg = PdfColor.fromHex('#0A0E27');
  static final PdfColor cardBg = PdfColor.fromHex('#252B47');
  static final PdfColor successColor = PdfColor.fromHex('#00D09E');
  static final PdfColor errorColor = PdfColor.fromHex('#FF6B6B');
  static final PdfColor textPrimary = PdfColor.fromHex('#FFFFFF');
  static final PdfColor textSecondary = PdfColor.fromHex('#B0B8D4');

  /// Genera reporte profesional de gastos
  Future<String?> generateExpenseReport({
    required List<Expense> expenses,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      // Calcular estadísticas
      final stats = await compute(_calculateExpenseStats, expenses);
      
      // Página de portada
      pdf.addPage(_buildCoverPage(
        title: 'Reporte de Gastos',
        subtitle: startDate != null && endDate != null
            ? 'Período: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'
            : 'Reporte Completo',
        generatedDate: now,
      ));

      // Página de resumen ejecutivo
      pdf.addPage(_buildExecutiveSummaryPage(stats));

      // Página de gráficos
      pdf.addPage(_buildChartsPage(stats));

      // Páginas de detalle
      pdf.addPage(_buildExpenseDetailPages(expenses, stats));

      // Guardar archivo
      return await _savePdfFile(pdf, 'reporte_gastos');
    } catch (e) {
      LogService.error('Error generando PDF de gastos', e, null, 'ProfessionalPdfService');
      return null;
    }
  }

  /// Genera reporte profesional de inversiones
  Future<String?> generateInvestmentReport({
    required List<Investment> investments,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      // Calcular estadísticas
      final stats = await compute(_calculateInvestmentStats, investments);

      // Página de portada
      pdf.addPage(_buildCoverPage(
        title: 'Reporte de Inversiones',
        subtitle: 'Portfolio Completo',
        generatedDate: now,
      ));

      // Resumen ejecutivo
      pdf.addPage(_buildInvestmentSummaryPage(stats));

      // Gráficos
      pdf.addPage(_buildInvestmentChartsPage(stats, investments));

      // Detalle de inversiones
      pdf.addPage(_buildInvestmentDetailPages(investments, stats));

      // Guardar archivo
      return await _savePdfFile(pdf, 'reporte_inversiones');
    } catch (e) {
      LogService.error('Error generando PDF de inversiones', e, null, 'ProfessionalPdfService');
      return null;
    }
  }

  /// Genera reporte financiero completo
  Future<String?> generateCompleteReport({
    required List<Expense> expenses,
    required List<Investment> investments,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      // Calcular estadísticas
      final expenseStats = await compute(_calculateExpenseStats, expenses);
      final investmentStats = await compute(_calculateInvestmentStats, investments);

      // Portada
      pdf.addPage(_buildCoverPage(
        title: 'Reporte Financiero Completo',
        subtitle: 'Análisis Integral de Finanzas Personales',
        generatedDate: now,
      ));

      // Índice
      pdf.addPage(_buildTableOfContents());

      // Dashboard general
      pdf.addPage(_buildDashboardPage(expenseStats, investmentStats));

      // Sección de gastos
      pdf.addPage(_buildSectionDivider('Análisis de Gastos'));
      pdf.addPage(_buildExecutiveSummaryPage(expenseStats));
      pdf.addPage(_buildChartsPage(expenseStats));
      pdf.addPage(_buildExpenseDetailPages(expenses, expenseStats));

      // Sección de inversiones
      pdf.addPage(_buildSectionDivider('Portfolio de Inversiones'));
      pdf.addPage(_buildInvestmentSummaryPage(investmentStats));
      pdf.addPage(_buildInvestmentChartsPage(investmentStats, investments));
      pdf.addPage(_buildInvestmentDetailPages(investments, investmentStats));

      // Conclusiones
      pdf.addPage(_buildConclusionsPage(expenseStats, investmentStats));

      // Guardar archivo
      return await _savePdfFile(pdf, 'reporte_financiero_completo');
    } catch (e) {
      LogService.error('Error generando PDF completo', e, null, 'ProfessionalPdfService');
      return null;
    }
  }

  // ============ PÁGINAS DEL PDF ============

  pw.Page _buildCoverPage({
    required String title,
    required String subtitle,
    required DateTime generatedDate,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [darkBg, cardBg],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // Logo/Icon
              pw.Container(
                width: 120,
                height: 120,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  gradient: pw.LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '💰',
                    style: const pw.TextStyle(fontSize: 60),
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              
              // Título
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 42,
                  fontWeight: pw.FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 16),
              
              // Subtítulo
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  fontSize: 18,
                  color: textSecondary,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 60),
              
              // Información de generación
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: primaryColor, width: 2),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Generado el',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      _dateTimeFormat.format(generatedDate),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Footer
              pw.Spacer(),
              pw.Text(
                'Gestión de Gastos',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Reporte Profesional',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: textSecondary.shade(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  pw.Page _buildExecutiveSummaryPage(Map<String, dynamic> stats) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader('Resumen Ejecutivo'),
          pw.SizedBox(height: 30),

          // KPIs principales
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildKpiCard(
                title: 'Total Gastos',
                value: _currencyFormat.format(stats['total']),
                icon: '💸',
                color: errorColor,
              ),
              _buildKpiCard(
                title: 'Promedio Diario',
                value: _currencyFormat.format(stats['averageDaily']),
                icon: '📊',
                color: accentColor,
              ),
              _buildKpiCard(
                title: 'Categorías',
                value: '${stats['categoriesCount']}',
                icon: '📁',
                color: secondaryColor,
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Top 5 categorías
          _buildSubHeader('Top 5 Categorías'),
          pw.SizedBox(height: 15),
          _buildTopCategoriesTable(stats['topCategories']),
          
          pw.SizedBox(height: 30),

          // Comparativa mensual
          if (stats['monthlyComparison'] != null) ...[
            _buildSubHeader('Comparativa Mensual'),
            pw.SizedBox(height: 15),
            _buildMonthlyComparisonChart(stats['monthlyComparison']),
          ],
        ],
      ),
    );
  }

  pw.Page _buildChartsPage(Map<String, dynamic> stats) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader('Análisis Gráfico'),
          pw.SizedBox(height: 30),

          // Gráfico de pastel de categorías
          _buildSubHeader('Distribución por Categoría'),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Container(
              width: 400,
              height: 300,
              child: _buildPieChart(stats['categoryDistribution']),
            ),
          ),
          
          pw.SizedBox(height: 40),

          // Gráfico de barras de tendencia
          _buildSubHeader('Tendencia Temporal'),
          pw.SizedBox(height: 20),
          pw.Container(
            height: 200,
            child: _buildBarChart(stats['timelineTrend']),
          ),
        ],
      ),
    );
  }

  pw.Page _buildExpenseDetailPages(List<Expense> expenses, Map<String, dynamic> stats) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader('Detalle de Gastos'),
          pw.SizedBox(height: 20),
          
          // Tabla detallada
          pw.Expanded(
            child: _buildExpenseTable(expenses),
          ),
        ],
      ),
    );
  }

  pw.Page _buildInvestmentSummaryPage(Map<String, dynamic> stats) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader('Resumen de Inversiones'),
          pw.SizedBox(height: 30),

          // KPIs de inversiones
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildKpiCard(
                title: 'Total Invertido',
                value: _currencyFormat.format(stats['totalInvested']),
                icon: '💼',
                color: secondaryColor,
              ),
              _buildKpiCard(
                title: 'Valor Actual',
                value: _currencyFormat.format(stats['currentValue']),
                icon: '💰',
                color: primaryColor,
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildKpiCard(
                title: 'Ganancia/Pérdida',
                value: _currencyFormat.format(stats['profitLoss']),
                icon: stats['profitLoss'] >= 0 ? '📈' : '📉',
                color: stats['profitLoss'] >= 0 ? successColor : errorColor,
              ),
              _buildKpiCard(
                title: 'ROI',
                value: '${stats['roi'].toStringAsFixed(2)}%',
                icon: '🎯',
                color: accentColor,
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // Desglose por tipo
          _buildSubHeader('Distribución por Tipo'),
          pw.SizedBox(height: 15),
          _buildInvestmentTypeTable(stats['byType']),
        ],
      ),
    );
  }

  pw.Page _buildInvestmentChartsPage(Map<String, dynamic> stats, List<Investment> investments) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader('Análisis de Portfolio'),
          pw.SizedBox(height: 30),

          // Gráfico de composición
          _buildSubHeader('Composición del Portfolio'),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Container(
              width: 400,
              height: 300,
              child: _buildPieChart(stats['typeDistribution']),
            ),
          ),
          
          pw.SizedBox(height: 40),

          // Performance individual
          _buildSubHeader('Performance Individual'),
          pw.SizedBox(height: 20),
          _buildPerformanceChart(investments),
        ],
      ),
    );
  }

  pw.Page _buildInvestmentDetailPages(List<Investment> investments, Map<String, dynamic> stats) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader('Detalle de Inversiones'),
          pw.SizedBox(height: 20),
          
          pw.Expanded(
            child: _buildInvestmentTable(investments),
          ),
        ],
      ),
    );
  }

  pw.Page _buildDashboardPage(Map<String, dynamic> expenseStats, Map<String, dynamic> investmentStats) {
    final balance = (investmentStats['currentValue'] ?? 0.0) - (expenseStats['total'] ?? 0.0);
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader('Dashboard Financiero'),
          pw.SizedBox(height: 30),

          // Balance principal
          pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [primaryColor, secondaryColor],
              ),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Balance Total',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  _currencyFormat.format(balance),
                  style: pw.TextStyle(
                    fontSize: 48,
                    fontWeight: pw.FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // Resumen rápido
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryCard(
                  'Gastos Totales',
                  _currencyFormat.format(expenseStats['total']),
                  errorColor,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildSummaryCard(
                  'Inversiones',
                  _currencyFormat.format(investmentStats['currentValue']),
                  successColor,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryCard(
                  'ROI Portfolio',
                  '${investmentStats['roi'].toStringAsFixed(2)}%',
                  accentColor,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildSummaryCard(
                  'Gasto Promedio',
                  _currencyFormat.format(expenseStats['averageDaily']),
                  secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Page _buildTableOfContents() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader('Índice'),
          pw.SizedBox(height: 30),
          
          _buildTocItem('1. Dashboard Financiero', 3),
          _buildTocItem('2. Análisis de Gastos', 4),
          _buildTocItem('   2.1 Resumen Ejecutivo', 5),
          _buildTocItem('   2.2 Gráficos', 6),
          _buildTocItem('   2.3 Detalle', 7),
          _buildTocItem('3. Portfolio de Inversiones', 8),
          _buildTocItem('   3.1 Resumen', 9),
          _buildTocItem('   3.2 Análisis', 10),
          _buildTocItem('   3.3 Detalle', 11),
          _buildTocItem('4. Conclusiones', 12),
        ],
      ),
    );
  }

  pw.Page _buildSectionDivider(String title) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [darkBg, cardBg],
            begin: pw.Alignment.topCenter,
            end: pw.Alignment.bottomCenter,
          ),
        ),
        child: pw.Center(
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 48,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  pw.Page _buildConclusionsPage(Map<String, dynamic> expenseStats, Map<String, dynamic> investmentStats) {
    final roi = investmentStats['roi'] ?? 0.0;
    final savingsRate = ((investmentStats['currentValue'] ?? 0.0) / ((expenseStats['total'] ?? 1.0) + (investmentStats['currentValue'] ?? 0.0))) * 100;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader('Conclusiones y Recomendaciones'),
          pw.SizedBox(height: 30),

          _buildConclusionBox(
            '📊 Salud Financiera',
            roi > 10 
                ? 'Excelente desempeño del portfolio con ROI superior al 10%'
                : roi > 0
                    ? 'Desempeño positivo del portfolio, continúa optimizando'
                    : 'Portfolio en pérdidas, considera rebalancear',
            roi > 10 ? successColor : roi > 0 ? accentColor : errorColor,
          ),

          pw.SizedBox(height: 20),

          _buildConclusionBox(
            '💰 Tasa de Ahorro',
            savingsRate > 30
                ? 'Excelente tasa de ahorro (${savingsRate.toStringAsFixed(1)}%)'
                : savingsRate > 15
                    ? 'Buena tasa de ahorro (${savingsRate.toStringAsFixed(1)}%)'
                    : 'Tasa de ahorro baja (${savingsRate.toStringAsFixed(1)}%), considera reducir gastos',
            savingsRate > 30 ? successColor : savingsRate > 15 ? accentColor : errorColor,
          ),

          pw.SizedBox(height: 20),

          _buildConclusionBox(
            '🎯 Recomendaciones',
            '• Mantén un fondo de emergencia\n• Diversifica tus inversiones\n• Revisa gastos recurrentes\n• Establece metas de ahorro',
            secondaryColor,
          ),
        ],
      ),
    );
  }

  // ============ COMPONENTES VISUALES ============

  pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: primaryColor, width: 3),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 28,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  pw.Widget _buildSubHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: secondaryColor,
      ),
    );
  }

  pw.Widget _buildKpiCard({
    required String title,
    required String value,
    required String icon,
    required PdfColor color,
  }) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: cardBg,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            icon,
            style: const pw.TextStyle(fontSize: 32),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: textSecondary,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: cardBg,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTocItem(String title, int page) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            page.toString(),
            style: pw.TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildConclusionBox(String title, String content, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: cardBg,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            content,
            style: pw.TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopCategoriesTable(List<Map<String, dynamic>> categories) {
    return pw.Table(
      border: pw.TableBorder.all(color: cardBg, width: 1),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: cardBg),
          children: [
            _buildTableCell('Categoría', isHeader: true),
            _buildTableCell('Monto', isHeader: true),
            _buildTableCell('% Total', isHeader: true),
          ],
        ),
        // Data
        ...categories.map((cat) => pw.TableRow(
          children: [
            _buildTableCell(cat['name']),
            _buildTableCell(_currencyFormat.format(cat['amount'])),
            _buildTableCell('${cat['percentage'].toStringAsFixed(1)}%'),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildInvestmentTypeTable(Map<String, dynamic> byType) {
    return pw.Table(
      border: pw.TableBorder.all(color: cardBg, width: 1),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: cardBg),
          children: [
            _buildTableCell('Tipo', isHeader: true),
            _buildTableCell('Invertido', isHeader: true),
            _buildTableCell('Actual', isHeader: true),
            _buildTableCell('ROI', isHeader: true),
          ],
        ),
        ...byType.entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;
          final roi = data['roi'] as double;
          return pw.TableRow(
            children: [
              _buildTableCell(entry.key),
              _buildTableCell(_currencyFormat.format(data['invested'])),
              _buildTableCell(_currencyFormat.format(data['current'])),
              _buildTableCell(
                '${roi.toStringAsFixed(2)}%',
                color: roi >= 0 ? successColor : errorColor,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildExpenseTable(List<Expense> expenses) {
    return pw.Table(
      border: pw.TableBorder.all(color: cardBg, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: cardBg),
          children: [
            _buildTableCell('Fecha', isHeader: true),
            _buildTableCell('Categoría', isHeader: true),
            _buildTableCell('Subcategoría', isHeader: true),
            _buildTableCell('Monto', isHeader: true),
          ],
        ),
        ...expenses.take(50).map((expense) => pw.TableRow(
          children: [
            _buildTableCell(_dateFormat.format(expense.date)),
            _buildTableCell(expense.category),
            _buildTableCell(expense.subcategory),
            _buildTableCell(_currencyFormat.format(expense.amount)),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildInvestmentTable(List<Investment> investments) {
    return pw.Table(
      border: pw.TableBorder.all(color: cardBg, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: cardBg),
          children: [
            _buildTableCell('Nombre', isHeader: true),
            _buildTableCell('Tipo', isHeader: true),
            _buildTableCell('Invertido', isHeader: true),
            _buildTableCell('Actual', isHeader: true),
            _buildTableCell('ROI', isHeader: true),
          ],
        ),
        ...investments.map((inv) {
          final roi = inv.profitLossPercentage;
          return pw.TableRow(
            children: [
              _buildTableCell(inv.name),
              _buildTableCell(inv.type),
              _buildTableCell(_currencyFormat.format(inv.amountInvested)),
              _buildTableCell(_currencyFormat.format(inv.currentValue)),
              _buildTableCell(
                '${roi.toStringAsFixed(2)}%',
                color: roi >= 0 ? successColor : errorColor,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? primaryColor : textPrimary),
        ),
      ),
    );
  }

  pw.Widget _buildPieChart(Map<String, double> data) {
    final total = data.values.fold<double>(0, (sum, val) => sum + val);
    final colors = [
      primaryColor,
      secondaryColor,
      accentColor,
      successColor,
      errorColor,
      PdfColor.fromHex('#9B59B6'),
      PdfColor.fromHex('#3498DB'),
      PdfColor.fromHex('#E74C3C'),
    ];

    return pw.Container(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          // Círculo central simulado con Container
          pw.Container(
            width: 200,
            height: 200,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              gradient: pw.LinearGradient(
                colors: [primaryColor, secondaryColor],
              ),
            ),
            child: pw.Center(
              child: pw.Text(
                _currencyFormat.format(total),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          
          // Leyenda
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: data.entries.take(8).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final percentage = (item.value / total * 100).toStringAsFixed(1);
              
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 16,
                      height: 16,
                      decoration: pw.BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.key,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '$percentage% - ${_currencyFormat.format(item.value)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBarChart(Map<String, double> data) {
    final maxValue = data.values.fold<double>(0, (max, val) => val > max ? val : max);
    
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: data.entries.map((entry) {
        final height = (entry.value / maxValue) * 150;
        
        return pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              _currencyFormat.format(entry.value),
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 5),
            pw.Container(
              width: 40,
              height: height,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: pw.Alignment.bottomCenter,
                  end: pw.Alignment.topCenter,
                ),
                borderRadius: const pw.BorderRadius.vertical(
                  top: pw.Radius.circular(4),
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              entry.key,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _buildPerformanceChart(List<Investment> investments) {
    return pw.Column(
      children: investments.take(10).map((inv) {
        final roi = inv.profitLossPercentage;
        final normalizedRoi = (roi + 100) / 200; // Normalizar a 0-1
        final barWidth = normalizedRoi * 400;
        
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 100,
                child: pw.Text(
                  inv.name,
                  style: const pw.TextStyle(fontSize: 9),
                  overflow: pw.TextOverflow.clip,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                width: barWidth,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: roi >= 0 ? successColor : errorColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                '${roi.toStringAsFixed(2)}%',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: roi >= 0 ? successColor : errorColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildMonthlyComparisonChart(Map<String, double> monthlyData) {
    return _buildBarChart(monthlyData);
  }

  // ============ UTILIDADES ============

  Future<String?> _savePdfFile(pw.Document pdf, String baseName) async {
    try {
      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/${baseName}_$timestamp.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      LogService.error('Error guardando PDF', e, null, 'ProfessionalPdfService');
      return null;
    }
  }

  // ============ CÁLCULOS ESTADÍSTICOS (ejecutados en isolate) ============

  static Map<String, dynamic> _calculateExpenseStats(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return {
        'total': 0.0,
        'averageDaily': 0.0,
        'categoriesCount': 0,
        'topCategories': [],
        'categoryDistribution': {},
        'timelineTrend': {},
        'monthlyComparison': {},
      };
    }

    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final daysDiff = expenses.last.date.difference(expenses.first.date).inDays + 1;
    final averageDaily = total / daysDiff;

    // Agrupar por categoría
    final Map<String, double> categoryTotals = {};
    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    // Top categorías
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategoriesList = topCategories.take(5).map((entry) => {
      'name': entry.key,
      'amount': entry.value,
      'percentage': (entry.value / total) * 100,
    }).toList();

    // Tendencia temporal
    final Map<String, double> timelineTrend = {};
    for (final expense in expenses) {
      final month = DateFormat('MMM yyyy').format(expense.date);
      timelineTrend[month] = (timelineTrend[month] ?? 0) + expense.amount;
    }

    return {
      'total': total,
      'averageDaily': averageDaily,
      'categoriesCount': categoryTotals.length,
      'topCategories': topCategoriesList,
      'categoryDistribution': categoryTotals,
      'timelineTrend': timelineTrend,
      'monthlyComparison': timelineTrend,
    };
  }

  static Map<String, dynamic> _calculateInvestmentStats(List<Investment> investments) {
    if (investments.isEmpty) {
      return {
        'totalInvested': 0.0,
        'currentValue': 0.0,
        'profitLoss': 0.0,
        'roi': 0.0,
        'byType': {},
        'typeDistribution': {},
      };
    }

    final totalInvested = investments.fold<double>(0, (sum, i) => sum + i.amountInvested);
    final currentValue = investments.fold<double>(0, (sum, i) => sum + i.currentValue);
    final profitLoss = currentValue - totalInvested;
    final roi = totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0.0;

    // Agrupar por tipo
    final Map<String, Map<String, double>> byType = {};
    final Map<String, double> typeDistribution = {};
    
    for (final inv in investments) {
      if (!byType.containsKey(inv.type)) {
        byType[inv.type] = {'invested': 0.0, 'current': 0.0, 'roi': 0.0};
      }
      byType[inv.type]!['invested'] = (byType[inv.type]!['invested'] ?? 0) + inv.amountInvested;
      byType[inv.type]!['current'] = (byType[inv.type]!['current'] ?? 0) + inv.currentValue;
      
      typeDistribution[inv.type] = (typeDistribution[inv.type] ?? 0) + inv.currentValue;
    }

    // Calcular ROI por tipo
    byType.forEach((type, data) {
      final invested = data['invested'] ?? 0;
      final current = data['current'] ?? 0;
      data['roi'] = invested > 0 ? ((current - invested) / invested) * 100 : 0;
    });

    return {
      'totalInvested': totalInvested,
      'currentValue': currentValue,
      'profitLoss': profitLoss,
      'roi': roi,
      'byType': byType,
      'typeDistribution': typeDistribution,
    };
  }
}
