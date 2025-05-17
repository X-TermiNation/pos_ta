import 'package:flutter/material.dart';
import 'package:ta_pos/view-model-flutter/barang_controller.dart';

String convertToWIB(String utcDateTimeString) {
  DateTime utcDateTime = DateTime.parse(utcDateTimeString);
  DateTime wibDateTime = utcDateTime.add(const Duration(hours: 7));
  String formattedDate = "${wibDateTime.day.toString().padLeft(2, '0')} "
      "${_getMonthName(wibDateTime.month)} "
      "${wibDateTime.year}, "
      "${wibDateTime.hour.toString().padLeft(2, '0')}:"
      "${wibDateTime.minute.toString().padLeft(2, '0')}";
  return "$formattedDate WIB";
}

String _getMonthName(int month) {
  const monthNames = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "Mei",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Okt",
    "Nov",
    "Des"
  ];
  return monthNames[month - 1];
}

class ConversionHistoryScreen extends StatefulWidget {
  final String idCabang;

  const ConversionHistoryScreen({Key? key, required this.idCabang})
      : super(key: key);

  @override
  _ConversionHistoryScreenState createState() =>
      _ConversionHistoryScreenState();
}

class _ConversionHistoryScreenState extends State<ConversionHistoryScreen> {
  late Future<List<dynamic>> _historyList;

  String _searchText = '';
  DateTimeRange? _selectedDateRange;

  // Cache barang data agar search dan tampil cepat
  final Map<String, Map<String, dynamic>> _itemCache = {};

  @override
  void initState() {
    super.initState();
    _historyList = fetchConversionHistory(widget.idCabang);
  }

  // Fungsi ambil data barang dengan cache
  Future<Map<String, dynamic>?> _getItemData(String? barangId) async {
    if (barangId == null) return null;
    if (_itemCache.containsKey(barangId)) return _itemCache[barangId];
    final data = await searchItemByID(barangId);
    if (data != null) _itemCache[barangId] = data;
    return data;
  }

  // Filter history berdasarkan searchText dan filter tanggal
  Future<List<dynamic>> _filterHistory(List<dynamic> historyList) async {
    if (historyList.isEmpty) return [];

    List<dynamic> filtered = [];

    for (var history in historyList) {
      final barangId = history['barang_id']?.toString();
      final itemData = await _getItemData(barangId);

      final String namaBarang =
          itemData?['nama_barang']?.toString().toLowerCase() ?? '';
      final String idBarang = barangId?.toLowerCase() ?? '';

      // Filter berdasarkan searchText: cari di nama barang atau id barang
      if (_searchText.isNotEmpty) {
        if (!(namaBarang.contains(_searchText.toLowerCase()) ||
            idBarang.contains(_searchText.toLowerCase()))) {
          continue;
        }
      }

      // Filter tanggal dengan inklusif (tanggal awal dan akhir ikut dihitung)
      if (_selectedDateRange != null) {
        DateTime historyDate = DateTime.parse(history['tanggal_konversi']);
        bool isInRange =
            (historyDate.isAtSameMomentAs(_selectedDateRange!.start) ||
                    historyDate.isAfter(_selectedDateRange!.start)) &&
                (historyDate.isAtSameMomentAs(_selectedDateRange!.end) ||
                    historyDate.isBefore(_selectedDateRange!.end));
        if (!isInRange) continue;
      }

      filtered.add(history);
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversion History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search & Filter bar
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 500,
                    child: TextField(
                      onChanged: (query) {
                        setState(() {
                          _searchText = query;
                        });
                      },
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        labelText: 'Search by Barang Name or ID',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    tooltip: "Range Tanggal Filter",
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDateRange: _selectedDateRange,
                      );
                      if (picked != null) {
                        final fixedEnd = DateTime(
                          picked.end.year,
                          picked.end.month,
                          picked.end.day,
                          23,
                          59,
                          59,
                        );
                        setState(() {
                          _selectedDateRange =
                              DateTimeRange(start: picked.start, end: fixedEnd);
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: "Clear filter",
                    onPressed: () {
                      setState(() {
                        _searchText = '';
                        _selectedDateRange = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Table
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _historyList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text("Error: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("No conversion history found."));
                  } else {
                    return FutureBuilder<List<dynamic>>(
                      future: _filterHistory(snapshot.data!),
                      builder: (context, filteredSnapshot) {
                        if (filteredSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (filteredSnapshot.hasError) {
                          return Center(
                              child: Text("Error: ${filteredSnapshot.error}",
                                  style: const TextStyle(color: Colors.red)));
                        } else if (!filteredSnapshot.hasData ||
                            filteredSnapshot.data!.isEmpty) {
                          return const Center(
                              child: Text("No matching data found."));
                        }

                        final filteredHistory = filteredSnapshot.data!;

                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Container(
                            constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width),
                            child: DataTable(
                              headingRowColor:
                                  MaterialStateProperty.all(Colors.grey[500]),
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(
                                    label: Text(
                                  "Tanggal",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )),
                                DataColumn(
                                    label: Text(
                                  "Nama Barang",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )),
                                DataColumn(
                                    label: Text(
                                  "ID Barang",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )),
                                DataColumn(
                                    label: Text(
                                  "Satuan Awal",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )),
                                DataColumn(
                                    label: Text(
                                  "Satuan Tujuan",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )),
                              ],
                              rows: filteredHistory.map((history) {
                                final barangId =
                                    history['barang_id']?.toString();
                                final tanggal =
                                    convertToWIB(history['tanggal_konversi']);

                                return DataRow(cells: [
                                  DataCell(Text(tanggal)),
                                  DataCell(FutureBuilder<Map<String, dynamic>?>(
                                    future: _getItemData(barangId),
                                    builder: (context, itemSnapshot) {
                                      if (itemSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text("Memuat...");
                                      } else if (itemSnapshot.hasError) {
                                        return const Text("Error");
                                      } else if (!itemSnapshot.hasData ||
                                          itemSnapshot.data == null) {
                                        return const Text("Tidak ditemukan");
                                      }
                                      return Text(
                                          itemSnapshot.data!['nama_barang'] ??
                                              'N/A');
                                    },
                                  )),
                                  DataCell(FutureBuilder<Map<String, dynamic>?>(
                                    future: _getItemData(barangId),
                                    builder: (context, itemSnapshot) {
                                      if (itemSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text("...");
                                      } else if (!itemSnapshot.hasData ||
                                          itemSnapshot.data == null) {
                                        return const Text("-");
                                      }
                                      return Text(
                                          itemSnapshot.data!['_id'] ?? '-');
                                    },
                                  )),
                                  DataCell(Text(
                                      "${history['satuan_asal']} (${history['jumlah_awal_sa']} → ${history['jumlah_akhir_sa']})")),
                                  DataCell(Text(
                                      "${history['satuan_tujuan']} (${history['jumlah_awal_st']} → ${history['jumlah_akhir_st']})")),
                                ]);
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
