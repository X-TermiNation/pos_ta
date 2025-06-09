import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ta_pos/view-model-flutter/laporan_controller.dart';
import 'package:ta_pos/view-model-flutter/barang_controller.dart';

class LaporanPendapatanPage extends StatefulWidget {
  const LaporanPendapatanPage({super.key});

  @override
  State<LaporanPendapatanPage> createState() => _LaporanPendapatanPageState();
}

class _LaporanPendapatanPageState extends State<LaporanPendapatanPage> {
  DateTimeRange? _selectedRange;
  Map<String, dynamic>? _data;
  bool _loading = false;
  final numberFormat = NumberFormat("#,##0", "id_ID");

  Future<String> _getNamaSatuan(
      String idBarang, String idSatuan, BuildContext context) async {
    final satuanData = await getSatuanById(idBarang, idSatuan, context);
    if (satuanData != null && satuanData["nama_satuan"] != null) {
      return satuanData["nama_satuan"];
    }
    return "Unknown";
  }

  Future<void> _fetchPendapatan() async {
    if (_selectedRange == null) return;

    setState(() => _loading = true);

    final result = await getPendapatanReport(
      startDate: _selectedRange!.start,
      endDate: _selectedRange!.end,
    );

    setState(() {
      _data = result["data"];
      _loading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final last = DateTime(2001);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: last,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: Colors.blue,
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.accent),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
      await _fetchPendapatan();
    }
  }

