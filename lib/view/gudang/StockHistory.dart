import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart'; // Import for clipboard functionality

class HistoryStockPage extends StatefulWidget {
  @override
  _HistoryStockPageState createState() => _HistoryStockPageState();
}

class _HistoryStockPageState extends State<HistoryStockPage> {
  late Future<List<dynamic>> historyStokData;
  late String idCabang;
  Map<String, dynamic>? selectedItem;
  List<dynamic> filteredHistoryStok = [];
  String searchQuery = '';
  bool isAsc = true;

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

  // Function to filter the history stock data based on the search query
  void filterData(String query, List<dynamic> historyStok) {
    setState(() {
      searchQuery = query;
      filteredHistoryStok = historyStok.where((item) {
        return item['barang_id'].toString().contains(query) ||
            item['satuan_id'].toString().contains(query) ||
            item['sumber_transaksi_id'].toString().contains(query) ||
            formatDate(item['tanggal_pengisian']).contains(query);
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

          var historyStok = snapshot.data!;

          // If searchQuery is empty, show all data, otherwise filter
          if (searchQuery.isNotEmpty) {
            filteredHistoryStok = historyStok.where((item) {
              return item['barang_id'].toString().contains(searchQuery) ||
                  item['satuan_id'].toString().contains(searchQuery) ||
                  item['sumber_transaksi_id']
                      .toString()
                      .contains(searchQuery) ||
                  formatDate(item['tanggal_pengisian']).contains(searchQuery);
            }).toList();
          } else {
            filteredHistoryStok = historyStok;
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (query) {
                    filterData(query, historyStok);
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
                                return CircularProgressIndicator(); // Loading indicator
                              }

                              return FutureBuilder<Map<String, dynamic>?>(
                                future:
                                    getSatuanById(barangId, satuanId, context),
                                builder: (context, satuanSnapshot) {
                                  if (satuanSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator(); // Loading indicator
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
                                          selectedItem =
                                              item; // Update selected item
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
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              'Jenis: ${barang['jenis_barang']}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              'Kategori: ${barang['kategori_barang']}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              'Insert Date: ${formatDate(barang['insert_date'])}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                            if (barang['exp_date'] != null)
                                              Text(
                                                'Exp Date: ${formatDate(barang['exp_date'])}',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16),
                                              ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  // Satuan ID and details
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: getSatuanById(
                                        selectedItem!['barang_id'],
                                        selectedItem!['satuan_id'],
                                        context),
                                    builder: (context, satuanSnapshot) {
                                      var satuan = satuanSnapshot.data;
                                      String satuanId =
                                          selectedItem!['satuan_id'];
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Satuan ID: $satuanId',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.copy,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  copyToClipboard(satuanId);
                                                },
                                              ),
                                            ],
                                          ),
                                          if (satuan != null) ...[
                                            Text(
                                              'Nama: ${satuan['nama_satuan']}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              'Jumlah: ${satuan['jumlah_satuan']}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              'Harga: ${satuan['harga_satuan']}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              'Isi Satuan: ${satuan['isi_satuan']}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  // Remaining fields in the details section
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Sumber Transaksi ID: ${selectedItem!['sumber_transaksi_id']}',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 18),
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
                                  SizedBox(height: 8),
                                  Text(
                                    'Tanggal Pengisian: ${formatDate(selectedItem!['tanggal_pengisian'])}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Jumlah Input: ${selectedItem!['jumlah_input']}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Jenis Pengisian: ${selectedItem!['jenis_pengisian']}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Text(
                                'Select a stock history item to view details',
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
