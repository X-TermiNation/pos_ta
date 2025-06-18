import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
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

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedRange = DateTimeRange(
      start: today.subtract(Duration(days: 6)),
      end: today,
    );
    _ambilLaporan();
  }

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

  Future<void> _cetakPDF() async {
    final pdf = pw.Document();
    final formatter = NumberFormat.decimalPattern('id');
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd-MM-yyyy');
    final now = DateTime.now();
    final namaFile =
        'Laporan_Opname_${dateFormat.format(now)}_${DateFormat('HHmmss').format(now)}.pdf';

    // Buat konten PDF
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text("Laporan Opname Stok",
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(
              "Periode: ${dateFormat.format(_selectedRange!.start)} s/d ${dateFormat.format(_selectedRange!.end)}",
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
              columnWidths: {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(3),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(2),
                5: pw.FlexColumnWidth(2),
                6: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Barang')),
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Satuan')),
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5), child: pw.Text('Harga')),
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5), child: pw.Text('Masuk')),
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Keluar')),
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Transfer')),
                    pw.Padding(
                        padding: pw.EdgeInsets.all(5), child: pw.Text('Sisa')),
                  ],
                ),
                ..._laporan.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(item['nama_barang'] ?? '-')),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(item['satuan'] ?? '-')),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(
                              currency.format(item['harga_satuan'] ?? 0))),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text('${item['masuk'] ?? 0}')),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text('${item['keluar'] ?? 0}')),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text('${item['transfer'] ?? 0}')),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${item['total'] ?? 0}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          )),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    try {
      // Cari folder Downloads di Windows
      final downloadsDir = Directory(
          '${Platform.environment['USERPROFILE']}\\Downloads'); // Windows path
      final filePath = '${downloadsDir.path}\\$namaFile';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Konfirmasi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF disimpan di Downloads sebagai $namaFile')),
      );
    } catch (e) {
      print("❌ Gagal menyimpan PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan PDF: ${e.toString()}")),
      );
    }
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
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Header Tabel
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      width: 1, color: Colors.grey.shade400),
                                ),
                                color: Colors.grey.shade500,
                              ),
                              child: Row(
                                children: const [
                                  Expanded(
                                      flex: 2,
                                      child: Text("Barang",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 1,
                                      child: Text("Satuan",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 1,
                                      child: Text("Harga",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 1,
                                      child: Text("Masuk",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 1,
                                      child: Text("Keluar",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 1,
                                      child: Text("Transfer",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 1,
                                      child: Text("Sisa",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),

                            // Isi Tabel
                            ..._laporan.map((item) {
                              final formatter =
                                  NumberFormat.decimalPattern('id');

                              return Column(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                                item['nama_barang'] ?? '-')),
                                        Expanded(
                                            flex: 1,
                                            child: Text(item['satuan'] ?? '-')),
                                        Expanded(
                                            flex: 1,
                                            child: Text(formatter.format(
                                                item['harga_satuan'] ?? 0))),
                                        Expanded(
                                            flex: 1,
                                            child:
                                                Text('${item['masuk'] ?? 0}')),
                                        Expanded(
                                            flex: 1,
                                            child:
                                                Text('${item['keluar'] ?? 0}')),
                                        Expanded(
                                            flex: 1,
                                            child: Text(
                                                '${item['transfer'] ?? 0}')),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '${item['total'] ?? 0}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                      height: 1, color: Colors.grey.shade500),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
