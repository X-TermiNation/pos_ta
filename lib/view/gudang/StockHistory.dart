import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';

class HistoryStockPage extends StatefulWidget {
  @override
  _HistoryStockPageState createState() => _HistoryStockPageState();
}

class _HistoryStockPageState extends State<HistoryStockPage> {
  late Future<List<dynamic>> historyStokData;
  late String idCabang;
  Map<String, dynamic>? selectedItem;
  List<dynamic> filteredHistoryStok = [];
  List<dynamic> historyStok = [];
  String searchQuery = '';
  bool isAsc = true;
  DateTime? startDate;
  DateTime? endDate;
  TextEditingController searchbar = TextEditingController();
  @override
  void initState() {
    super.initState();
    final dataStorage = GetStorage();
    idCabang = dataStorage.read('id_cabang') ?? '';
    historyStokData = fetchHistoryStokByCabang(idCabang);
  }

  // Function to format date in WIB format
  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    DateFormat wibFormat = DateFormat('dd MMM yyyy HH:mm:ss');
    return wibFormat.format(parsedDate.add(Duration(hours: 7)));
  }

  // Function to filter the history stock data based on the search query and date range
  void filterData() {
    setState(() {
      filteredHistoryStok = historyStok.where((item) {
        // Parse item date (tanggal_pengisian) into DateTime
        DateTime itemDate = DateTime.parse(item['tanggal_pengisian']).toLocal();

        bool matchesSearch =
            item['barang_id'].toString().contains(searchQuery) ||
                item['satuan_id'].toString().contains(searchQuery) ||
                item['sumber_transaksi_id'].toString().contains(searchQuery) ||
                formatDate(item['tanggal_pengisian']).contains(searchQuery);

        bool matchesDateRange = true;

        if (startDate != null && endDate != null) {
          // Normalize the startDate and endDate to compare only the date part (no time)
          DateTime normalizedStartDate =
              DateTime(startDate!.year, startDate!.month, startDate!.day);
          DateTime normalizedEndDate =
              DateTime(endDate!.year, endDate!.month, endDate!.day);

          // Check if itemDate is within the selected range
          matchesDateRange = itemDate.isAtSameMomentAs(normalizedStartDate) ||
              itemDate.isAfter(normalizedStartDate);
          matchesDateRange &= itemDate.isAtSameMomentAs(normalizedEndDate) ||
              itemDate.isBefore(normalizedEndDate.add(Duration(days: 1)));
        }

        return matchesSearch && matchesDateRange;
      }).toList();
    });
  }

  // Function to toggle the sorting order
  void toggleSortOrder() {
    setState(() {
      isAsc = !isAsc;
      filteredHistoryStok.sort((a, b) {
        DateTime aDate = DateTime.parse(a['tanggal_pengisian']);
        DateTime bDate = DateTime.parse(b['tanggal_pengisian']);
        return isAsc ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });
    });
  }

  // Function to select date range
  Future<void> selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor:
                Colors.blue, // Change the primary color here if needed
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              hintStyle: TextStyle(color: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        filterData(); // Apply filter after selecting date range
      });
    }
  }

  // Function to copy text to clipboard
  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard!')),
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

          // Set the initial data for historyStok and filteredHistoryStok
          if (historyStok.isEmpty) {
            historyStok = snapshot.data!;
            filteredHistoryStok = List.from(historyStok);
          }

          return Column(
            children: [
              // Search bar
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
                        'Search (Barang ID, Satuan ID, Supplier ID, Date)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => selectDateRange(context),
                    child: Text(startDate != null && endDate != null
                        ? '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                        : 'Select Date Range'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        startDate = null;
                        endDate = null;
                        searchbar.clear();
                        searchQuery = '';
                        filteredHistoryStok =
                            List.from(historyStok); // Reset filter
                      });
                    },
                    child: Text('Clear Filter'),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon:
                        Icon(isAsc ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: toggleSortOrder,
                  ),
                  Text(isAsc ? 'Date Ascending' : 'Date Descending'),
                  SizedBox(width: 10),
                ],
              ),

              // Display the filtered list and details
              Expanded(
                child: Row(
                  children: [
                    // List section
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                        itemCount: filteredHistoryStok.length,
                        itemBuilder: (context, index) {
                          var item = filteredHistoryStok[index];
                          String barangId = item['barang_id'];
                          String satuanId = item['satuan_id'];
                          String tanggalPengisian = item['tanggal_pengisian'];

                          return FutureBuilder<Map<String, dynamic>?>(
                            future: searchItemByID(barangId),
                            builder: (context, barangSnapshot) {
                              if (barangSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }

                              return FutureBuilder<Map<String, dynamic>?>(
                                future:
                                    getSatuanById(barangId, satuanId, context),
                                builder: (context, satuanSnapshot) {
                                  if (satuanSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }

                                  var barang = barangSnapshot.data;
                                  var satuan = satuanSnapshot.data;

                                  String barangName = barang?['nama_barang'] ??
                                      "Unknown Barang";
                                  String satuanName = satuan?['nama_satuan'] ??
                                      "Unknown Satuan";

                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 15),
                                    child: ListTile(
                                      title: Text('$barangName - $satuanName'),
                                      subtitle: Text(
                                          'Tanggal: ${formatDate(tanggalPengisian)} WIB'),
                                      onTap: () {
                                        setState(() {
                                          selectedItem = item;
                                        });
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Detail section
                    Expanded(
                      flex: 3,
                      child: selectedItem != null
                          ? Container(
                              color: Colors.black87,
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stock History Details',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Barang ID and details
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: searchItemByID(
                                        selectedItem!['barang_id']),
                                    builder: (context, barangSnapshot) {
                                      var barang = barangSnapshot.data;
                                      String barangId =
                                          selectedItem!['barang_id'];
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Barang ID: $barangId',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.copy,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  copyToClipboard(barangId);
                                                },
                                              ),
                                            ],
                                          ),
                                          if (barang != null) ...[
                                            Text(
                                              'Nama: ${barang['nama_barang']}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18),
                                            ),
                                            Text(
                                              'Jenis: ${barang['jenis_barang']}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18),
                                            ),
                                            Text(
                                              'Kategori: ${barang['kategori_barang']}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18),
                                            ),
                                          ],
                                          SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Text(
                                                'Satuan ID: ${selectedItem!['satuan_id']}',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.copy,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  copyToClipboard(selectedItem![
                                                      'satuan_id']);
                                                },
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Jumlah Input: ${selectedItem!['jumlah_input']}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Tanggal Pengisian: ${formatDate(selectedItem!['tanggal_pengisian'])} WIB',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ),
                                          Text(
                                            'Jenis Pengisian: ${selectedItem!['jenis_pengisian']}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'Supplier ID: ${selectedItem!['sumber_transaksi_id']}',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.copy,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  copyToClipboard(selectedItem![
                                                      'sumber_transaksi_id']);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Text(
                                'Select an item to view details',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
