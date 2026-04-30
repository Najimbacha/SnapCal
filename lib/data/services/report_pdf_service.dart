import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/meal.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';

class ReportPdfService {
  static Future<void> generateAndShareReport({
    required String userName,
    required List<Meal> meals,
    required SettingsProvider settings,
    required int streak,
  }) async {
    final pdf = pw.Document();

    // Load logo with fallback
    pw.MemoryImage? logoImage;
    try {
      logoImage = pw.MemoryImage(
        (await rootBundle.load('assets/icon/icon.png')).buffer.asUint8List(),
      );
    } catch (e) {
      debugPrint('PDF Logo Error: $e');
    }

    final now = DateTime.now();
    final weeklyMeals = meals; // Already filtered by provider

    // Calculate totals
    int totalCals = 0;
    int totalP = 0;
    int totalC = 0;
    int totalF = 0;
    for (var m in weeklyMeals) {
      totalCals += m.calories;
      totalP += m.macros.protein;
      totalC += m.macros.carbs;
      totalF += m.macros.fat;
    }
    
    final avgCals = weeklyMeals.isEmpty ? 0 : (totalCals / 7).round();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ── Header ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    if (logoImage != null) 
                      pw.Container(
                        width: 40, height: 40,
                        child: pw.Image(logoImage),
                      ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SnapCal',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal,
                          ),
                        ),
                        pw.Text(
                          'AI NUTRITION REPORT',
                          style: pw.TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      DateFormat('MMMM dd, yyyy').format(now),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'User: $userName',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            // ── Executive Summary ──
            pw.Text(
              'WEEKLY PERFORMANCE',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            pw.Divider(thickness: 2, color: PdfColors.teal),
            pw.SizedBox(height: 20),

            pw.Row(
              children: [
                _buildSummaryStat('Avg. Calories', '$avgCals', 'kcal/day', PdfColors.teal),
                pw.SizedBox(width: 20),
                _buildSummaryStat('Total Protein', '$totalP', 'grams', PdfColors.blue),
                pw.SizedBox(width: 20),
                _buildSummaryStat('Active Streak', '$streak', 'days', PdfColors.orange),
              ],
            ),

            pw.SizedBox(height: 40),

            // ── Macro Balance Table ──
            pw.Text(
              'MACRONUTRIENT DISTRIBUTION',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _tableHeader('Nutrient'),
                    _tableHeader('Total Consumed'),
                    _tableHeader('Daily Target'),
                    _tableHeader('Goal Status'),
                  ],
                ),
                _tableRow('Protein', '${totalP}g', '${settings.dailyProteinGoal}g', _getGoalStatus(totalP / 7, settings.dailyProteinGoal)),
                _tableRow('Carbohydrates', '${totalC}g', '${settings.dailyCarbGoal}g', _getGoalStatus(totalC / 7, settings.dailyCarbGoal)),
                _tableRow('Fats', '${totalF}g', '${settings.dailyFatGoal}g', _getGoalStatus(totalF / 7, settings.dailyFatGoal)),
              ],
            ),

            pw.SizedBox(height: 40),

            // ── Recent Activity Log ──
            pw.Text(
              'DETAILED MEAL LOG (Last 7 Days)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 1))),
                  children: [
                    _tableHeader('Date'),
                    _tableHeader('Meal Item'),
                    _tableHeader('Type'),
                    _tableHeader('Calories'),
                  ],
                ),
                ...weeklyMeals.reversed.map((m) {
                  final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp);
                  return pw.TableRow(
                    children: [
                      _tableCell(DateFormat('MMM dd').format(date)),
                      _tableCell(m.foodName),
                      _tableCell(m.mealType ?? 'Snack'),
                      _tableCell('${m.calories} kcal', align: pw.Alignment.centerRight),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 60),

            // ── Footer ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'This report was automatically generated by SnapCal AI.',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Stay consistent, stay healthy.',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Preview/Print/Share
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'SnapCal_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildSummaryStat(String label, String value, String unit, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color.shade(0.02),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: color.shade(0.2), width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
                pw.SizedBox(width: 4),
                pw.Text(unit, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.TableRow _tableRow(String label, String value, String target, String status) {
    return pw.TableRow(
      children: [
        _tableCell(label),
        _tableCell(value),
        _tableCell(target),
        _tableCell(status, color: status == 'ON TRACK' ? PdfColors.green : PdfColors.orange),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {pw.Alignment align = pw.Alignment.centerLeft, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 9, color: color ?? PdfColors.black),
        ),
      ),
    );
  }

  static String _getGoalStatus(double dailyAvg, int target) {
    if (dailyAvg == 0) return 'NO DATA';
    final diff = (dailyAvg - target).abs();
    if (diff < (target * 0.15)) return 'ON TRACK';
    return dailyAvg > target ? 'ABOVE TARGET' : 'BELOW TARGET';
  }
}
