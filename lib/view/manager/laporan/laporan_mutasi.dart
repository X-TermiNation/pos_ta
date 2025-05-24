import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ta_pos/view-model-flutter/laporan_controller.dart';

class MutasiReportPage extends StatefulWidget {
  const MutasiReportPage({
    super.key,
  });
  @override
  State<MutasiReportPage> createState() => _MutasiReportPageState();
}

class _MutasiReportPageState extends State<MutasiReportPage> {
  final MutasiController _controller = MutasiController();
  DateTimeRange? selectedRange;
  Map<String, dynamic>? mutasiData;
  bool loading = false;

  final dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = selectedRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime.now(),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });
      await _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (selectedRange == null) return;

    setState(() {
      loading = true;
    });

    final data = await _controller.fetchMutasi(
      startDate: selectedRange!.start,
      endDate: selectedRange!.end,
    );

    setState(() {
      mutasiData = data;
      loading = false;
    });
  }

  Future<void> _printPdf() async {
    if (mutasiData == null ||
        (mutasiData!['mutasi']['keluar'].isEmpty &&
            mutasiData!['mutasi']['masuk'].isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data kosong, tidak bisa cetak PDF')),
      );
      return;
    }

    final pdf = await _generatePdf(mutasiData!);

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  Future<pw.Document> _generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final mutasiKeluar = data['mutasi']['keluar'] as List<dynamic>;
    final mutasiMasuk = data['mutasi']['masuk'] as List<dynamic>;

    pw.Widget buildMutasiTable(List<dynamic> mutasiList) {
      if (mutasiList.isEmpty) {
        return pw.Text('Tidak terdapat mutasi.');
      }

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: mutasiList.map((m) {
          // Table header for items
          final tableHeaders = ['Nama Barang', 'Satuan', 'Jumlah'];
          // Table rows for items
          final tableRows = (m['items'] as List).map((item) {
            return [
              item['nama_barang'] ?? '-',
              item['nama_satuan'] ?? '-',
              item['jumlah_item'].toString(),
            ];
          }).toList();

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Kode SJ: ${m['kode_sj'] ?? "-"}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Tanggal Request: ${m['tanggal_request']}'),
              pw.Text('Status: ${m['status']}'),
              pw.Text('Total Item: ${m['total_jumlah_item']}'),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: tableHeaders,
                data: tableRows,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding:
                    const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                },
              ),
              pw.SizedBox(height: 12),
            ],
          );
        }).toList(),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Laporan Mutasi',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Periode: ${dateFormat.format(selectedRange!.start)} s/d ${dateFormat.format(selectedRange!.end)}',
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 10),

            // Mutasi Keluar Section
            pw.Text(
              'Mutasi Keluar',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 4),
            buildMutasiTable(mutasiKeluar),

            // Mutasi Masuk Section
            pw.Text(
              'Mutasi Masuk',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 4),
            buildMutasiTable(mutasiMasuk),
          ];
        },
      ),
    );

    return pdf;
  }

  Widget _buildMutasiList(String title, List<dynamic> list) {
    if (list.isEmpty) {
      return Text('Tidak ada data $title.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        ...list.map((m) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kode SJ: ${m['kode_sj'] ?? "-"}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Tanggal Request: ${m['tanggal_request']}'),
                  Text('Tanggal Konfirmasi: ${m['tanggal_konfirmasi'] ?? '-'}'),
                  Text('Tanggal Diambil: ${m['tanggal_diambil'] ?? '-'}'),
                  Text('Status: ${m['status']}'),
                  Text('Total Item: ${m['total_jumlah_item']}'),
                  const SizedBox(height: 6),
                  const Text('Detail Item:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...((m['items'] as List).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                          '- ${item['nama_barang']} (${item['nama_satuan']}): ${item['jumlah_item']}'),
                    );
                  }).toList()),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Optional: load default range data on open
    final now = DateTime.now();
    selectedRange =
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final from = selectedRange?.start;
    final to = selectedRange?.end;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Mutasi')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(from == null || to == null
                      ? 'Pilih rentang tanggal'
                      : 'Periode: ${dateFormat.format(from)} - ${dateFormat.format(to)}'),
                ),
                ElevatedButton(
                  onPressed: _pickDateRange,
                  child: const Text('Pilih Tanggal'),
                ),
                SizedBox(
                  width: 10,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Cetak PDF'),
                  onPressed: _printPdf,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (mutasiData == null)
              const Center(child: Text('Tidak ada data'))
            else
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildMutasiList(
                          'Mutasi Masuk',
                          mutasiData!['mutasi']['masuk'],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildMutasiList(
                          'Mutasi Keluar',
                          mutasiData!['mutasi']['keluar'],
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
}
