import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ta_pos/view/manager/laporan/laporan pendapatan.dart';
import 'package:ta_pos/view/manager/laporan/laporan_pengeluaran.dart';

class ReportNavigationWidget extends StatelessWidget {
  const ReportNavigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_ReportItem> reports = [
      _ReportItem(
        title: "Laporan Pemasukan",
        description: "Melihat biaya pemasukan/penjualan barang dalam cabang.",
        icon: LucideIcons.trendingUp,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LaporanPendapatanPage()),
          );
        },
      ),
      _ReportItem(
        title: "Laporan Pengeluaran",
        description: "Melihat biaya re-stock barang dalam rentang waktu.",
        icon: LucideIcons.package,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LaporanPengeluaranPage()),
          );
        },
      ),
      _ReportItem(
        title: "Inventaris & Opname",
        description: "Informasi keluar/masuk & stok barang gudang.",
        icon: LucideIcons.clipboardList,
        onTap: () {
          // TODO: Navigate to Laporan Opname
        },
      ),
      _ReportItem(
        title: "Mutasi Barang",
        description: "Laporan barang yang ditransfer antar cabang.",
        icon: LucideIcons.repeat,
        onTap: () {
          // TODO: Navigate to Laporan Mutasi
        },
      ),
      _ReportItem(
        title: "Analisa Revenue",
        description: "Grafik pendapatan, laba, dan analisa performa.",
        icon: LucideIcons.barChart4,
        onTap: () {
          // TODO: Navigate to Laporan Revenue
        },
      ),
    ];

    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.all(32.0),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.5,
        children: reports.map((report) {
          return InkWell(
            onTap: report.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade800),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(report.icon, color: Colors.tealAccent, size: 32),
                  const SizedBox(height: 16),
                  Text(
                    report.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportItem {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  _ReportItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}
