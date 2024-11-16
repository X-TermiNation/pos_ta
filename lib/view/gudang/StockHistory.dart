import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:get_storage/get_storage.dart';

class HistoryStockPage extends StatefulWidget {
  @override
  _HistoryStockPageState createState() => _HistoryStockPageState();
}

class _HistoryStockPageState extends State<HistoryStockPage> {
  late Future<List<dynamic>> historyStokData;
  late String idCabang;
  List<dynamic> filteredHistoryStok = [];
  List<dynamic> historyStok = [];
  String searchQuery = '';
  bool isAsc = true;
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = true; // Track loading state
  TextEditingController searchbar = TextEditingController();

  @override
  void initState() {
    super.initState();
    final dataStorage = GetStorage();
    idCabang = dataStorage.read('id_cabang') ?? '';
    historyStokData = fetchHistoryStokByCabang(idCabang);
  }

  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    DateFormat wibFormat = DateFormat('dd MMM yyyy HH:mm:ss');
    return wibFormat.format(parsedDate.add(Duration(hours: 7)));
  }

  Future<void> fetchItemAndSatuanDetailsForAllItems() async {
    for (var item in historyStok) {
      final details = await fetchItemAndSatuanDetails(
        item['barang_id'],
        item['satuan_id'],
        context,
      );

      if (details != null) {
        item['nama_barang'] = details['nama_barang'];
        item['nama_satuan'] = details['nama_satuan'];
      }
    }

    setState(() {
      filteredHistoryStok = List.from(historyStok);
      isLoading = false; // Set loading to false after fetching all details
    });
  }

  Future<Map<String, String>?> fetchItemAndSatuanDetails(
      String idBarang, String idSatuan, BuildContext context) async {
    final itemData = await searchItemByID(idBarang);
    if (itemData == null || !itemData.containsKey('nama_barang')) {
      showToast(context, 'Failed to fetch item data.');
      return null;
    }
    final namaBarang = itemData['nama_barang'];
    final satuanData = await getSatuanById(idBarang, idSatuan, context);
    if (satuanData == null || !satuanData.containsKey('nama_satuan')) {
      showToast(context, 'Failed to fetch satuan data.');
      return null;
    }
    final namaSatuan = satuanData['nama_satuan'];
    return {
      'nama_barang': namaBarang,
      'nama_satuan': namaSatuan,
    };
  }

  void filterData() {
    setState(() {
      filteredHistoryStok = historyStok.where((item) {
        DateTime itemDate = DateTime.parse(item['tanggal_pengisian']).toLocal();
        bool matchesSearch =
            item['nama_barang'].toString().contains(searchQuery) ||
                item['nama_satuan'].toString().contains(searchQuery) ||
                item['jenis_aktivitas'].toString().contains(searchQuery) ||
                item['Kode_Aktivitas'].toString().contains(searchQuery) ||
                formatDate(item['tanggal_pengisian']).contains(searchQuery);
        bool matchesDateRange = true;
        if (startDate != null && endDate != null) {
          DateTime normalizedStartDate =
              DateTime(startDate!.year, startDate!.month, startDate!.day);
          DateTime normalizedEndDate =
              DateTime(endDate!.year, endDate!.month, endDate!.day);
          matchesDateRange = itemDate.isAfter(normalizedStartDate) &&
              itemDate.isBefore(normalizedEndDate.add(Duration(days: 1)));
        }
        return matchesSearch && matchesDateRange;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History Stock'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: historyStokData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No History Stock Data Found'));
          }

          if (historyStok.isEmpty) {
            historyStok = snapshot.data!;
            fetchItemAndSatuanDetailsForAllItems();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchbar,
                  onChanged: (query) {
                    searchQuery = query;
                    filterData();
                  },
                  decoration: InputDecoration(
                    labelText:
                        'Search (Nama Barang, Nama Satuan, Kode Aktivitas, Tanggal, Jenis Aktivitas)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          sortAscending: isAsc,
                          sortColumnIndex: 2,
                          columns: [
                            DataColumn(label: Text('Item Name - Satuan Name')),
                            DataColumn(
                              label: Text('Activity Date'),
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  isAsc = ascending;
                                  filteredHistoryStok.sort((a, b) {
                                    DateTime aDate =
                                        DateTime.parse(a['tanggal_pengisian']);
                                    DateTime bDate =
                                        DateTime.parse(b['tanggal_pengisian']);
                                    return isAsc
                                        ? aDate.compareTo(bDate)
                                        : bDate.compareTo(aDate);
                                  });
                                });
                              },
                            ),
                            DataColumn(label: Text('Jenis Aktivitas')),
                            DataColumn(label: Text('Jumlah Satuan')),
                            DataColumn(label: Text('Kode Aktivitas')),
                            DataColumn(label: Text('Details')),
                          ],
                          rows: filteredHistoryStok.map((item) {
                            return DataRow(
                              cells: [
                                DataCell(Text(
                                    '${item['nama_barang'] ?? 'Unknown'} - ${item['nama_satuan'] ?? 'Unknown'}')),
                                DataCell(Text(
                                    formatDate(item['tanggal_pengisian']))),
                                DataCell(Text(item['jenis_aktivitas'])),
                                DataCell(Text(item['jumlah_input'].toString())),
                                DataCell(Text(item['Kode_Aktivitas'])),
                                DataCell(
                                  ElevatedButton(
                                    onPressed: () {
                                      // Show detailed dialog or another action
                                    },
                                    child: Text('Details'),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
