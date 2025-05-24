import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ta_pos/view-model-flutter/laporan_controller.dart';

class LaporanPengeluaranPage extends StatefulWidget {
  @override
  _LaporanPengeluaranPageState createState() => _LaporanPengeluaranPageState();
}

class _LaporanPengeluaranPageState extends State<LaporanPengeluaranPage> {
  DateTimeRange? _selectedDateRange;
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  void _fetchReportData() async {
    if (_selectedDateRange == null) return;

    setState(() => _isLoading = true);

    final data = await getPengeluaranReport(
      startDate: _selectedDateRange!.start,
      endDate: _selectedDateRange!.end,
    );

    setState(() {
      _isLoading = false;
      _reportData = data;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _fetchReportData();
    }
  }

  Future<void> _generatePdf(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 2, // Menampilkan dua angka di belakang koma
    );
    ;

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          // Mengubah 'detail' menjadi List<dynamic> bukan Map
          final List<dynamic> detail = reportData['detail'] as List<dynamic>;
          final List<pw.Widget> content = [];

          content.add(pw.Text('Laporan Pengeluaran',
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)));
          content.add(pw.SizedBox(height: 10));
          content.add(pw.Text(
            'Periode: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
            style: pw.TextStyle(fontSize: 12),
          ));
          content.add(pw.SizedBox(height: 20));

          // Iterasi detail berdasarkan transaksi
          for (var transaksi in detail) {
            content.add(pw.Text('Tanggal: ${transaksi['tanggal'] ?? ''}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
            content.add(pw.Text(
                'Nota: ${transaksi['invoice_number'] ?? ''} | Supplier: ${transaksi['supplier'] ?? ''} | Subtotal: ${formatCurrency.format(transaksi['subtotal_transaksi'] ?? 0)}',
                style: pw.TextStyle(fontSize: 10)));

            // Cek apakah 'items' ada dan bukan kosong
            if (transaksi['items'] != null && transaksi['items'].isNotEmpty) {
              content.add(pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FixedColumnWidth(100),
                  1: pw.FixedColumnWidth(50),
                  2: pw.FixedColumnWidth(50),
                  3: pw.FixedColumnWidth(60),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text('Nama Barang')),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text('Harga')),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text('Jumlah')),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text('Subtotal')),
                    ],
                  ),
                  ...List.generate(transaksi['items'].length, (index) {
                    final item = transaksi['items'][index];

                    // Pastikan Item_Qty dan Item_Price tidak null, gunakan default 0 jika null
                    final qty =
                        item['qty'] ?? 0; // Sesuaikan dengan data yang ada
                    final price =
                        item['harga'] ?? 0; // Sesuaikan dengan data yang ada
                    final subtotal = qty * price;

                    return pw.TableRow(children: [
                      pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(item['nama_barang'] ??
                              '')), // Sesuaikan dengan data yang ada
                      pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(formatCurrency.format(price))),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                              '$qty ${item['satuan'] ?? ''}')), // Sesuaikan dengan data yang ada
                      pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(formatCurrency.format(subtotal))),
                    ]);
                  })
                ],
              ));
            } else {
              content.add(pw.Text(
                'Tidak ada item untuk transaksi ini.',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ));
            }

            content.add(pw.SizedBox(height: 10));
          }

          content.add(pw.SizedBox(height: 20));
          content.add(pw.Text(
            'Total Pengeluaran: ${formatCurrency.format(reportData['pengeluaran'] ?? 0)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ));

          return content;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildReportTable() {
    if (_reportData == null || _reportData!['detail'] == null) {
      return Center(child: Text('Data tidak tersedia'));
    }

    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 2,
    );

    final List<dynamic> detail = _reportData!['detail'];
    final rows = <DataRow>[];
    int counter = 1;

    for (var transaksi in detail) {
      final items = transaksi['items'];
      if (items != null && items.isNotEmpty) {
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          final subtotal = item['qty'] * item['harga'];
          rows.add(DataRow(cells: [
            DataCell(Text('${counter++}')),
            DataCell(Text(transaksi['invoice_number'])),
            DataCell(Text(transaksi['tanggal'])),
            DataCell(Text(transaksi['supplier'])),
            DataCell(Text(item['nama_barang'])),
            DataCell(Text(formatCurrency.format(item['harga']))),
            DataCell(Text('${item['qty']} ${item['satuan']}')),
            DataCell(Text(formatCurrency.format(subtotal))),
          ]));
        }

        rows.add(DataRow(cells: [
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('Subtotal Transaksi',
              style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text(
              formatCurrency.format(transaksi['subtotal_transaksi'] ?? 0),
              style: TextStyle(fontWeight: FontWeight.bold))),
        ]));
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 12,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('No')),
                DataColumn(label: Text('Invoice')),
                DataColumn(label: Text('Tanggal')),
                DataColumn(label: Text('Supplier')),
                DataColumn(label: Text('Nama Barang')),
                DataColumn(label: Text('Harga')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Subtotal')),
              ],
              rows: rows,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Laporan Pengeluaran')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _selectDateRange(context),
                  child: Text(_selectedDateRange == null
                      ? 'Pilih Rentang Tanggal'
                      : 'Periode: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'),
                ),
                SizedBox(
                  width: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_reportData == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Data belum tersedia. Silakan ambil laporan terlebih dahulu.'),
                        ),
                      );
                    } else {
                      _generatePdf(_reportData!);
                    }
                  },
                  child: Text("Unduh PDF"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _reportData == null
                    ? Text("Silakan pilih rentang tanggal.")
                    : Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Pengeluaran: Rp ${NumberFormat("#,###").format(_reportData!['pengeluaran'])}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Expanded(child: _buildReportTable()),
                          ],
                        ),
                      )
          ],
        ),
      ),
    );
  }
}
