import 'package:flutter/material.dart';
import 'package:ta_pos/view-model-flutter/barang_controller.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HistorySupplierPage extends StatefulWidget {
  @override
  _HistorySupplierPageState createState() => _HistorySupplierPageState();
}

class _HistorySupplierPageState extends State<HistorySupplierPage> {
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> filteredSuppliers = [];
  Map<String, dynamic>? selectedSupplier;
  TextEditingController _searchController = TextEditingController();
  TextEditingController _invoiceSearchController = TextEditingController();
  String? searchQuery = '';
  String? invoiceSearchQuery = '';

  Map<String, List<Map<String, dynamic>>> originalInvoices = {};

  @override
  void initState() {
    super.initState();
    loadSuppliers();
    _searchController.addListener(_searchSuppliers);
    _invoiceSearchController.addListener(_searchInvoices);
  }

  Future<void> loadSuppliers() async {
    final data = await fetchSuppliersByCabang();
    setState(() {
      suppliers = data;
      filteredSuppliers = data;
      for (var supplier in suppliers) {
        originalInvoices[supplier['_id']] =
            List<Map<String, dynamic>>.from(supplier['invoices']);
      }
    });
  }

  void _searchSuppliers() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _searchInvoices() {
    setState(() {
      invoiceSearchQuery = _invoiceSearchController.text.toLowerCase();
      _applyInvoiceFilters();
    });
  }

  void _applyFilters() {
    filteredSuppliers = suppliers.where((supplier) {
      bool matchesSearch = supplier['nama_supplier']
              .toString()
              .toLowerCase()
              .contains(searchQuery!) ||
          supplier['_id'].toString().toLowerCase().contains(searchQuery!);
      return matchesSearch;
    }).toList();
  }

  void _applyInvoiceFilters() {
    if (selectedSupplier != null && selectedSupplier!['invoices'] != null) {
      selectedSupplier!['invoices'] =
          originalInvoices[selectedSupplier!['_id']]!.where((invoice) {
        return invoice['invoice_number']
                .toString()
                .toLowerCase()
                .contains(invoiceSearchQuery!) ||
            invoice['insert_date']
                .toString()
                .toLowerCase()
                .contains(invoiceSearchQuery!);
      }).toList();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _invoiceSearchController.clear();
      _applyFilters();
      if (selectedSupplier != null) {
        selectedSupplier!['invoices'] = List<Map<String, dynamic>>.from(
            originalInvoices[selectedSupplier!['_id']]!);
      }
    });
  }

  String formatDateToWIB(String dateString) {
    DateTime dateUtc = DateTime.parse(dateString).toUtc();
    DateTime dateWIB = dateUtc.add(Duration(hours: 7));
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateWIB);
  }

  List<Map<String, dynamic>> invoiceItems = [];
  String? selectedInvoiceNumber;

  Future<void> loadInvoiceItems(String invoiceNumber) async {
    final items = await fetchInvoiceItems(invoiceNumber);
    setState(() {
      invoiceItems = items;
      selectedInvoiceNumber = invoiceNumber;
    });
  }

  void clearInvoiceItems() {
    setState(() {
      invoiceItems = [];
      selectedInvoiceNumber = null;
    });
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Supplier Name or ID...',
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
          Expanded(
            child: Row(
              children: [
                // === Daftar Supplier ===
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Daftar Supplier",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Expanded(
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
                                  supplier['_id'],
                                  style: TextStyle(color: Colors.white70),
                                ),
                                tileColor: selectedSupplier != null &&
                                        selectedSupplier!['_id'] ==
                                            supplier['_id']
                                    ? Colors.grey[800]
                                    : null,
                                onTap: () {
                                  setState(() {
                                    selectedSupplier = supplier;
                                    invoiceItems = [];
                                    selectedInvoiceNumber = null;
                                    _invoiceSearchController.clear();
                                    selectedSupplier!['invoices'] =
                                        List<Map<String, dynamic>>.from(
                                      originalInvoices[supplier['_id']]!,
                                    );
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // === Daftar Invoice & Barang ===
                Expanded(
                  flex: 5,
                  child: selectedSupplier != null
                      ? Row(
                          children: [
                            // Daftar Invoice
                            Expanded(
                              flex: 2,
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.greenAccent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.black,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Daftar Invoice",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    TextField(
                                      controller: _invoiceSearchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search invoice...',
                                        hintStyle:
                                            TextStyle(color: Colors.white54),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(height: 8),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: selectedSupplier!['invoices']
                                            .length,
                                        itemBuilder: (context, index) {
                                          final invoice =
                                              selectedSupplier!['invoices']
                                                  [index];
                                          return ListTile(
                                            title: Text(
                                              'Invoice No: ${invoice['invoice_number']}',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            subtitle: Text(
                                              'Date: ${formatDateToWIB(invoice['insert_date'])}',
                                              style: TextStyle(
                                                  color: Colors.white70),
                                            ),
                                            onTap: () => loadInvoiceItems(
                                                invoice['invoice_number']),
                                            tileColor: selectedInvoiceNumber ==
                                                    invoice['invoice_number']
                                                ? Colors.grey[800]
                                                : null,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Daftar Barang
                            Expanded(
                              flex: 3,
                              child: Container(
                                margin: EdgeInsets.only(
                                    top: 8, bottom: 16, right: 16, left: 4),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(
                                      color: Colors.greenAccent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Daftar Barang",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        if (invoiceItems.isNotEmpty)
                                          IconButton(
                                            icon: Icon(Icons.clear,
                                                color: Colors.white),
                                            onPressed: clearInvoiceItems,
                                          ),
                                      ],
                                    ),
                                    Divider(color: Colors.white),
                                    Expanded(
                                      child: invoiceItems.isNotEmpty
                                          ? ListView.builder(
                                              itemCount: invoiceItems.length,
                                              itemBuilder: (context, index) {
                                                final item =
                                                    invoiceItems[index];
                                                return ListTile(
                                                  title: Text(
                                                    item['item_name'] ??
                                                        'No Name',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  subtitle: Text(
                                                    'Qty: ${item['qty']} | Unit: ${item['unit']} | Price: ${item['price']}',
                                                    style: TextStyle(
                                                        color: Colors.white70),
                                                  ),
                                                );
                                              },
                                            )
                                          : Center(
                                              child: Text(
                                                "No item detail. Select an invoice.",
                                                style: TextStyle(
                                                    color: Colors.white60),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            "Select a supplier to view details",
                            style: TextStyle(color: Colors.white70),
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
