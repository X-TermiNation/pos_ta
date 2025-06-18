import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
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

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    _selectedRange = DateTimeRange(
      start: DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );

    _fetchPendapatan();
  }

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
      final adjustedRange = DateTimeRange(
        start: picked.start,
        end: picked.end.add(const Duration(
          hours: 23,
          minutes: 59,
          seconds: 59,
          milliseconds: 999,
        )),
      );

      setState(() => _selectedRange = adjustedRange);
      await _fetchPendapatan();
    }
  }

  Future<void> _downloadPDF() async {
    if (_data == null || (_data!["detail"] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data laporan kosong, tidak dapat mengunduh PDF'),
        ),
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

    // ... [ISI PDF Tetap Seperti Kode Kamu Sebelumnya]
    // (tidak diubah karena kamu minta tidak mengubah isi PDF)
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
                  "Total Pendapatan Kotor: Rp ${numberFormat.format(_data!['total_pendapatan_kotor'] ?? 0)}"),
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
                              "Rp ${numberFormat.format(tx["total_sebelum_pajak"] ?? 0)}",
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
                      final diskon = (item["diskon"] ?? 0) > 0
                          ? "${item["diskon"].toString()}%"
                          : "Tidak ada";
                      return pw.Text(
                        "- ${item["nama_barang"]} (${item["qty"]} $satuan) | "
                        "Harga Jual: Rp ${numberFormat.format(item["harga_awal"] ?? 0)} | "
                        "Modal: Rp ${numberFormat.format(item["harga_modal"] ?? 0)} | "
                        "Diskon: $diskon",
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

    // Simpan ke folder Downloads secara manual
    final now = DateTime.now();
    final filename =
        "Laporan_Pendapatan_${DateFormat('dd-MM-yyyy_HHmmss').format(now)}.pdf";

    final downloadsDir =
        Directory("${Platform.environment['USERPROFILE']}\\Downloads");
    final file = File("${downloadsDir.path}\\$filename");

    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF berhasil disimpan di: ${file.path}")),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_data != null && !_loading)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        columnWidths: const {
                          0: FixedColumnWidth(220),
                          1: FlexColumnWidth(),
                        },
                        children: [
                          _buildTableRow("Periode:",
                              "${formatter.format(_selectedRange!.start)} - ${formatter.format(_selectedRange!.end)}"),
                          _buildTableRow("Total Pendapatan Kotor:",
                              "Rp ${numberFormat.format(_data!['total_pendapatan_kotor'])}"),
                          _buildTableRow("Total Pajak:",
                              "Rp ${numberFormat.format(_data!['total_pajak'])}"),
                          _buildTableRow("Pendapatan Sebelum Pajak:",
                              "Rp ${numberFormat.format(_data!['total_pendapatan_sebelum_pajak'])}"),
                          _buildTableRow("Total Modal:",
                              "Rp ${numberFormat.format(_data!['total_modal'])}"),
                          _buildTableRow("Untung Sebelum Pajak:",
                              "Rp ${numberFormat.format(_data!['total_untung_sebelum_pajak'])}"),
                          _buildTableRow("Untung Termasuk Pajak:",
                              "Rp ${numberFormat.format(_data!['total_untung_termasuk_pajak'])}"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Detail Transaksi:",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor:
                                MaterialStateProperty.all(Colors.teal.shade800),
                            dataRowColor:
                                MaterialStateProperty.all(Colors.grey.shade900),
                            columnSpacing: 24,
                            headingRowHeight: 48,
                            dataRowHeight: 56,
                            columns: const [
                              DataColumn(
                                  label: Text("Tanggal Transaksi",
                                      style: TextStyle(color: Colors.white))),
                              DataColumn(
                                  label: Text("Pendapatan Sebelum Pajak",
                                      style: TextStyle(color: Colors.white))),
                              DataColumn(
                                  label: Text("Pajak Transaksi Total",
                                      style: TextStyle(color: Colors.white))),
                              DataColumn(
                                  label: Text("Pendapatan Termasuk Pajak",
                                      style: TextStyle(color: Colors.white))),
                              DataColumn(
                                  label: Text("Modal Transaksi",
                                      style: TextStyle(color: Colors.white))),
                              DataColumn(
                                  label: Text("Untung Sebelum Pajak",
                                      style: TextStyle(color: Colors.white))),
                              DataColumn(
                                  label: Text("Untung Termasuk Pajak",
                                      style: TextStyle(color: Colors.white))),
                            ],
                            rows: (_data!["detail"] as List).map<DataRow>((tx) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                      formatter.format(
                                          DateTime.parse(tx["tanggal"])),
                                      style: const TextStyle(
                                          color: Colors.white))),
                                  DataCell(Text(
                                      "Rp ${numberFormat.format(tx["total_sebelum_pajak"])}",
                                      style: const TextStyle(
                                          color: Colors.white))),
                                  DataCell(Text(
                                      "Rp ${numberFormat.format(tx["total_pajak"])}",
                                      style: const TextStyle(
                                          color: Colors.white))),
                                  DataCell(Text(
                                      "Rp ${numberFormat.format(tx["total_termasuk_pajak"])}",
                                      style: const TextStyle(
                                          color: Colors.white))),
                                  DataCell(Text(
                                      "Rp ${numberFormat.format(tx["total_modal"])}",
                                      style: const TextStyle(
                                          color: Colors.white))),
                                  DataCell(Text(
                                      "Rp ${numberFormat.format(tx["untung_sebelum_pajak"])}",
                                      style: const TextStyle(
                                          color: Colors.white))),
                                  DataCell(Text(
                                      "Rp ${numberFormat.format(tx["untung_termasuk_pajak"])}",
                                      style: const TextStyle(
                                          color: Colors.white))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
