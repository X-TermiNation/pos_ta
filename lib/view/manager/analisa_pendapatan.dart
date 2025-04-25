import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view-model-flutter/transaksi_controller.dart';

class AnalisaPendapatanView extends StatefulWidget {
  @override
  _AnalisaPendapatanViewState createState() => _AnalisaPendapatanViewState();
}

class _AnalisaPendapatanViewState extends State<AnalisaPendapatanView> {
  DateTime? _startDate;
  DateTime? _endDate = DateTime.now();
  List<FlSpot> _chartData = [];

  Future<void> _selectDateRange() async {
    final DateTime now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _fetchAndProcessData(); // Memanggil fungsi untuk mengolah data
      });
    }
  }

  List<FlSpot> _generatePendapatanPerHari(List<dynamic> transaksiList) {
    // Map untuk menyimpan total pendapatan per hari
    Map<String, double> dailyPendapatan = {};

    for (var trans in transaksiList) {
      DateTime transDate = DateTime.parse(trans['trans_date']);
      String dateKey = DateFormat('yyyy-MM-dd').format(transDate);

      if (!dailyPendapatan.containsKey(dateKey)) {
        dailyPendapatan[dateKey] = 0;
      }
      dailyPendapatan[dateKey] =
          dailyPendapatan[dateKey]! + trans['grand_total'];
    }

    // Mengurutkan berdasarkan tanggal
    List<String> sortedDates = dailyPendapatan.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // Menyusun data untuk grafik
    return sortedDates.map((date) {
      return FlSpot(
        sortedDates.indexOf(date).toDouble(),
        dailyPendapatan[date]!,
      );
    }).toList();
  }

  // Fungsi untuk mengambil dan mengolah data
  Future<void> _fetchAndProcessData() async {
    List<dynamic> transaksiList =
        await getConfirmedTransInRange(_startDate!, _endDate!);
    setState(() {
      _chartData = _generatePendapatanPerHari(transaksiList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _selectDateRange,
              child: Text('Pilih Rentang Tanggal'),
            ),
            if (_startDate != null && _endDate != null)
              Text(
                'Dari ${DateFormat('dd MMM yyyy').format(_startDate!)} '
                'hingga ${DateFormat('dd MMM yyyy').format(_endDate!)}',
              ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: LineChart(LineChartData(
                      minY: 0,
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 100000, // Setiap Rp100.000
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                NumberFormat.currency(
                                        locale: 'id',
                                        symbol: 'Rp',
                                        decimalDigits: 0)
                                    .format(value),
                                style: TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval:
                                2, // Tampilkan tanggal tiap 2 hari (bisa disesuaikan)
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < _chartData.length) {
                                final date =
                                    _startDate!.add(Duration(days: index));
                                return Text(
                                  DateFormat('dd/MM').format(date),
                                  style: TextStyle(fontSize: 10),
                                );
                              } else {
                                return Text('');
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _chartData,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.blueAccent,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    )),
                  );
                },
              ),
            ),
          ],
        ));
  }
}