  Future<void> _downloadPDF() async {
    if (_data == null || (_data!["detail"] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data laporan kosong, tidak dapat mengunduh PDF')),
      );
      return;
    }

    final pdf = pw.Document();
    final formatter = DateFormat("dd MMM yyyy");

    final satuanMap = <String, String>{};

    for (var tx in _data!["detail"]) {
      for (var item in tx["barang_terjual"]) {
        final key = "${item["id_barang"]}|${item["id_satuan"]}";
        if (!satuanMap.containsKey(key)) {
          final satuanName = await _getNamaSatuan(
              item["id_barang"], item["id_satuan"], context);
          satuanMap[key] = satuanName;
        }
      }
    }

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Laporan Pendapatan",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(
                  "Periode: ${formatter.format(_selectedRange!.start)} - ${formatter.format(_selectedRange!.end)}"),
              pw.Divider(),
              pw.Text(
                  "Total Pendapatan Kotor: Rp ${numberFormat.format(_data!['total_pendapatan_kotor'])}"),
              pw.Text(
                  "Total Pajak: Rp ${numberFormat.format(_data!['total_pajak'])}"),
              pw.Text(
                  "Total Pendapatan Sebelum Pajak: Rp ${numberFormat.format(_data!['total_pendapatan_sebelum_pajak'])}"),
              pw.Text(
                  "Total Modal: Rp ${numberFormat.format(_data!['total_modal'])}"),
              pw.Text(
                  "Total Untung Sebelum Pajak: Rp ${numberFormat.format(_data!['total_untung_sebelum_pajak'])}"),
              pw.Text(
                  "Total Untung Termasuk Pajak: Rp ${numberFormat.format(_data!['total_untung_termasuk_pajak'])}"),
              pw.SizedBox(height: 16),
              pw.Text("Detail Transaksi",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(3),
                  5: const pw.FlexColumnWidth(2),
                  6: const pw.FlexColumnWidth(3),
                  7: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      for (final h in [
                        "No",
                        "Tanggal",
                        "Total Sebelum Pajak",
                        "Total Pajak",
                        "Total Termasuk Pajak",
                        "Modal",
                        "Untung Sebelum Pajak",
                        "Untung Termasuk Pajak"
                      ])
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        )
                    ],
                  ),
                  ...List.generate((_data!["detail"] as List).length, (index) {
                    final tx = _data!["detail"][index];
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("${index + 1}",
                              style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              formatter.format(DateTime.parse(tx["tanggal"])),
                              style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              "Rp ${numberFormat.format(tx["total_sebelum_pajak"])}",
                              style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              "Rp ${numberFormat.format(tx["total_pajak"])}",
                              style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              "Rp ${numberFormat.format(tx["total_termasuk_pajak"])}",
                              style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              "Rp ${numberFormat.format(tx["total_modal"])}",
                              style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              "Rp ${numberFormat.format(tx["untung_sebelum_pajak"])}",
                              style: pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              "Rp ${numberFormat.format(tx["untung_termasuk_pajak"])}",
                              style: pw.TextStyle(fontSize: 9)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text("Barang Terjual Per Tanggal:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...(_data!["detail"] as List).map((tx) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Tanggal: ${formatter.format(DateTime.parse(tx["tanggal"]))}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    ...(tx["barang_terjual"] as List).map((item) {
                      final key = "${item["id_barang"]}|${item["id_satuan"]}";
                      final satuan = satuanMap[key] ?? "Satuan?";
                      return pw.Text(
                        "- ${item["nama_barang"]} (${item["qty"]} $satuan) | "
                        "Harga Jual: Rp ${numberFormat.format(item["harga_jual_sebelum_pajak"])} | "
                        "Modal: Rp ${numberFormat.format(item["harga_modal"])}",
                        style: pw.TextStyle(fontSize: 12),
                      );
                    }).toList(),
                    pw.SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat("dd MMM yyyy");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Pendapatan"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Pilih Rentang Tanggal"),
                ),
                const SizedBox(width: 16),
                if (_data != null)
                  ElevatedButton.icon(
                    onPressed: _downloadPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Download PDF"),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_data != null && !_loading)
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      color: Colors.teal.shade900,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Periode: ${formatter.format(_selectedRange!.start)} - ${formatter.format(_selectedRange!.end)}",
                                style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(
                                "Total Pendapatan Kotor: Rp ${numberFormat.format(_data!['total_pendapatan_kotor'])}",
                                style: const TextStyle(color: Colors.white)),
                            Text(
                                "Total Pajak: Rp ${numberFormat.format(_data!['total_pajak'])}",
                                style: const TextStyle(color: Colors.white)),
                            Text(
                                "Total Pendapatan Sebelum Pajak: Rp ${numberFormat.format(_data!['total_pendapatan_sebelum_pajak'])}",
                                style: const TextStyle(color: Colors.white)),
                            Text(
                                "Total Modal: Rp ${numberFormat.format(_data!['total_modal'])}",
                                style: const TextStyle(color: Colors.white)),
                            Text(
                                "Total Untung Sebelum Pajak: Rp ${numberFormat.format(_data!['total_untung_sebelum_pajak'])}",
                                style: const TextStyle(color: Colors.white)),
                            Text(
                                "Total Untung Termasuk Pajak: Rp ${numberFormat.format(_data!['total_untung_termasuk_pajak'])}",
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Detail Transaksi:",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_data!["detail"] as List).map((tx) {
                      return Card(
                        color: Colors.grey.shade900,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Tanggal: ${formatter.format(DateTime.parse(tx["tanggal"]))}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                  "Total Sebelum Pajak: Rp ${numberFormat.format(tx["total_sebelum_pajak"])}",
                                  style: const TextStyle(color: Colors.white)),
                              Text(
                                  "Total Pajak: Rp ${numberFormat.format(tx["total_pajak"])}",
                                  style: const TextStyle(color: Colors.white)),
                              Text(
                                  "Total Termasuk Pajak: Rp ${numberFormat.format(tx["total_termasuk_pajak"])}",
                                  style: const TextStyle(color: Colors.white)),
                              Text(
                                  "Modal: Rp ${numberFormat.format(tx["total_modal"])}",
                                  style: const TextStyle(color: Colors.white)),
                              Text(
                                  "Untung Sebelum Pajak: Rp ${numberFormat.format(tx["untung_sebelum_pajak"])}",
                                  style: const TextStyle(color: Colors.white)),
                              Text(
                                  "Untung Termasuk Pajak: Rp ${numberFormat.format(tx["untung_termasuk_pajak"])}",
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
