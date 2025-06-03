import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view-model-flutter/transaksi_controller.dart';

class GrafikTrendWidget extends StatefulWidget {
  const GrafikTrendWidget({super.key});

  @override
  State<GrafikTrendWidget> createState() => _GrafikTrendWidgetState();
}

class _GrafikTrendWidgetState extends State<GrafikTrendWidget> {
  Map<String, Map<String, int>> trendingData = {};
  bool loading = false;
  bool showAllTime = true;
  DateTimeRange? selectedRange;
  String? selectedBarang;

  @override
  void initState() {
    super.initState();
    fetchAllTime();
  }

  Future<void> fetchAllTime() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      showAllTime = true;
      selectedBarang = null;
    });

    final data = await fetchTrendingItems(
      start: DateTime(2000),
      end: DateTime.now(),
    );
    if (!mounted) return;
    setState(() {
      trendingData = data;
      loading = false;
    });
  }

  Future<void> fetchByDateRange(DateTimeRange range) async {
    setState(() {
      loading = true;
      showAllTime = false;
    });

    final data = await fetchTrendingItems(
      start: range.start,
      end: range.end,
    );
    setState(() {
      trendingData = data;
      selectedRange = range;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chart = (selectedBarang == null) ? buildBarChart() : buildLineChart();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2022),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    await fetchByDateRange(picked);
                  }
                },
                child: const Text('Tampilkan Berdasarkan Tanggal'),
              ),
              ElevatedButton(
                onPressed: fetchAllTime,
                child: const Text('Tampilkan All Time'),
              ),
              DropdownButton<String>(
                hint: const Text("Pilih Barang (Opsional)"),
                value: selectedBarang,
                isDense: true,
                onChanged: (value) {
                  setState(() {
                    selectedBarang = value;
                  });
                },
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tampilkan Semua Barang'),
                  ),
                  ...trendingData.keys.map((key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          loading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: chart,
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget buildLineChart() {
    if (selectedBarang == null || trendingData[selectedBarang] == null) {
      return const Center(
          child: Text("Silakan pilih barang untuk melihat tren."));
    }

    final data = trendingData[selectedBarang!]!;
    final sortedDates = data.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((e) {
      final idx = e.key;
      final date = e.value;
      return FlSpot(idx.toDouble(), data[date]!.toDouble());
    }).toList();

    return LineChart(LineChartData(
      minY: 0,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          axisNameWidget: const Text("Tanggal"),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx >= 0 && idx < sortedDates.length) {
                return Text(
                    DateFormat.Md().format(DateTime.parse(sortedDates[idx])));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text("Qty"),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 10,
            getTitlesWidget: (value, _) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          dotData: FlDotData(show: true),
        ),
      ],
    ));
  }

  Widget buildBarChart() {
    if (trendingData.isEmpty) {
      return const Center(child: Text("Tidak ada data tersedia."));
    }

    final totalPerBarang = trendingData.map((key, map) {
      final total = map.values.fold(0, (sum, qty) => sum + qty);
      return MapEntry(key, total);
    });

    final sorted = totalPerBarang.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BarChart(BarChartData(
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: const Text("Qty"),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 10,
            getTitlesWidget: (value, _) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: const Text("Barang"),
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx >= 0 && idx < sorted.length) {
                return Text(sorted[idx].key,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      barGroups: sorted.asMap().entries.map((e) {
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.value.toDouble(),
              color: Colors.blue,
              width: 20,
              borderRadius: BorderRadius.circular(4),
              rodStackItems: [],
            ),
          ],
          showingTooltipIndicators: [0],
        );
      }).toList(),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final barang = sorted[group.x.toInt()].key;
            final jumlah = rod.toY.toInt();
            return BarTooltipItem(
              '$barang\n$jumlah pcs',
              const TextStyle(color: Colors.white),
            );
          },
        ),
      ),
    ));
  }
}
