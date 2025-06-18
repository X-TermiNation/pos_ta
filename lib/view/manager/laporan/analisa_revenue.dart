import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ta_pos/view-model-flutter/laporan_controller.dart';
import 'dart:math';

class AnalisaRevenuePage extends StatefulWidget {
  const AnalisaRevenuePage({Key? key}) : super(key: key);

  @override
  _AnalisaRevenuePageState createState() => _AnalisaRevenuePageState();
}

class _AnalisaRevenuePageState extends State<AnalisaRevenuePage> {
  final controller = Get.put(AnalisaRevenueController());

  DateTime? startDate;
  DateTime? endDate;

  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    endDate = DateTime.now();
    startDate = endDate!.subtract(const Duration(days: 6));
    controller.fetchAnalisaRevenueData(startDate!, endDate!);
  }

  List<FlSpot> _generateLineChartData() {
    final perJam = controller.analisa['penjualan_per_jam'] ?? [];
    List<FlSpot> spots = [];
    for (int i = 0; i < perJam.length; i++) {
      double total = (perJam[i]['total_penjualan'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), total));
    }
    return spots;
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final f =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final perJam = controller.analisa['penjualan_per_jam'] ?? [];
    final perBarang = controller.analisa['penjualan_per_barang'] ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Laporan Analisa Revenue',
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text(
              'Periode: ${dateFormat.format(startDate!)} - ${dateFormat.format(endDate!)}'),
          pw.SizedBox(height: 20),
          pw.Text('Penjualan Per Jam',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 0.5),
            headers: ['Jam', 'Total Penjualan'],
            data: List<List<dynamic>>.from(perJam.map((item) {
              String jam = item['jam'].toString().padLeft(2, '0') + ":00";
              String total = f.format(item['total_penjualan'] ?? 0);
              return [jam, total];
            })),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Penjualan Per Barang',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 0.5),
            headers: [
              'Nama Barang',
              'Qty Terjual',
              'Total Penjualan',
              'Total Modal',
              'Profit'
            ],
            data: List<List<dynamic>>.from(perBarang.map((item) {
              return [
                item['nama_barang'] ?? '',
                item['total_qty'].toString(),
                f.format(item['total_penjualan'] ?? 0),
                f.format(item['total_modal'] ?? 0),
                f.format(item['total_profit'] ?? 0),
              ];
            })),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  List<Map<String, dynamic>> _topBarangByQty(List<Map<String, dynamic>> list) {
    List<Map<String, dynamic>> sorted = List.from(list);
    sorted.sort((a, b) => (b['total_qty'] ?? 0).compareTo(a['total_qty'] ?? 0));
    return sorted.take(3).toList();
  }

  List<Map<String, dynamic>> _topBarangByProfit(
      List<Map<String, dynamic>> list) {
    List<Map<String, dynamic>> sorted = List.from(list);
    sorted.sort(
        (a, b) => (b['total_profit'] ?? 0).compareTo(a['total_profit'] ?? 0));
    return sorted.take(3).toList();
  }

  List<Map<String, dynamic>> _worstMargin(List<Map<String, dynamic>> list) {
    List<Map<String, dynamic>> sorted = List.from(list);
    sorted.sort((a, b) {
      double marginA = ((a['total_profit'] ?? 0) * 1.0) /
          max<double>(1.0, ((a['total_penjualan'] ?? 1) as num).toDouble());
      double marginB = ((b['total_profit'] ?? 0) * 1.0) /
          max<double>(1.0, ((b['total_penjualan'] ?? 1) as num).toDouble());
      return marginA.compareTo(marginB);
    });
    return sorted.take(3).toList();
  }

  Widget _buildLineChart() {
    final spots = _generateLineChartData();
    final perJam = controller.analisa['penjualan_per_jam'] ?? [];

    if (spots.isEmpty) return const Text("Data tidak tersedia");

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: LineChart(
          LineChartData(
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                color: Colors.blue,
                dotData: FlDotData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    int index = value.toInt();
                    if (index >= 0 && index < perJam.length) {
                      return Text(
                        perJam[index]['jam'].toString().padLeft(2, '0') + ":00",
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> data, List<String> columns,
      List<DataCell> Function(Map<String, dynamic>) buildRow) {
    return DataTable(
      columns: columns.map((e) => DataColumn(label: Text(e))).toList(),
      rows: data.map((item) => DataRow(cells: buildRow(item))).toList(),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate!, end: endDate!),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      controller.fetchAnalisaRevenueData(startDate!, endDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelRange = startDate != null && endDate != null
        ? '${dateFormat.format(startDate!)} - ${dateFormat.format(endDate!)}'
        : 'Pilih rentang tanggal';

    return Scaffold(
      appBar: AppBar(title: const Text("Analisa Revenue")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(labelRange),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() => ElevatedButton.icon(
                      onPressed: controller.analisa.isEmpty
                          ? null
                          : () async {
                              try {
                                final pdfData = await _generatePdf();
                                final now = DateTime.now();
                                final filename =
                                    'Laporan_AnalisaRevenue_${DateFormat('dd-MM-yyyy_HHmmss').format(now)}.pdf';

                                final downloadsDir =
                                    await getDownloadsDirectory();
                                if (downloadsDir == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Folder Downloads tidak ditemukan")),
                                  );
                                  return;
                                }

                                final filePath =
                                    '${downloadsDir.path}/$filename';
                                final file = File(filePath);
                                await file.writeAsBytes(pdfData);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "PDF berhasil disimpan ke:\n$filePath")),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Gagal menyimpan PDF: $e")),
                                );
                              }
                            },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Generate PDF"),
                    )),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.loading.value) {
                return const Expanded(
                    child: Center(child: CircularProgressIndicator()));
              } else if (controller.errorMessage.isNotEmpty) {
                return Expanded(
                    child: Center(child: Text(controller.errorMessage.value)));
              } else {
                final barangList =
                    (controller.analisa['penjualan_per_barang'] ?? [])
                        .cast<Map<String, dynamic>>();
                final f = NumberFormat.currency(
                    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                final topByQty = _topBarangByQty(barangList);
                final topByProfit = _topBarangByProfit(barangList);
                final worstMarginList = _worstMargin(barangList);

                return Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Pendapatan Per Jam",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _buildLineChart(),
                        const SizedBox(height: 20),
                        const Text("Penjualan Per Barang",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildDataTable(
                            barangList,
                            [
                              'Nama Barang',
                              'Qty',
                              'Penjualan',
                              'Modal',
                              'Profit'
                            ],
                            (item) => [
                              DataCell(Text(item['nama_barang'] ?? '')),
                              DataCell(Text(item['total_qty'].toString())),
                              DataCell(
                                  Text(f.format(item['total_penjualan'] ?? 0))),
                              DataCell(
                                  Text(f.format(item['total_modal'] ?? 0))),
                              DataCell(
                                  Text(f.format(item['total_profit'] ?? 0))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text("Top 3 Barang Terlaris",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        _buildDataTable(
                          topByQty,
                          ['Nama Barang', 'Qty Terjual'],
                          (item) => [
                            DataCell(Text(item['nama_barang'] ?? '')),
                            DataCell(Text(item['total_qty'].toString())),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text("Top 3 Barang dengan Profit Tertinggi",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        _buildDataTable(
                          topByProfit,
                          ['Nama Barang', 'Profit'],
                          (item) => [
                            DataCell(Text(item['nama_barang'] ?? '')),
                            DataCell(Text(f.format(item['total_profit'] ?? 0))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text("Top 3 Margin Penjualan Terburuk",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        _buildDataTable(
                          worstMarginList,
                          ['Nama Barang', 'Penjualan', 'Profit', 'Margin %'],
                          (item) {
                            final penjualan = item['total_penjualan'] ?? 1;
                            final profit = item['total_profit'] ?? 0;
                            final margin = ((profit * 100.0) / penjualan)
                                .toStringAsFixed(2);
                            return [
                              DataCell(Text(item['nama_barang'] ?? '')),
                              DataCell(Text(f.format(penjualan))),
                              DataCell(Text(f.format(profit))),
                              DataCell(Text('$margin %')),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
