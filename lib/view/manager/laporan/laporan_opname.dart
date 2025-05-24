import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ta_pos/view-model-flutter/laporan_controller.dart';

class LaporanOpnamePage extends StatefulWidget {
  const LaporanOpnamePage({super.key});

  @override
  State<LaporanOpnamePage> createState() => _LaporanOpnamePageState();
}

class _LaporanOpnamePageState extends State<LaporanOpnamePage> {
  final OpnameController _controller = OpnameController();
  DateTimeRange? _selectedRange;
  List<dynamic> _laporan = [];
  bool _isLoading = false;

  Future<void> _ambilLaporan() async {
    if (_selectedRange == null) return;

    setState(() => _isLoading = true);

    try {
      final data = await _controller.fetchOpnameReport(
        startDate: _selectedRange!.start,
        endDate: _selectedRange!.end,
      );
      setState(() {
        _laporan = data['data'] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _pilihTanggal() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );
    if (range != null) {
      setState(() {
        _selectedRange = range;
      });
      _ambilLaporan();
    }
  }

  void _cetakPDF() async {
    final doc = pw.Document();

    final formatter = NumberFormat.decimalPattern('id');
    final dateFormat = DateFormat('dd-MM-yyyy');

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text("Laporan Opname Stok",
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
              "Periode: ${dateFormat.format(_selectedRange!.start)} s/d ${dateFormat.format(_selectedRange!.end)}"),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              "Barang",
              "Satuan",
              "Harga",
              "Masuk",
              "Keluar",
              "Transfer",
              "Sisa"
            ],
            data: _laporan
                .map((e) => [
                      e['nama_barang'] ?? '-',
                      e['satuan'] ?? '-',
                      formatter.format(e['harga'] ?? 0),
                      e['masuk']?.toString() ?? '0',
                      e['keluar']?.toString() ?? '0',
                      e['transfer']?.toString() ?? '0',
                      e['total']?.toString() ?? '0',
                    ])
                .toList(),
            cellStyle: pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeText = _selectedRange == null
        ? "Pilih Rentang Tanggal"
        : "${DateFormat('dd/MM/yyyy').format(_selectedRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedRange!.end)}";

    return Scaffold(
      appBar: AppBar(title: Text("Laporan Opname")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pilihTanggal,
                  icon: Icon(Icons.date_range),
                  label: Text(dateRangeText),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_laporan.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Data laporan kosong. Silakan pilih tanggal terlebih dahulu.'),
                        ),
                      );
                    } else {
                      _cetakPDF();
                    }
                  },
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("Unduh PDF"),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _laporan.isEmpty
                    ? Center(child: Text("Tidak ada data."))
                    : ListView.builder(
                        itemCount: _laporan.length,
                        itemBuilder: (context, index) {
                          final item = _laporan[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item['nama_barang'] ?? "-",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text(
                                            "Satuan: ${item['satuan'] ?? '-'} | Harga: ${NumberFormat.decimalPattern().format(item['harga_satuan'] ?? 0)}"),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Masuk: ${item['masuk'] ?? 0}"),
                                        Text("Keluar: ${item['keluar'] ?? 0}"),
                                        Text(
                                            "Transfer: ${item['transfer'] ?? 0}"),
                                        Text("Sisa: ${item['total'] ?? 0}",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
