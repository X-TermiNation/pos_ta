import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import 'package:ta_pos/view-model-flutter/laporan_controller.dart';

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

  Widget _buildLineChart() {
    final spots = _generateLineChartData();
    final perJam = controller.analisa['penjualan_per_jam'] ?? [];

    if (spots.isEmpty) return const Text("Data tidak tersedia");

    return SizedBox(
      height: 500,
      child: Padding(
        padding: const EdgeInsets.only(right: 20), // padding kanan 20
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
              topTitles: AxisTitles(
                // tambahkan ini
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                // optional, biasanya default false atau true
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final barangList = controller.analisa['penjualan_per_barang'] ?? [];
    final f =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return DataTable(
      columns: const [
        DataColumn(label: Text('Nama Barang')),
        DataColumn(label: Text('Qty Terjual')),
        DataColumn(label: Text('Total Penjualan')),
        DataColumn(label: Text('Total Modal')),
        DataColumn(label: Text('Profit')),
      ],
      rows: barangList.map<DataRow>((item) {
        return DataRow(cells: [
          DataCell(Text(item['nama_barang'] ?? '')),
          DataCell(Text(item['total_qty'].toString())),
          DataCell(Text(f.format(item['total_penjualan'] ?? 0))),
          DataCell(Text(f.format(item['total_modal'] ?? 0))),
          DataCell(Text(f.format(item['total_profit'] ?? 0))),
        ]);
      }).toList(),
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
                              final pdfData = await _generatePdf();
                              await Printing.layoutPdf(
                                  onLayout: (_) => pdfData);
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
              } else if ((controller.analisa['penjualan_per_jam'] == null ||
                      controller.analisa['penjualan_per_jam'].isEmpty) &&
                  (controller.analisa['penjualan_per_barang'] == null ||
                      controller.analisa['penjualan_per_barang'].isEmpty)) {
                return const Expanded(
                    child: Center(child: Text('Data tidak tersedia')));
              } else {
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
                          child: _buildDataTable(),
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
