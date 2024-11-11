import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:flutter/services.dart';

class HistorySupplierPage extends StatefulWidget {
  @override
  _HistorySupplierPageState createState() => _HistorySupplierPageState();
}

class _HistorySupplierPageState extends State<HistorySupplierPage> {
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> filteredSuppliers = [];
  Map<String, dynamic>? selectedSupplier;
  TextEditingController _searchController = TextEditingController();
  String? searchQuery = '';
  bool isAscending = true; // To toggle between ascending and descending order

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    loadSuppliers();
    _searchController.addListener(_searchSuppliers);
  }

  Future<void> loadSuppliers() async {
    final data = await fetchSuppliersByCabang();
    setState(() {
      suppliers = data;
      filteredSuppliers = data;
    });
  }

  void _searchSuppliers() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    filteredSuppliers = suppliers.where((supplier) {
      bool matchesSearch = supplier['nama_supplier']
              .toString()
              .toLowerCase()
              .contains(searchQuery!) ||
          formatToWIB(supplier['tanggal_transaksi'])
              .toLowerCase()
              .contains(searchQuery!) ||
          supplier['_id'].toString().toLowerCase().contains(searchQuery!);

      if (startDate != null && endDate != null) {
        DateTime transactionDate =
            DateTime.parse(supplier['tanggal_transaksi']);
        return matchesSearch &&
            transactionDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
            transactionDate.isBefore(endDate!.add(Duration(days: 1)));
      }
      return matchesSearch;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      startDate = null;
      endDate = null;
      _searchController.clear();
      _applyFilters();
    });
  }

  // Convert DateTime to WIB (UTC+7)
  String formatToWIB(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    DateTime wibDate = date.toUtc().add(Duration(hours: 7));
    return DateFormat('yyyy-MM-dd HH:mm').format(wibDate) + ' WIB';
  }

  // Toggle sorting order and apply the sort
  void _toggleSortOrder() {
    setState(() {
      isAscending = !isAscending;
      if (isAscending) {
        filteredSuppliers.sort((a, b) => DateTime.parse(a['tanggal_transaksi'])
            .compareTo(DateTime.parse(b['tanggal_transaksi'])));
      } else {
        filteredSuppliers.sort((a, b) => DateTime.parse(b['tanggal_transaksi'])
            .compareTo(DateTime.parse(a['tanggal_transaksi'])));
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
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
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text("Supplier History"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search bar section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Supplier Name or Date...',
                hintStyle: TextStyle(color: Colors.white60),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          // Date range and Clear Filter button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _selectDateRange(context),
                  child: Text(
                    startDate != null && endDate != null
                        ? 'Selected Range: ${DateFormat('yyyy-MM-dd').format(startDate!)} - ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                        : 'Select Date Range',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Toggle Sort Order button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: _toggleSortOrder,
              child: Text(
                isAscending
                    ? 'Sort by Date Ascending'
                    : 'Sort by Date Descending',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Supplier list section
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = filteredSuppliers[index];
                      return ListTile(
                        title: Text(
                          supplier['nama_supplier'],
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "WIB Time: ${formatToWIB(supplier['tanggal_transaksi'])}",
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          setState(() {
                            selectedSupplier = supplier;
                          });
                        },
                      );
                    },
                  ),
                ),
                // Detail section
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.black87,
                    padding: EdgeInsets.all(16.0),
                    child: selectedSupplier != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Supplier Details',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    "ID History Supplier: ${selectedSupplier!['_id']}",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                  SizedBox(width: 8),
                                  Tooltip(
                                    message: "Copy ID",
                                    child: IconButton(
                                      icon: Icon(Icons.copy,
                                          color: Colors.white, size: 20),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: selectedSupplier!['_id']
                                                .toString()));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  "ID copied to clipboard")),
                                        );
                                      },
                                      constraints: BoxConstraints(),
                                      padding: EdgeInsets.all(4),
                                      splashRadius: 20,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Name: ${selectedSupplier!['nama_supplier']}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Contact: ${selectedSupplier!['kontak'] ?? 'N/A'}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Address: ${selectedSupplier!['alamat'] ?? 'N/A'}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Total Spending: ${selectedSupplier!['total_pengeluaran']}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Transaction Date: ${formatToWIB(selectedSupplier!['tanggal_transaksi'])}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              "Select a supplier to see details",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
