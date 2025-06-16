import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view-model-flutter/cabang_controller.dart';
import 'package:ta_pos/view-model-flutter/transaksi_controller.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  List<dynamic> allCabang = [];
  String? selectedCabang;
  String selectedRange = '6 Bulan';
  List<int> monthlySales = [];
  List<double> monthlyRevenue = [];
  int totalTransAllCabang = 0;
  List<int> monthlyBarangMasuk = [];
  List<double> monthlyPengeluaran = [];
  List<double> monthlyKeuntungan = [];

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    allCabang = await getallcabang();
    setState(() {});
    await calculateTotalTransAllCabang();
  }

  Future<void> calculateTotalTransAllCabang() async {
    final now = DateTime.now();
    final start =
        DateTime(now.year, now.month, 1).subtract(const Duration(days: 30 * 5));
    int total = 0;

    for (final cabang in allCabang) {
      final trans = await getTransByCabang(cabang["_id"], start, now);
      total += trans.length;
    }

    setState(() {
      totalTransAllCabang = total;
    });
  }

  Future<void> fetchDetailCabangData() async {
    if (selectedCabang == null) return;
    monthlyBarangMasuk.clear();
    monthlyPengeluaran.clear();
    monthlyKeuntungan.clear();
    int months;
    switch (selectedRange) {
      case '1 Bulan':
        months = 1;
        break;
      case '3 Bulan':
        months = 3;
        break;
      default:
        months = 6;
    }

    final now = DateTime.now();
    final List<int> sales = [];
    final List<double> revenue = [];

    for (int i = 0; i < months; i++) {
      final date = DateTime(now.year, now.month - (months - 1 - i));
      final start = DateTime(date.year, date.month, 1);
      final end = i == months - 1
          ? now
          : DateTime(start.year, start.month + 1, 1)
              .subtract(const Duration(days: 1));

      final trans = await getTransByCabang(selectedCabang!, start, end);
      final totalRevenue =
          trans.fold<double>(0.0, (sum, t) => sum + (t["grand_total"] ?? 0));
      sales.add(trans.length);
      revenue.add(totalRevenue);
      final result = await getCabangStatistikRingkasan(
        selectedCabang!,
        start.toIso8601String(),
        end.toIso8601String(),
      );

      monthlyBarangMasuk.add(result['total_barang_masuk'] ?? 0);
      monthlyPengeluaran.add(result['total_pengeluaran']?.toDouble() ?? 0);
      monthlyKeuntungan.add(result['keuntungan']?.toDouble() ?? 0);
    }

    setState(() {
      monthlySales = sales;
      monthlyRevenue = revenue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLabels = _generateMonthLabels();

    return Scaffold(
      appBar: AppBar(title: const Text("Owner Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.grey.shade600,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Total Transaksi Seluruh Cabang (6 Bulan): $totalTransAllCabang",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      labelText: "Pilih Cabang",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: selectedCabang,
                    items: allCabang
                        .map<DropdownMenuItem<String>>(
                          (c) => DropdownMenuItem(
                            value: c["_id"],
                            child: Text(c["nama_cabang"]),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCabang = value;
                      });
                      fetchDetailCabangData();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      labelText: "Range Waktu",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: selectedRange,
                    items: ["1 Bulan", "3 Bulan", "6 Bulan"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedRange = val!;
                      });
                      fetchDetailCabangData();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedCabang != null)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "Grafik Jumlah Transaksi ($selectedRange)",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 180, // Grafik Transaksi lebih kecil
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: 1,
                                  getTitlesWidget: (value, _) {
                                    final index = value.toInt();
                                    return index < monthLabels.length
                                        ? Text(monthLabels[index],
                                            style:
                                                const TextStyle(fontSize: 10))
                                        : const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true, reservedSize: 42),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  monthlySales.length,
                                  (i) => FlSpot(
                                      i.toDouble(), monthlySales[i].toDouble()),
                                ),
                                isCurved: false,
                                color: Colors.green,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Grafik Kinerja Keuangan ($selectedRange)",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0), // padding kiri-kanan
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Statistik Keuangan Cabang",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),

                          SizedBox(height: 12),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Grafik Kinerja Keuangan ($selectedRange)",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 280, // Grafik Keuangan lebih besar
                                  child: LineChart(
                                    LineChartData(
                                      minY: 0,
                                      titlesData: FlTitlesData(
                                        topTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1,
                                            getTitlesWidget: (value, _) {
                                              final index = value.toInt();
                                              return index < monthLabels.length
                                                  ? Text(monthLabels[index],
                                                      style: TextStyle(
                                                          fontSize: 10))
                                                  : Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 42),
                                        ),
                                      ),
                                      gridData: FlGridData(show: true),
                                      borderData: FlBorderData(show: true),
                                      lineBarsData: [
                                        // Pendapatan
                                        LineChartBarData(
                                          spots: List.generate(
                                            monthlyRevenue.length,
                                            (i) => FlSpot(i.toDouble(),
                                                monthlyRevenue[i]),
                                          ),
                                          isCurved: false,
                                          color: Colors.blue,
                                          barWidth: 2.5,
                                          dotData: FlDotData(show: true),
                                        ),
                                        // Pengeluaran
                                        LineChartBarData(
                                          spots: List.generate(
                                            monthlyPengeluaran.length,
                                            (i) => FlSpot(i.toDouble(),
                                                monthlyPengeluaran[i]),
                                          ),
                                          isCurved: false,
                                          color: Colors.red,
                                          barWidth: 2.5,
                                          dotData: FlDotData(show: true),
                                        ),
                                        // Keuntungan
                                        LineChartBarData(
                                          spots: List.generate(
                                            monthlyKeuntungan.length,
                                            (i) => FlSpot(i.toDouble(),
                                                monthlyKeuntungan[i]),
                                          ),
                                          isCurved: false,
                                          color: Colors.green,
                                          barWidth: 2.5,
                                          dotData: FlDotData(show: true),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 12),

                          // Legend warna chart
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(Colors.red, "Pengeluaran"),
                              _buildLegendItem(Colors.blue, "Pendapatan"),
                              _buildLegendItem(Colors.green, "Keuntungan"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 16),
                    Text(
                      "Ringkasan Total Selama $selectedRange",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Total Barang Masuk: ${monthlyBarangMasuk.fold(0, (a, b) => a + b)}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total Pengeluaran: ${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(
                        monthlyPengeluaran.fold(0.0, (a, b) => a + b),
                      )}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total Pendapatan: ${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(
                        monthlyRevenue.fold(0.0, (a, b) => a + b),
                      )}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total Keuntungan: ${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(
                        monthlyKeuntungan.fold(0.0, (a, b) => a + b),
                      )}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  List<String> _generateMonthLabels() {
    int months;
    switch (selectedRange) {
      case '1 Bulan':
        months = 1;
        break;
      case '3 Bulan':
        months = 3;
        break;
      default:
        months = 6;
    }

    final now = DateTime.now();
    return List.generate(months, (i) {
      final date = DateTime(now.year, now.month - (months - 1 - i));
      return DateFormat('MMM').format(date);
    });
  }
}
