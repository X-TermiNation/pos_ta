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
  bool showAllTime = false;
  DateTimeRange? selectedRange;

  @override
  void initState() {
    super.initState();
    fetchAllTime(); // default all time
  }

  Future<void> fetchAllTime() async {
    setState(() {
      loading = true;
      showAllTime = true;
    });
    final data = await fetchTrendingItems(
      start: DateTime(2000),
      end: DateTime.now(),
    );
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
    final chart = showAllTime ? buildBarChart() : buildLineChart();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
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
    if (trendingData.isEmpty) {
      return const Center(
          child: Text("Tidak ada data untuk tanggal tersebut."));
    }

    final dates = <String>{};
    trendingData.values.forEach((map) => dates.addAll(map.keys));
    final sortedDates = dates.toList()..sort();

    final dateLabels = List.generate(sortedDates.length, (i) => sortedDates[i]);

    return LineChart(LineChartData(
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          axisNameWidget: const Text("Tanggal"),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx >= 0 && idx < dateLabels.length) {
                return Text(
                    DateFormat.Md().format(DateTime.parse(dateLabels[idx])));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text("Qty"),
          sideTitles: SideTitles(showTitles: true, interval: 10),
        ),
      ),
      lineBarsData: trendingData.entries.map((entry) {
        final color =
            Colors.primaries[entry.key.hashCode % Colors.primaries.length];
        return LineChartBarData(
          spots: sortedDates.asMap().entries.map((e) {
            final idx = e.key;
            final date = e.value;
            final qty = entry.value[date] ?? 0;
            return FlSpot(idx.toDouble(), qty.toDouble());
          }).toList(),
          isCurved: true,
          dotData: FlDotData(show: false),
          color: color,
          barWidth: 2,
        );
      }).toList(),
    ));
  }

  Widget buildBarChart() {
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
          sideTitles: SideTitles(showTitles: true, interval: 10),
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
            BarChartRodData(toY: e.value.value.toDouble(), color: Colors.blue),
          ],
        );
      }).toList(),
    ));
  }
}
