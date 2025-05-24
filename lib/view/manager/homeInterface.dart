import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class CabangDashboardChartPage extends StatefulWidget {
  const CabangDashboardChartPage({Key? key}) : super(key: key);

  @override
  State<CabangDashboardChartPage> createState() =>
      _CabangDashboardChartPageState();
}

class _CabangDashboardChartPageState extends State<CabangDashboardChartPage> {
  Map<int, double> salesPerHour = {};
  Map<String, int> quantityPerItem = {};
  Map<String, double> itemPercentage = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAndProcessData();
  }

  Future<void> fetchAndProcessData() async {
    final dataStorage = GetStorage();
    String id_cabang = dataStorage.read('id_cabang');
    final request =
        Uri.parse('http://localhost:3000/transaksi/translist/$id_cabang');
    final response = await http.get(request);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)["data"];
      final now = DateTime.now();
      Map<int, double> hourlySales = {
        for (var i = 0; i < 24; i++) i: 0.0
      }; // default 0
      Map<String, int> itemQty = {};
      Map<String, int> itemCount = {};

      for (var trx in data) {
        DateTime date = DateTime.parse(trx['trans_date'])
            .toUtc()
            .add(const Duration(hours: 7));
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          int hour = date.hour;
          int total = trx['grand_total'];
          hourlySales[hour] = (hourlySales[hour] ?? 0) + total;

          for (var item in trx['Items']) {
            String key = '${item['nama_barang']}';
            itemQty[key] =
                (itemQty[key] ?? 0) + (item['trans_qty'] as num).toInt();
            itemCount[key] = (itemCount[key] ?? 0) + 1;
          }
        }
      }

      int totalQty = itemQty.values.fold(0, (a, b) => a + b);
      Map<String, double> itemPercent = {
        for (var key in itemQty.keys) key: (itemQty[key]! / totalQty) * 100
      };

      setState(() {
        salesPerHour = hourlySales;
        quantityPerItem = itemQty;
        itemPercentage = itemPercent;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Cabang"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi Data',
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              fetchAndProcessData();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(child: Card(child: buildLineChart())),
                        const SizedBox(width: 16),
                        Expanded(child: Card(child: buildBarChart())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 1,
                    child: Card(child: buildPieChart()),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildLineChart() {
    final now = DateTime.now();
    final currentHour = now.hour; // misal sekarang jam 15 (3 PM)

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: currentHour.toDouble(), // hanya sampai jam sekarang
          minY: 0,
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int hour = value.toInt();
                  if (hour < 0 || hour > 23) return const SizedBox();
                  final label = _formatHourLabel(hour);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: salesPerHour.entries
                  .where((e) => e.key <= currentHour)
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: false,
              barWidth: 2,
              color: Colors.blue,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHourLabel(int hour) {
    final isAM = hour < 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return "$displayHour ${isAM ? 'AM' : 'PM'}";
  }

  Widget buildBarChart() {
    if (quantityPerItem.isEmpty) {
      return const Center(child: Text('Tidak ada data barang'));
    }

    // Get max quantity for interval calculation
    int maxQty = quantityPerItem.values.reduce((a, b) => a > b ? a : b);
    double interval = (maxQty / 5).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          maxY: maxQty.toDouble() + interval,
          minY: 0,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                reservedSize: 40,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final key = quantityPerItem.keys.toList()[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      key,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
                reservedSize: 60,
              ),
            ),
          ),
          barGroups: List.generate(
            quantityPerItem.length,
            (i) {
              final key = quantityPerItem.keys.toList()[i];
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                      toY: quantityPerItem[key]!.toDouble(),
                      color: Colors.green),
                ],
              );
            },
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget buildPieChart() {
    if (itemPercentage.isEmpty) {
      return const Center(child: Text('Tidak ada data penjualan'));
    }

    final sortedEntries = itemPercentage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCount = sortedEntries.length > 4 ? 4 : sortedEntries.length;
    final topItems = sortedEntries.take(topCount).toList();

    final lainnyaPercent =
        sortedEntries.skip(topCount).fold<double>(0, (sum, e) => sum + e.value);

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.grey
    ];

    final sections = <PieChartSectionData>[];

    for (int i = 0; i < topItems.length; i++) {
      final entry = topItems[i];
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title:
              "${entry.key.split(' ')[0]}\n${entry.value.toStringAsFixed(1)}%",
          color: colors[i % colors.length],
          radius: 60,
          titleStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          titlePositionPercentageOffset: 0.6,
        ),
      );
    }

    if (lainnyaPercent > 0) {
      sections.add(
        PieChartSectionData(
          value: lainnyaPercent,
          title: "Lainnya\n${lainnyaPercent.toStringAsFixed(1)}%",
          color: colors.last,
          radius: 60,
          titleStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          titlePositionPercentageOffset: 0.6,
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 1, // square container, equal height and width
        child: PieChart(
          PieChartData(
            sections: sections,
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            borderData: FlBorderData(show: false),
            pieTouchData: PieTouchData(enabled: true),
          ),
        ),
      ),
    );
  }
}
