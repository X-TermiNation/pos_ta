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
      if (item['jenis_aktivitas'] == 'masuk') {
        List<String> parts = item['Kode_Aktivitas'].toString().split('_');
        final invoicedata = parts[1];
        print(invoicedata);
        final supplierDetails = await fetchSupplierDetails(invoicedata);
        if (supplierDetails != null) {
          item['nama_supplier'] = supplierDetails['nama_supplier'];
          item['kontak_supplier'] = supplierDetails['kontak'];
        }
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

  Future<Map<String, dynamic>?> fetchSupplierDetails(String invoice) async {
    final supplierData = await fetchSupplierByInvoice(invoice);
    if (supplierData.isNotEmpty) {
      return {
        'nama_supplier':
            supplierData['data']['nama_supplier'] ?? 'Unknown Supplier',
        'kontak': supplierData['data']['kontak'] ?? 'N/A',
      };
    }
    return null; // Return null if no supplier data is found
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

  Future<void> showDateRangePickerDialog() async {
    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDateRange != null) {
      setState(() {
        startDate = pickedDateRange.start;
        endDate = pickedDateRange.end;
      });
      filterData();
    }
  }

  void clearDateFilters() {
    setState(() {
      startDate = null;
      endDate = null;
      filterData();
    });
  }

  void showItemDetailsPopup(Map<String, dynamic> item) async {
    // Check if supplier details are already available
    if (item['jenis_aktivitas'] == 'Masuk' &&
        (item['nama_supplier'] == null || item['kontak_supplier'] == null)) {
      // Extract invoice data from Kode_Aktivitas
      List<String> parts = item['Kode_Aktivitas'].toString().split('_');
      final invoicedata = parts[1];

      // Fetch supplier details
      final supplierDetails = await fetchSupplierDetails(invoicedata);
      print(supplierDetails);
      if (supplierDetails != null) {
        setState(() {
          item['nama_supplier'] = supplierDetails['nama_supplier'];
          item['kontak_supplier'] = supplierDetails['kontak'];
        });
      } else {
        showToast(context, 'Supplier details not found.');
      }
    }

    // Show the popup
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Activity Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Nama Barang: ${item['nama_barang'] ?? 'N/A'}'),
                Text('Nama Satuan: ${item['nama_satuan'] ?? 'N/A'}'),
                Text('Jenis Aktivitas: ${item['jenis_aktivitas'] ?? 'N/A'}'),
                Text('Jumlah Satuan: ${item['jumlah_input'] ?? 'N/A'}'),
                Text('Kode Aktivitas: ${item['Kode_Aktivitas'] ?? 'N/A'}'),
                Text(
                    'Tanggal Pengisian: ${formatDate(item['tanggal_pengisian'])}'),
                if (item['jenis_aktivitas'] == 'Masuk') ...[
                  Text('Nama Supplier: ${item['nama_supplier'] ?? 'N/A'}'),
                  Text('Kontak Supplier: ${item['kontak_supplier'] ?? 'N/A'}'),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                child: Row(
                  children: [
                    Expanded(
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
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: showDateRangePickerDialog,
                    ),
                    if (startDate != null && endDate != null)
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: clearDateFilters,
                        tooltip: 'Clear date filter',
                      ),
                  ],
                ),
              ),
              if (startDate != null && endDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Date Range: ${DateFormat('dd MMM yyyy').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0), // Right padding for content
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Nama Barang & Satuan')),
                          DataColumn(label: Text('Tanggal Pengisian')),
                          DataColumn(label: Text('Jenis Aktivitas')),
                          DataColumn(label: Text('Jumlah Input')),
                          DataColumn(label: Text('Kode Aktivitas')),
                          DataColumn(label: Text('Detail')),
                        ],
                        rows: filteredHistoryStok.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                  '${item['nama_barang'] ?? 'N/A'} - ${item['nama_satuan'] ?? 'N/A'}')),
                              DataCell(
                                  Text(formatDate(item['tanggal_pengisian']))),
                              DataCell(Text(item['jenis_aktivitas'] ?? 'N/A')),
                              DataCell(Text(item['jumlah_input'].toString())),
                              DataCell(Text(item['Kode_Aktivitas'] ?? 'N/A')),
                              DataCell(
                                IconButton(
                                  icon: Icon(Icons.visibility),
                                  onPressed: () => showItemDetailsPopup(item),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
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
