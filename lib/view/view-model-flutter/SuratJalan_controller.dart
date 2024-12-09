import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

Future<void> generateSuratJalanPDF({
  required String cabangRequest,
  required String telpRequest,
  required String alamatRequest,
  required String cabangConfirm,
  required String telpConfirm,
  required String alamatConfirm,
  required List<Map<String, dynamic>> items,
  required String date, // Adding date as parameter
}) async {
  try {
    // Create a PDF document
    final pdf = pw.Document();

    // Add a page to the PDF document
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Header
              pw.Center(
                child: pw.Text("Surat Jalan",
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),

              // Date Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Tanggal: $date", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Info Section (TO & FROM)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // TO (Cabang Request)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("TO:",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Cabang: $cabangRequest"),
                      pw.Text("No Telp: $telpRequest"),
                      pw.Text("Alamat: $alamatRequest"),
                    ],
                  ),
                  // FROM (Cabang Confirmed)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("FROM:",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Cabang: $cabangConfirm"),
                      pw.Text("No Telp: $telpConfirm"),
                      pw.Text("Alamat: $alamatConfirm"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Divider
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Table Section
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Nama Barang', 'Nama Satuan', 'Jumlah Item'],
                data: items
                    .map((item) => [
                          item['nama_item'] ?? '',
                          item['nama_satuan'] ?? '',
                          item['jumlah_item'].toString(),
                        ])
                    .toList(),
                border: pw.TableBorder.all(
                  width: 1,
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(fontSize: 12),
              ),
            ],
          ); // Return content to be added on the page
        },
      ),
    );

    // Get the Downloads directory for saving the PDF
    final outputDir = await getDownloadsDirectory();
    final pdfFile = File('${outputDir!.path}/Surat_Jalan.pdf');

    // Save the PDF file
    await pdfFile.writeAsBytes(await pdf.save());

    print('PDF saved to: ${pdfFile.path}');
  } catch (e) {
    print('Error generating PDF: $e');
  }
}
