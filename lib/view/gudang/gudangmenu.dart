import 'package:flutter/material.dart';
import 'package:ta_pos/view/gudang/AddHierarchyPage.dart';
import 'package:ta_pos/view/gudang/StockHistory.dart';
import 'package:ta_pos/view/gudang/SubmitRequestScreen.dart';
import 'package:ta_pos/view/gudang/SupplierHistory.dart';
import 'package:ta_pos/view/gudang/responsive_header.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view/view-model-flutter/cabang_controller.dart';
import 'package:ta_pos/view/view-model-flutter/gudang_controller.dart';
import 'package:ta_pos/view/gudang/stockConversionHistory.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:io';

String? selectedvalueJenis = "";
String? selectedvalueKategori = "";
String? detailbarang_ID = "";
String katakategori = "";
String Edit_katakategori = "";
bool _isEditUser = false;
late String? edit_selectedvalueKategori;
//untuk update barang
String temp_id_update = "";
bool isExp = false;
String satuan_idbarang = "";
String base_satuan_id = "";
String nama_satuan_initial_spc = "No Satuan";
Future<List<Map<String, dynamic>>> barangdata = Future.value([]);

class GudangMenu extends StatefulWidget {
  const GudangMenu({super.key});

  @override
  State<GudangMenu> createState() => _GudangMenuState();
}

class _GudangMenuState extends State<GudangMenu> {
  //lokasi inisialisasi dalam state
  TextEditingController nama_barang = TextEditingController();
  TextEditingController nama_kategori = TextEditingController();
  TextEditingController nama_jenis = TextEditingController();
  TextEditingController initial_insert_date_detail = TextEditingController();
  TextEditingController last_insert_date_detail = TextEditingController();
  TextEditingController edit_nama_barang = TextEditingController();
  TextEditingController edit_nama_kategorijenis = TextEditingController();
  TextEditingController nama_satuan = TextEditingController();
  TextEditingController harga_satuan = TextEditingController();
  TextEditingController isi_satuan = TextEditingController();
  TextEditingController nama_satuan_initial = TextEditingController();
  TextEditingController harga_satuan_initial = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  TextEditingController _searchControllerBarangList = TextEditingController();
  TextEditingController id_supplier_insert = TextEditingController();
  TextEditingController id_supplier_stock_alert = TextEditingController();
  TextEditingController ReStock_InvoiceNumber = TextEditingController();

  //supplier data for dropdown in restock section
  String selectedSupplierId = '';
  List<Map<String, dynamic>> suppliers = [];
  Map<String, dynamic> selectedSupplierData = {};

  void onBarangRefresh() async {
    await fetchDataAndUseInJsonString();
    await fetchExpiringBatches();
    setState(() {
      barangdata = Future.value([]);
      barangdata = getBarang();
      print(barangdata);
    });
  }

  Future<void> loadSuppliers() async {
    final data =
        await fetchSuppliersByCabang(); // Use your fetchSuppliersByCabang function here
    setState(() {
      suppliers = data;
    });
  }

  // Set the selected supplier data when a supplier is selected from the dropdown
  void onSupplierSelected(Map<String, dynamic> selectedSupplier) {
    setState(() {
      selectedSupplierId = selectedSupplier['_id'];
      selectedSupplierData = selectedSupplier;
    });
  }

  XFile? selectedImage;

  String searchQuery = '';
  List<Map<String, dynamic>> _dataList = [];
  List<Map<String, dynamic>> satuanList = [];
  Map<String, dynamic>? selectedSatuan;
  String _jsonString = '';

  //for stock
  List<Map<String, dynamic>> itemsStock = []; // List to hold each item entry
  List<Map<String, dynamic>> barangListStock = []; // List to hold barang data
  List<Map<String, dynamic>> satuanListStock = [];
  Map<String, dynamic>? selectedBarangStock;
  Map<String, dynamic>? selectedSatuanStock;
  TextEditingController manual_restock_namabarang = TextEditingController();

  void _addItem() {
    setState(() {
      itemsStock.add({
        'ID_barang': null,
        'ID_satuan': null,
        'jumlah': 0,
        'harga_satuan': 0.0,
        'selectedBarang': null,
        'selectedSatuan': null,
        'exp_date': null,
        'satuanList': [], // Satuan list specific to this item
      });
    });
  }

  void _updateItem(int index, String key, dynamic value) {
    setState(() {
      itemsStock[index][key] = value;
    });
  }

  void onBarangSelectedStock(int index, Map<String, dynamic> selectedBarang) {
    setState(() {
      itemsStock[index]['selectedBarang'] = selectedBarang;
      itemsStock[index]['ID_barang'] = selectedBarang['_id'];
      // Fetch satuan details for the selected barang
      fetchSatuanDetailsStock(index, selectedBarang['_id']);
    });
  }

  Future<void> fetchBarangStock() async {
    try {
      // Fetch barang data
      var data = await getBarang();
      setState(() {
        barangListStock = List<Map<String, dynamic>>.from(
            data); // assuming data is a List<Map<String, dynamic>>
      });
    } catch (e) {
      showToast(context, 'Failed to fetch barang data: $e');
    }
  }

  Future<void> fetchSatuanDetailsStock(int index, String barangId) async {
    try {
      var data = await getsatuan(barangId, context);

      if (mounted) {
        setState(() {
          itemsStock[index]['satuanList'] =
              List<Map<String, dynamic>>.from(data);
          itemsStock[index]['selectedSatuan'] =
              itemsStock[index]['satuanList'].isNotEmpty
                  ? itemsStock[index]['satuanList'][0]
                  : null;
          itemsStock[index]['ID_satuan'] =
              itemsStock[index]['selectedSatuan']?['_id'];
        });
      }
    } catch (e) {
      showToast(context, 'Failed to fetch satuan data: $e');
    }
  }

  //untuk alert kadaluarsa
  List<Map<String, dynamic>> expiringBatches = [];

  Future<void> _loadExpiringBatches() async {
    final batches = await fetchExpiringBatches();
    setState(() {
      expiringBatches = batches;
    });
  }

  //konversi barang
  Map<String, dynamic>? selectedBarang;
  List<Map<String, dynamic>> konversi_satuanList = [];
  List<Map<String, dynamic>> konversi_satuanTo = [];
  int ConversionRate = 0;
  String konversisearchQuery = "";
  Map<String, dynamic>? selectedSatuanFrom;
  Map<String, dynamic>? selectedSatuanTo;
  int jumlah_tambah = 0;
  int jumlah_kurang = 0;
  int stockAmount = 0;
  TextEditingController amountkonversifrom = TextEditingController();
  TextEditingController amountkonversito = TextEditingController();
  Map<String, dynamic>? hierarchysatuan;
  //
  void onBarangSelected(Map<String, dynamic> barang) async {
    final satuanList = await getsatuan(barang["_id"].toString(), context);

    // Exclude the base satuan from the list
    final List<Map<String, dynamic>> filteredSatuanList = satuanList
        .where((satuan) => satuan["_id"] != barang["base_satuan_id"])
        .toList();

    setState(() {
      selectedBarang = barang;
      konversi_satuanList =
          filteredSatuanList; // Update the satuanFrom dropdown with filtered list
      selectedSatuanFrom = null; // Reset selected left dropdown
      konversi_satuanTo = []; // Reset right dropdown
      selectedSatuanTo = null;
    });
  }

  void onSatuanFromSelected(Map<String, dynamic> satuanFrom) async {
    if (selectedBarang == null) {
      showToast(context, 'Please select a Barang first.');
      return;
    }

    final String idBarang =
        selectedBarang!["_id"]?.toString() ?? ''; // Use empty string if null
    final String selectedSatuanFromId =
        satuanFrom["_id"]?.toString() ?? ''; // Use empty string if null

    // Check if both IDs are not empty before proceeding
    if (idBarang.isEmpty || selectedSatuanFromId.isEmpty) {
      showToast(context, 'Barang or SatuanFrom ID is missing.');
      return;
    }

    try {
      // Fetch hierarchy for the selected satuanFrom
      final List<Map<String, dynamic>> hierarchyData =
          await fetchUnitConversionsWithId(selectedSatuanFromId, context);

      // Check if the hierarchyData has valid entries
      if (hierarchyData.isEmpty) {
        showToast(context, 'No hierarchies found for the selected satuan.');
        setState(() {
          konversi_satuanTo = []; // Reset right dropdown
          selectedSatuanTo = null;
        });
        return;
      }

      // Extract child satuan details from the hierarchyData
      List<Map<String, dynamic>> childSatuans = [];

      for (var hierarchy in hierarchyData) {
        final String? childSatuanId = hierarchy['target'];
        // Check if childSatuanId is not null
        if (childSatuanId != null && childSatuanId.isNotEmpty) {
          // Fetch each child satuan
          final satuanDetails =
              await getSatuanById(idBarang, childSatuanId, context);
          if (satuanDetails != null) {
            childSatuans.add(satuanDetails);
          }
        }
      }

      setState(() {
        selectedSatuanFrom = satuanFrom;
        konversi_satuanTo = childSatuans; // Populate right dropdown
        selectedSatuanTo = null; // Reset selected right dropdown
      });
    } catch (error) {
      showToast(context, 'Error fetching child satuans: $error');
      print('Error fetching child satuans: $error');
    }
  }

  //untuk tombol konversi(masih dalam proses)
  void onConvert(String id_barang, String id_satuanFrom, String id_satuanTo) {
    num increase = stockAmount * ConversionRate;
    num decrease = stockAmount;
    convertSatuan(
      id_barang,
      id_satuanFrom,
      id_satuanTo,
      decrease.toInt(),
      increase.toInt(),
      context,
    );
    setState(() {});
  }

  //tambah gambar pada insert gambar
  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  //get kategori dan jenis untuk combo box
  void fetchData() async {
    try {
      edit_selectedvalueKategori = await getFirstKategoriId();
      selectedvalueJenis = await getFirstJenisId();
      selectedvalueKategori = await getFirstKategoriId();

      print(
          "data jenis dan kategori pertama: $selectedvalueJenis dan $selectedvalueKategori");
    } catch (error) {
      print('Error fetchdata kategori dan jenis: $error');
    }
  }

  //satuan detail for detail barang
  void fetchsatuandetail() async {
    if (temp_id_update.isNotEmpty) {
      final data = await getsatuan(temp_id_update, context);
      setState(() {
        satuanList = data;
        if (satuanList.isNotEmpty) {
          selectedSatuan = satuanList[0];
        }
      });
    }
  }

  //convert into json String
  Future<void> fetchDataAndUseInJsonString() async {
    try {
      List<Map<String, dynamic>> data = await barangdata;
      if (data.isNotEmpty) {
        String jsonString = json.encode(data);
        setState(() {
          _jsonString = jsonString;
          _dataList = List<Map<String, dynamic>>.from(json.decode(_jsonString));
          print('JSON String: $jsonString');
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  //kategori and jenis add widget
  void showTambahJenisKategoriDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent closing by touching outside the pop-up
      builder: (BuildContext context) {
        int step = 1;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              contentPadding: EdgeInsets.all(16),
              content: Container(
                height: 350,
                width: 500,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: step == 1
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tambah Jenis",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 40),
                          TextFormField(
                            controller: nama_jenis,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Field tidak boleh kosong';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelText: 'Nama Jenis',
                              labelStyle: TextStyle(fontSize: 16),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 16),
                                  backgroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  // Skip to the kategori step
                                  setState(() {
                                    step = 2;
                                  });
                                },
                                child: Text(
                                  "Skip",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 16),
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  if (nama_jenis.text.isNotEmpty) {
                                    addjenis(nama_jenis.text, context);
                                    nama_jenis.clear();
                                    setState(() {
                                      fetchData();
                                      getJenis();
                                      step = 2; // Move to kategori step
                                    });
                                  } else {
                                    showToast(
                                        context, "jenis tidak boleh kosong");
                                  }
                                },
                                child: Text(
                                  "Tambah Jenis",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tambah Kategori",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: nama_kategori,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Field tidak boleh kosong';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelText: 'Nama Kategori',
                              labelStyle: TextStyle(fontSize: 16),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Pilih Jenis:",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          FutureBuilder<Map<String, String>>(
                            future: getmapjenis(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (snapshot.hasData &&
                                  snapshot.data != null) {
                                var entries = snapshot.data!.entries.toList();

                                if (entries.isEmpty) {
                                  return Text('No Items available');
                                }

                                // Ensure selectedvalueJenis is valid
                                if (selectedvalueJenis == null ||
                                    !entries.any((entry) =>
                                        entry.key == selectedvalueJenis)) {
                                  selectedvalueJenis = entries.first.key;
                                }

                                return DropdownButton<String>(
                                  value: selectedvalueJenis,
                                  isExpanded: true,
                                  items: entries
                                      .map((entry) => DropdownMenuItem(
                                            child: Text(entry.value),
                                            value: entry.key,
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedvalueJenis = value!;
                                    });
                                  },
                                );
                              } else {
                                return Text('No data available');
                              }
                            },
                          ),
                          Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 16),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              addkategori(nama_kategori.text,
                                  selectedvalueJenis.toString(), context);
                              nama_kategori.clear();
                              setState(() {
                                fetchData();
                                getKategori();
                                Navigator.of(context).pop();
                              });
                            },
                            child: Text(
                              "Tambah Kategori",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    onBarangRefresh();
    getFirstKategoriId().then((value) => edit_selectedvalueKategori);
    getKategori();
    fetchData();
    getdatagudang();
    fetchDataAndUseInJsonString();
    fetchDataKategori();
    getlowstocksatuan(context);
    fetchBarangStock();
    loadSuppliers();
    _loadExpiringBatches();
  }

  List<Map<String, dynamic>> _searchResults = [];
  void _updateSearchResults(String query) {
    setState(() {
      // Filter data berdasarkan nama barang sesuai dengan query
      _searchResults = _dataList
          .where((data) =>
              data['nama_barang'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  String generateKodeAktivitas(
      String sumberTransaksiId, String jenisAktivitas) {
    // Get the current time in UTC and adjust for UTC+7 (WIB)
    final now = DateTime.now().toUtc().add(Duration(hours: 7));

    // Format the time to a readable string in WIB
    final wibTimestamp = DateFormat('yyyyMMdd_HHmmss').format(now);

    return '${jenisAktivitas}_${sumberTransaksiId}_${wibTimestamp}';
  }

  void updateMultipleItems(
    List<Map<String, dynamic>> items,
    String id_supplier,
    String sumberTransaksi,
    String action,
    BuildContext context,
  ) async {
    final kodeAktivitas = generateKodeAktivitas(sumberTransaksi, 'MSK');

    for (var item in items) {
      final String idBarang = item['ID_barang'];
      final String idSatuan = item['ID_satuan'];
      final int jumlahSatuan = item['jumlah'];
      final DateTime? exp_date = item['exp_date'];

      updatejumlahSatuanTambah(idBarang, idSatuan, jumlahSatuan, exp_date,
          kodeAktivitas, action, context);
    }

    // Clear the list of items after submission
    items.clear();
    await addInvoiceToSupplier(
        supplierId: id_supplier, invoiceNumber: sumberTransaksi);
  }

  //function and data type for supplier type
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  //for save data to being sent to the database
  void _saveSupplier() async {
    final idCabang = GetStorage().read("id_cabang");
    // Combine selected date and time, then convert to UTC
    final supplierData = {
      "id_cabang": idCabang,
      "nama_supplier": _supplierNameController.text,
      "kontak": _contactController.text,
      "alamat": _addressController.text,
    };
    await addSupplier(supplierData);
    await loadSuppliers();
    print("Supplier Data: $supplierData");
  }

  String formatToWIBDetail(String expDate) {
    DateTime parsedDate = DateTime.parse(expDate);
    DateTime wibDate = parsedDate.add(const Duration(hours: 7));
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(wibDate);

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveSideMenu(
        containers: [
          Center(
            child: Container(
              width: 1500,
              height: 750,
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Daftar Barang Section
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Daftar Barang",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Tooltip(
                                message: 'See Stock History',
                                child: IconButton(
                                  icon:
                                      Icon(Icons.history, color: Colors.white),
                                  onPressed: () {
                                    // Navigate to the Stock History page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HistoryStockPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _searchControllerBarangList,
                            decoration: InputDecoration(
                              hintText: 'Search Barang',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.blue,
                              filled: true,
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                          SizedBox(height: 16),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final availableWidth =
                                    constraints.maxWidth - 32;
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: availableWidth,
                                    ),
                                    child: FutureBuilder(
                                      future: barangdata,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else if (snapshot.hasError) {
                                          return Center(
                                              child: Text(
                                                  'Error: ${snapshot.error}'));
                                        } else if (!snapshot.hasData ||
                                            snapshot.data == null) {
                                          return Center(
                                              child: Text('No data available'));
                                        } else {
                                          final List<Map<String, dynamic>>?
                                              data = snapshot.data as List<
                                                  Map<String, dynamic>>?;
                                          if (data == null) {
                                            return Center(
                                                child:
                                                    Text('No data available'));
                                          }

                                          // Filter the data based on the search query
                                          final filteredData =
                                              data.where((map) {
                                            // Convert each field to a string and check if it contains the search query
                                            final searchText = [
                                              map['nama_barang']
                                                      ?.toLowerCase() ??
                                                  '',
                                              map['jenis_barang']
                                                      ?.toLowerCase() ??
                                                  '',
                                              map['kategori_barang']
                                                      ?.toLowerCase() ??
                                                  '',
                                              map['exp_date']
                                                      ?.toString()
                                                      .toLowerCase() ??
                                                  '',
                                              map['initial_insert_date']
                                                      ?.toString()
                                                      .toLowerCase() ??
                                                  '',
                                            ].join(
                                                ' '); // Concatenate all fields into a single string for searching

                                            return searchText
                                                .contains(searchQuery);
                                          }).toList();

                                          if (filteredData.isEmpty) {
                                            return Center(
                                                child: Text(
                                                    'No items match your search'));
                                          }

                                          final rows = filteredData.map((map) {
                                            return DataRow(cells: [
                                              DataCell(
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      // Handle 'initial_insert_date'
                                                      DateTime utcTimeInitial =
                                                          DateTime.parse(map[
                                                                  'initial_insert_date'])
                                                              .toUtc();
                                                      DateTime wibTimeInitial =
                                                          utcTimeInitial.add(
                                                              Duration(
                                                                  hours: 7));
                                                      initial_insert_date_detail
                                                          .text = DateFormat(
                                                              'yyyy-MM-dd HH:mm')
                                                          .format(
                                                              wibTimeInitial)
                                                          .toString();

                                                      // Handle 'last_insert_date', fallback to '-'
                                                      if (map['last_insert_date'] !=
                                                          null) {
                                                        DateTime utcTimelast =
                                                            DateTime.parse(map[
                                                                    'last_insert_date'])
                                                                .toUtc();
                                                        DateTime wibTimelast =
                                                            utcTimelast.add(
                                                                Duration(
                                                                    hours: 7));
                                                        last_insert_date_detail
                                                            .text = DateFormat(
                                                                'yyyy-MM-dd HH:mm')
                                                            .format(wibTimelast)
                                                            .toString();
                                                      } else {
                                                        last_insert_date_detail
                                                            .text = "-";
                                                      }

                                                      detailbarang_ID =
                                                          map['_id'];
                                                      edit_nama_barang.text =
                                                          map['nama_barang'];
                                                      String jenisBarang =
                                                          map['jenis_barang'];
                                                      String kategoriBarang =
                                                          map['kategori_barang'];
                                                      edit_nama_kategorijenis
                                                              .text =
                                                          "$jenisBarang / $kategoriBarang";

                                                      _isEditUser = true;
                                                      temp_id_update =
                                                          map['_id'];
                                                      fetchsatuandetail();
                                                    });
                                                  },
                                                  child: Text(
                                                    map['nama_barang'],
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                              DataCell(Text(
                                                '${map['jenis_barang']} / ${map['kategori_barang']}',
                                                style: TextStyle(fontSize: 16),
                                              )),
                                              DataCell(Text(
                                                map['initial_insert_date'] !=
                                                        null
                                                    ? map['initial_insert_date']
                                                        .toString()
                                                        .substring(0, 10)
                                                    : "-",
                                                style: TextStyle(fontSize: 16),
                                              )),
                                              DataCell(
                                                ElevatedButton(
                                                  onPressed: () {
                                                    deletebarang(map['_id']);
                                                    setState(() {
                                                      onBarangRefresh();
                                                    });
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                  ),
                                                  child: Text('Delete',
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                ),
                                              ),
                                            ]);
                                          }).toList();

                                          return SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  500, // 16 + 16 padding
                                              child: DataTable(
                                                headingRowColor:
                                                    MaterialStateColor
                                                        .resolveWith(
                                                  (states) => Colors.blue,
                                                ),
                                                columnSpacing: 20,
                                                dataRowColor: MaterialStateColor
                                                    .resolveWith(
                                                  (states) => Colors.black,
                                                ),
                                                dataTextStyle: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                                headingTextStyle: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                columns: const <DataColumn>[
                                                  DataColumn(
                                                      label:
                                                          Text('Nama Barang')),
                                                  DataColumn(
                                                      label: Text(
                                                          'Jenis/Kategori')),
                                                  DataColumn(
                                                      label: Text(
                                                          'Initial Insert Date')),
                                                  DataColumn(
                                                      label:
                                                          Text('Hapus Barang')),
                                                ],
                                                rows: rows,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  // Detail Barang Section
                  Expanded(
                    flex: 3,
                    child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                "Detail Barang",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 20.0),
                            Text(
                              "Barang ID:",
                              style: TextStyle(fontSize: 15),
                            ),
                            Row(
                              children: [
                                Text(
                                  "$detailbarang_ID",
                                  style: TextStyle(fontSize: 15),
                                ),
                                SizedBox(width: 8.0),
                                detailbarang_ID != ""
                                    ? IconButton(
                                        icon: Icon(Icons.copy,
                                            color: Colors.blue),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: detailbarang_ID!));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    "Barang ID copied to clipboard")),
                                          );
                                        },
                                      )
                                    : SizedBox()
                              ],
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              "Nama Barang : ${edit_nama_barang.text}",
                              style: TextStyle(fontSize: 15),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              "Jenis/Kategori : ${edit_nama_kategorijenis.text}",
                              style: TextStyle(fontSize: 15),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              "First Time Insert Date : ${initial_insert_date_detail.text}",
                              style: TextStyle(fontSize: 15),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              "Last Time Updated Date : ${last_insert_date_detail.text}",
                              style: TextStyle(fontSize: 15),
                            ),
                            SizedBox(height: 20.0),
                            Text(
                              "Satuan:",
                              style: TextStyle(fontSize: 15),
                            ),
                            DropdownButton<Map<String, dynamic>>(
                              value: selectedSatuan,
                              hint: Text('Select Satuan'),
                              items: satuanList.map((satuan) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: satuan,
                                  child:
                                      Text(satuan['nama_satuan'] ?? 'No Name'),
                                );
                              }).toList(),
                              onChanged: (selected) {
                                setState(() {
                                  selectedSatuan = selected;
                                });
                              },
                            ),
                            SizedBox(height: 16.0),
                            if (selectedSatuan != null) ...[
                              Text(
                                "ID Satuan: ",
                                style: TextStyle(fontSize: 15),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text("${selectedSatuan!['_id']}"),
                                      IconButton(
                                        icon: Icon(Icons.copy,
                                            color: Colors.blue),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: selectedSatuan!['_id']!));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    "Satuan ID copied to clipboard")),
                                          );
                                        },
                                      )
                                    ],
                                  )
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Nama Satuan: ${selectedSatuan!['nama_satuan']}",
                                style: TextStyle(fontSize: 15),
                              ),
                              SizedBox(height: 10),
                              selectedSatuan!['exp_date'] != null
                                  ? Text(
                                      "Expire Date: ${formatToWIBDetail(selectedSatuan!['exp_date'].toString())}",
                                      style: TextStyle(fontSize: 15),
                                    )
                                  : Text("Expire Date: No Expire Date",
                                      style: TextStyle(fontSize: 15)),
                              SizedBox(height: 10),
                              Text(
                                "Jumlah Stock Satuan: ${selectedSatuan!['jumlah_satuan']}",
                                style: TextStyle(fontSize: 15),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Harga Satuan: Rp.${NumberFormat('#,###.00', 'id_ID').format(selectedSatuan!['harga_satuan'] ?? 0.0)}",
                                style: TextStyle(fontSize: 15),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              selectedSatuan!['last_insert_date'] != null
                                  ? Text(
                                      "Last Modified: ${formatToWIBDetail(selectedSatuan!['exp_date'].toString())}",
                                      style: TextStyle(fontSize: 15),
                                    )
                                  : Text("Last Modified: No Date Registered",
                                      style: TextStyle(fontSize: 15)),
                            ],
                            Spacer(),
                            ElevatedButton(
                              onPressed: _isEditUser
                                  ? () {
                                      _showUpdateBarangDialog();
                                    }
                                  : null,
                              child: Text(
                                'Update Barang',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tambah Barang',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Tooltip(
                          message: 'See Supplier History',
                          child: IconButton(
                              icon: Icon(Icons.history, color: Colors.white),
                              onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            HistorySupplierPage()),
                                  )),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: nama_barang,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nama Barang',
                        prefixIcon: Icon(Icons.label),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Kategori Barang:"),
                        SizedBox(width: 20),
                        Expanded(
                          child: FutureBuilder<Map<String, String>>(
                            future: getmapkategori(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: SizedBox(
                                    width:
                                        24, // Adjust size of CircularProgressIndicator
                                    height: 24,
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (snapshot.hasData &&
                                  snapshot.data != null) {
                                var entries = snapshot.data!.entries.toList();
                                if (entries.isEmpty) {
                                  return Text('No Kategori Available');
                                }
                                if (selectedvalueKategori == null ||
                                    !entries.any((entry) =>
                                        entry.key == selectedvalueKategori)) {
                                  selectedvalueKategori = entries.first.key;
                                }
                                return DropdownButton<String>(
                                  value: selectedvalueKategori,
                                  isExpanded: true,
                                  items: entries
                                      .map((entry) => DropdownMenuItem(
                                            child: Text(entry.value),
                                            value: entry.key,
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    final selectedEntry = entries.firstWhere(
                                        (entry) => entry.key == value,
                                        orElse: () => MapEntry('', ''));
                                    if (selectedEntry.key.isNotEmpty) {
                                      setState(() {
                                        selectedvalueKategori = value;
                                        katakategori = selectedEntry.value;
                                      });
                                    }
                                  },
                                );
                              } else {
                                return Text('No data available');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: ElevatedButton(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 16),
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                showTambahJenisKategoriDialog(context);
                              },
                              child: Text(
                                "Tambah Kategori Dan Jenis",
                                style: TextStyle(color: Colors.white),
                              )),
                        )),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('Expiration Date:'),
                      value: isExp,
                      onChanged: (bool value) {
                        setState(() {
                          isExp = value;
                        });
                      },
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Upload Gambar Barang:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        selectedImage != null
                            ? Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                  image: DecorationImage(
                                    image: FileImage(File(selectedImage!.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Center(
                                  child: Text('No Image'),
                                ),
                              ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: pickImage,
                          icon: Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Pilih Gambar",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 16),
                    Text(
                      "Masukkan informasi satuan terkecil untuk barang diatas!",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: nama_satuan_initial,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Field tidak boleh kosong';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nama Satuan',
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: harga_satuan_initial,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harga Barang tidak boleh kosong';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Harga Barang per Satuan',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Center(
                      child: FilledButton(
                        onPressed: () async {
                          int base_number = 1;
                          addbarang(
                              isExp,
                              nama_barang.text,
                              katakategori,
                              nama_satuan_initial.text,
                              "0",
                              base_number.toString(),
                              harga_satuan_initial.text,
                              context,
                              selectedImage);
                          await fetchDataAndUseInJsonString();
                          await getlowstocksatuan(context);
                          await loadSuppliers();
                          await _loadExpiringBatches();
                          await fetchBarangStock();
                          setState(() {
                            fetchData();
                            onBarangRefresh();
                            isExp = false;
                            nama_barang.text = "";
                            nama_satuan_initial.text = "";
                            harga_satuan_initial.text = "";
                            id_supplier_insert.text = "";
                            selectedImage = null;
                          });
                        },
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Simpan',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 1400,
            height: 850,
            padding: EdgeInsets.all(16), // Add padding around the container
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  12), // Rounded corners for a modern look
              color: Colors.black, // Background color
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // Adds a slight shadow effect
                ),
              ],
            ),
            //untuk konversi satuan
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar for Barang
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Konversi Satuan",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),

                  SizedBox(
                    height: 10,
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: barangdata,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Show loading indicator
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No barang available');
                      } else {
                        final barangList = snapshot.data!;

                        // Filtered list based on search query
                        final filteredBarangList = barangList
                            .where((barang) => barang["nama_barang"]
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase()))
                            .toList();

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: "Search Barang",
                                      hintStyle: TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: Icon(Icons.search),
                                    ),
                                    onChanged: (query) {
                                      setState(() {
                                        searchQuery = query;
                                      });
                                    },
                                  ),
                                ),

                                SizedBox(
                                    width:
                                        8), // Add some spacing between search bar and icon

                                // Tooltip button
                                Tooltip(
                                  message: "View Conversion History",
                                  child: IconButton(
                                    icon: const Icon(Icons.history),
                                    onPressed: () {
                                      final getstorage = GetStorage();
                                      final idCabang = getstorage
                                              .read('id_cabang') ??
                                          ''; // Retrieve id_cabang from storage

                                      if (idCabang.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ConversionHistoryScreen(
                                                    idCabang: idCabang),
                                          ),
                                        );
                                      } else {
                                        // Handle case where id_cabang is not set
                                        print("id_cabang not found in storage");
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 10),
                            // Display search results
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                itemCount: filteredBarangList.length,
                                itemBuilder: (context, index) {
                                  final barang = filteredBarangList[index];
                                  return ListTile(
                                    title: Text(barang["nama_barang"]),
                                    onTap: () {
                                      onBarangSelected(barang);
                                      setState(() {
                                        searchQuery = barang["nama_barang"];
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  // Display Satuan Data
                  if (selectedBarang != null) ...[
                    Text(
                      "Available Satuan for ${selectedBarang?['nama_barang'] ?? ''}",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    // Conversion Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 'From' Satuan Column
                        Expanded(
                          child: Column(
                            children: [
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: selectedSatuanFrom,
                                items: konversi_satuanList.map((satuan) {
                                  return DropdownMenuItem(
                                    value: satuan,
                                    child: Text(satuan["nama_satuan"] ?? ""),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    onSatuanFromSelected(newValue);
                                    ConversionRate = 0;
                                  }
                                },
                              ),
                              // Stock information and other details
                              if (selectedSatuanFrom != null) ...[
                                SizedBox(height: 8),
                                Text(
                                    "Price: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(selectedSatuanFrom!['harga_satuan'])}"),
                                Text(
                                    "Amount: ${selectedSatuanFrom!['jumlah_satuan']}"),
                              ] else
                                SizedBox(height: 24),
                            ],
                          ),
                        ),

                        // Arrow Icon
                        Column(
                          children: [
                            Container(
                              width: 100,
                              child: Icon(Icons.arrow_forward, size: 50),
                            ),
                            Text("Conversion Rate"),
                            ConversionRate == 0
                                ? Text("0")
                                : Text(ConversionRate.toString()),
                          ],
                        ),

                        // 'To' Satuan Column
                        Expanded(
                          child: Column(
                            children: [
                              DropdownButton<Map<String, dynamic>>(
                                value: selectedSatuanTo,
                                hint: Text("To Satuan"),
                                isExpanded:
                                    true, // Makes the dropdown take full width
                                items: konversi_satuanTo.map((satuan) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: satuan,
                                    child: Text(satuan["nama_satuan"]),
                                  );
                                }).toList(),
                                onChanged: (satuan) async {
                                  hierarchysatuan =
                                      await fetchConversionByTarget(
                                          selectedBarang!['_id'],
                                          selectedSatuanFrom!['_id'],
                                          satuan!['_id']);
                                  setState(() {
                                    stockAmount = 0;
                                    selectedSatuanTo = satuan;
                                    ConversionRate =
                                        hierarchysatuan!['conversionRate'];
                                    amountkonversifrom.text = "0";
                                    amountkonversito.text =
                                        (stockAmount * ConversionRate)
                                            .toString();
                                  });
                                },
                              ),
                              // Stock information and other details
                              if (selectedSatuanTo != null) ...[
                                SizedBox(height: 8),
                                Text(
                                    "Price: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(selectedSatuanTo!['harga_satuan'])}"),
                                Text(
                                    "Amount: ${selectedSatuanTo!['jumlah_satuan']}"),
                              ] else
                                SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    selectedSatuanFrom != null && selectedSatuanTo != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  // Minus button
                                  IconButton(
                                    icon:
                                        Icon(Icons.remove, color: Colors.white),
                                    onPressed: () {
                                      if (stockAmount > 0) {
                                        setState(() {
                                          stockAmount--;
                                          amountkonversifrom.text =
                                              stockAmount.toString();
                                          amountkonversito.text =
                                              (stockAmount * ConversionRate)
                                                  .toString();
                                        });
                                      }
                                    },
                                  ),
                                  // Left editable TextField
                                  Container(
                                    width: 100,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: TextField(
                                      controller: amountkonversifrom,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: 'Amount',
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                        filled: true,
                                        fillColor: Colors.grey[800],
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onSubmitted: (value) {
                                        int? parsedValue = int.tryParse(value);
                                        if (parsedValue != null &&
                                            (parsedValue < 1 ||
                                                parsedValue >
                                                    selectedSatuanFrom![
                                                        "jumlah_satuan"])) {
                                          setState(() {
                                            amountkonversifrom.text =
                                                stockAmount.toString();
                                            amountkonversito.text =
                                                (stockAmount * ConversionRate)
                                                    .toString();
                                          });
                                          showToast(
                                              context, "Input Tidak Valid!");
                                        } else {
                                          setState(() {
                                            stockAmount = parsedValue!;
                                            amountkonversifrom.text =
                                                stockAmount.toString();
                                            amountkonversito.text =
                                                (stockAmount * ConversionRate)
                                                    .toString();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  // Plus button
                                  IconButton(
                                    icon: Icon(Icons.add, color: Colors.white),
                                    onPressed: () {
                                      if ((stockAmount + 1) <=
                                          selectedSatuanFrom![
                                              "jumlah_satuan"]) {
                                        setState(() {
                                          stockAmount++;
                                          amountkonversifrom.text =
                                              stockAmount.toString();
                                          amountkonversito.text =
                                              (stockAmount * ConversionRate)
                                                  .toString();
                                        });
                                      } else {
                                        showToast(
                                            context, "Input Mencapai Batas!");
                                      }
                                    },
                                  ),
                                ],
                              ),

                              // Right uneditable TextField
                              Container(
                                width: 100, // Set a fixed width for consistency
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: TextField(
                                    textAlign: TextAlign.center,
                                    readOnly:
                                        true, // Make this field uneditable
                                    decoration: InputDecoration(
                                      hintText: 'Result',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                    controller: amountkonversito),
                              ),
                            ],
                          )
                        : Text("pilih satuan terlebih dahulu"),
                    SizedBox(
                      height: 50,
                    ),
                    // Convert Button
                    ElevatedButton(
                      onPressed: (selectedSatuanFrom != null &&
                              selectedSatuanTo != null &&
                              selectedSatuanFrom! != selectedSatuanTo!)
                          ? () {
                              onConvert(
                                selectedBarang!['_id'].toString(),
                                selectedSatuanFrom!['_id'],
                                selectedSatuanTo!['_id'],
                              );

                              setState(() {
                                selectedBarang = null;
                                selectedSatuanFrom = null;
                                selectedSatuanTo = null;
                                stockAmount = 0;
                                amountkonversifrom.text =
                                    stockAmount.toString();
                                ConversionRate = 0;
                              });
                            }
                          : null,
                      child: Text("Convert"),
                    ),
                  ] else
                    Text(
                        "No satuan available. Please select a barang to view satuan options."),
                ],
              ),
            ),
          ),
          Container(
            width: 1400,
            height: 850,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Search bar for searching items in the gudang
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tambah Satuan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          FilledButton(
                              onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            AddHierarchyPage()),
                                  ),
                              child: Text("Manage Hierarchy Satuan"))
                        ],
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: _updateSearchResults,
                        decoration: InputDecoration(
                          hintText: 'Cari nama barang...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 12),
                      SingleChildScrollView(
                        child: Container(
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset:
                                    Offset(0, 3), // Adds a slight shadow effect
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  _searchResults[index]['nama_barang'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () async {
                                  _searchController.text = _searchResults[index]
                                          ['nama_barang']
                                      .toString();

                                  setState(() {
                                    satuan_idbarang =
                                        _searchResults[index]['_id'].toString();
                                    base_satuan_id = _searchResults[index]
                                            ['base_satuan_id']
                                        .toString();
                                  });
                                  if (satuan_idbarang.isNotEmpty &&
                                      base_satuan_id.isNotEmpty) {
                                    // Call the function to fetch satuan data
                                    Map<String, dynamic>? satuanData =
                                        await getSatuanById(satuan_idbarang,
                                            base_satuan_id, context);

                                    if (satuanData != null) {
                                      setState(() {
                                        nama_satuan_initial_spc =
                                            "X ${satuanData['nama_satuan']}";
                                      });
                                      print(
                                          'Satuan data retrieved: $satuanData');
                                    } else {
                                      print('Failed to retrieve satuan data');
                                    }
                                  } else {
                                    showToast(context,
                                        'Invalid satuan ID or barang ID');
                                  }
                                },
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildTextFormField(
                    controller: nama_satuan,
                    labelText: 'Nama Satuan',
                  ),
                  SizedBox(height: 12),
                  _buildTextFormField(
                    controller: harga_satuan,
                    labelText: 'Harga Barang per Satuan',
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: isi_satuan,
                          labelText: 'Kuantitas per Satuan',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text(nama_satuan_initial_spc)
                    ],
                  ),

                  Spacer(),
                  FilledButton(
                    onPressed: () async {
                      final itemData = await searchItemByID(satuan_idbarang);
                      if (itemData != null) {
                        // Extract base_satuan_id from the item data
                        String baseSatuanId = itemData['base_satuan_id'];
                        double conversionRate =
                            double.parse(isi_satuan.text.toString());
                        String id_satuan = await addsatuan(
                            satuan_idbarang,
                            nama_satuan.text,
                            harga_satuan.text.toString(),
                            isi_satuan.text.toString(),
                            context);
                        if (id_satuan != "") {
                          final conversionResponse = await insertConversion(
                            sourceSatuanId: id_satuan,
                            targetSatuanId: baseSatuanId,
                            conversionRate: conversionRate,
                          );

                          if (conversionResponse['success']) {
                            print('Conversion added successfully!');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Conversion berhasil ditambahkan')),
                            );
                          } else {
                            print(
                                'Failed to add conversion: ${conversionResponse['message']}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Gagal menambahkan konversi')),
                            );
                          }
                        }
                      } else {
                        print('Item not found or error occurred');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Barang tidak ditemukan atau terjadi kesalahan')),
                        );
                      }
                      setState(() {
                        nama_satuan.text = "";
                        harga_satuan.text = "";
                        isi_satuan.text = "";
                        nama_satuan_initial_spc = "No Satuan";
                        getlowstocksatuan(context);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Tambah Satuan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              // Stock Alert Section (Left Side) with FutureBuilder
              Expanded(
                flex: 5,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: getlowstocksatuan(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      final stockAlertData = snapshot.data ?? [];
                      return Container(
                        color: Colors.grey[900],
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stock Alert Title
                            Text(
                              'Stock Alert',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Scrollable Table for Stock Alert
                            Expanded(
                              child: stockAlertData.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No low stock available',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints:
                                              BoxConstraints(minWidth: 600),
                                          child: Table(
                                            border: TableBorder.all(),
                                            columnWidths: {
                                              0: FlexColumnWidth(2),
                                              1: FlexColumnWidth(2),
                                              2: FlexColumnWidth(1),
                                            },
                                            children: [
                                              TableRow(
                                                decoration: BoxDecoration(
                                                    color: Colors.blue[300]),
                                                children: [
                                                  TableCell(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Nama Barang',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                  TableCell(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Nama Satuan',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                  TableCell(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Jumlah Stok',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              ...stockAlertData.map((data) {
                                                return TableRow(
                                                  children: [
                                                    TableCell(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          data['nama_barang'],
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          data['nama_satuan'],
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          data['jumlah_satuan']
                                                              .toString(),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                            ),

                            SizedBox(height: 16),

                            // Expiration Alert Title
                            Text(
                              'Expiration Alert',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Scrollable Table for Expiration Alert
                            Expanded(
                              child: FutureBuilder<List<Map<String, dynamic>>>(
                                future: fetchExpiringBatches(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Error: ${snapshot.error}',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No expiration item within 30 days',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  } else {
                                    final expiringBatches = snapshot.data!;
                                    return SingleChildScrollView(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints:
                                              BoxConstraints(minWidth: 600),
                                          child: Table(
                                            border: TableBorder.all(),
                                            columnWidths: {
                                              0: FlexColumnWidth(2),
                                              1: FlexColumnWidth(2),
                                              2: FlexColumnWidth(1),
                                              3: FlexColumnWidth(1),
                                            },
                                            children: [
                                              TableRow(
                                                decoration: BoxDecoration(
                                                    color: Colors.blue[300]),
                                                children: [
                                                  TableCell(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Nama Barang',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                  TableCell(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Nama Satuan',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                  TableCell(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Tanggal Kadaluarsa',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                  TableCell(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Jumlah Stok',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              ...expiringBatches.map((batch) {
                                                return TableRow(
                                                  children: [
                                                    TableCell(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          batch['barang_nama'] ??
                                                              '',
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          batch['satuan_nama'] ??
                                                              '',
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          batch['tanggal_exp'] !=
                                                                  null
                                                              ? DateFormat(
                                                                      'yyyy-MM-dd')
                                                                  .format(DateTime
                                                                      .parse(batch[
                                                                          'tanggal_exp']))
                                                              : '',
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          batch['jumlah_stok']
                                                                  ?.toString() ??
                                                              '',
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
              // Re-stock Section (Right Side)
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.black87,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Re-stock Section',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Tooltip(
                            message: 'See Supplier History',
                            child: IconButton(
                                icon: Icon(Icons.history, color: Colors.white),
                                onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              HistorySupplierPage()),
                                    )),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      // Input fields for re-stocking items
                      DropdownButton<Map<String, dynamic>>(
                        value: selectedSupplierData.isEmpty
                            ? null
                            : selectedSupplierData,
                        hint: Text('Select Supplier'),
                        items: suppliers.map((supplier) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: supplier,
                            child: Text(supplier['nama_supplier'] ??
                                'No Name'), // Display supplier name
                          );
                        }).toList(),
                        onChanged: (selected) {
                          if (selected != null) {
                            onSupplierSelected(
                                selected); // Update the selected supplier and their details
                          }
                        },
                      ),
                      TextField(
                        controller: ReStock_InvoiceNumber,
                        decoration: InputDecoration(
                          labelText: 'Enter Invoice Number ',
                          labelStyle: TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Re-Stock Item List',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      ElevatedButton(
                        onPressed: _addItem,
                        child: Text('Tambah Barang'),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: itemsStock.length,
                          itemBuilder: (context, index) {
                            final item = itemsStock[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Barang Selection
                                  TypeAheadField<Map<String, dynamic>>(
                                    suggestionsCallback: (pattern) async {
                                      return barangListStock
                                          .where((barang) =>
                                              barang['nama_barang']
                                                  .toLowerCase()
                                                  .contains(
                                                      pattern.toLowerCase()))
                                          .toList();
                                    },
                                    itemBuilder: (context, suggestion) {
                                      return ListTile(
                                        title: Text(suggestion['nama_barang']),
                                      );
                                    },
                                    onSelected: (selectedBarang) {
                                      onBarangSelectedStock(
                                          index, selectedBarang);
                                    },
                                    builder: (context, controller, focusNode) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Search Barang',
                                          border: OutlineInputBorder(),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 8),

                                  // Display Selected Barang
                                  if (item['selectedBarang'] != null)
                                    Text(
                                      "Selected Barang: ${item['selectedBarang']['nama_barang']}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  SizedBox(height: 8),

                                  // Satuan Dropdown
                                  DropdownButtonFormField<Map<String, dynamic>>(
                                    value: item['selectedSatuan'],
                                    items: item['satuanList']
                                        .map<
                                                DropdownMenuItem<
                                                    Map<String, dynamic>>>(
                                            (satuan) => DropdownMenuItem<
                                                    Map<String, dynamic>>(
                                                  value: satuan,
                                                  child: Text(
                                                      satuan['nama_satuan'] ??
                                                          'Unknown'),
                                                ))
                                        .toList(),
                                    onChanged: (newSatuan) {
                                      setState(() {
                                        item['selectedSatuan'] = newSatuan;
                                        item['ID_satuan'] = newSatuan?['_id'];
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Select Satuan',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  SizedBox(height: 8),

                                  // Jumlah Input
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Jumlah',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _updateItem(index, 'jumlah',
                                          int.tryParse(value) ?? 0);
                                    },
                                  ),
                                  SizedBox(height: 8),

                                  // Tanggal Kedaluwarsa
                                  itemsStock[index]['selectedBarang'] != null &&
                                          itemsStock[index]['selectedBarang']
                                                  ['isKadaluarsa'] ==
                                              true
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    "Pilih Tanggal Kedaluwarsa:",
                                                    style:
                                                        TextStyle(fontSize: 14),
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          8), // Spasi kecil antara teks
                                                  Text(
                                                    itemsStock[index]
                                                                ['exp_date'] !=
                                                            null
                                                        ? DateFormat(
                                                                'yyyy-MM-dd HH:mm')
                                                            .format(itemsStock[
                                                                    index]
                                                                ['exp_date'])
                                                        : "-",
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.calendar_today,
                                                  color: Colors.blue),
                                              onPressed: () async {
                                                // Step 1: Show the date picker
                                                final selectedDate =
                                                    await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime(2100),
                                                );

                                                if (selectedDate != null) {
                                                  // Step 2: Show the time picker
                                                  final selectedTime =
                                                      await showTimePicker(
                                                    context: context,
                                                    initialTime:
                                                        TimeOfDay.now(),
                                                  );

                                                  if (selectedTime != null) {
                                                    // Step 3: Combine the date and time
                                                    DateTime combinedDateTime =
                                                        DateTime(
                                                      selectedDate.year,
                                                      selectedDate.month,
                                                      selectedDate.day,
                                                      selectedTime.hour,
                                                      selectedTime.minute,
                                                    );

                                                    // Update the `exp_date` field
                                                    _updateItem(
                                                        index,
                                                        'exp_date',
                                                        combinedDateTime);
                                                    setState(() {});
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        )
                                      : SizedBox(),
                                  SizedBox(height: 8),
                                  // Delete Item Button
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        itemsStock.removeAt(index);
                                      });
                                    },
                                  ),
                                  Divider(color: Colors.grey),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (ReStock_InvoiceNumber.text.isNotEmpty &&
                              itemsStock.length != 0) {
                            updateMultipleItems(itemsStock, selectedSupplierId,
                                ReStock_InvoiceNumber.text, 'tambah', context);
                            await getlowstocksatuan(context);
                            setState(() {
                              itemsStock.clear();
                              ReStock_InvoiceNumber.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          textStyle: TextStyle(color: Colors.white),
                        ),
                        child: Text(
                          'Submit Re-stock',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            color: Colors.black,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supplier Information Section
                  Text(
                    'Insert Supplier Information',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Nama Supplier
                  TextFormField(
                    controller: _supplierNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Supplier',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Kontak Supplier
                  TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: 'Kontak Supplier',
                      labelStyle:
                          TextStyle(color: Colors.white), // Label color white
                      filled: true,
                      fillColor: Colors.black, // Fill color black
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.white), // Border color white
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.blueAccent,
                            width: 2), // Border color blue on focus
                      ),
                      // Label color blue on focus
                    ),
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  SizedBox(height: 16),

                  // Alamat Supplier
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Alamat Supplier',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (_supplierNameController.text.isNotEmpty &&
                          _contactController.text.isNotEmpty &&
                          _addressController.text.isNotEmpty) {
                        _saveSupplier();
                        _supplierNameController.clear();
                        _contactController.clear();
                        _addressController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Informasi Supplier dan Barang disimpan')),
                        );
                        setState(() {});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Text Tidak Boleh Kosong, Insert Gagal!')),
                        );
                      }
                    },
                    child: Text('Simpan Informasi Supplier dan Barang'),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.blue,
            child: Center(
              child: DefaultTabController(
                length: 2,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text("Mutasi Barang"),
                    automaticallyImplyLeading: false,
                    bottom: TabBar(
                      tabs: [
                        Tab(text: "Request Transfer"),
                        Tab(text: "Confirm Transfer"),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      // First Tab: Request Transfer
                      RequestTransferTab(),
                      // Second Tab: Confirm Transfer
                      ConfirmTransferTab(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            child: Center(),
          )
        ],
      ),
    );
  }

  //get update barang pop up widget
  void _showUpdateBarangDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UpdateBarangDialog(
          barangId: temp_id_update, // Pass the ID of the barang to be updated
          onUpdated: () {
            setState(() {
              edit_nama_barang.text = "";
              _isEditUser = false;
              temp_id_update = "";
              onBarangRefresh();
            });
          },
        );
      },
    );
  }

  void confirmDeletion(BuildContext context, String id_barang, String id_satuan,
      String nama_satuan, String nama_barang) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi hapus'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Apakah anda ingin menghapus satuan "$nama_satuan" pada item "$nama_barang"?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await deletesatuan(id_barang, id_satuan, context);
                setState(() {
                  getlowstocksatuan(context);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //tambah satuan text widget
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Field tidak boleh kosong';
        }
        return null;
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelText: labelText,
        labelStyle: TextStyle(fontSize: 16),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ]
          : null,
    );
  }
}

//update pop up
class UpdateBarangDialog extends StatefulWidget {
  final String barangId;
  final Function onUpdated;

  UpdateBarangDialog({required this.barangId, required this.onUpdated});

  @override
  _UpdateBarangDialogState createState() => _UpdateBarangDialogState();
}

class _UpdateBarangDialogState extends State<UpdateBarangDialog> {
  final TextEditingController namaBarangController = TextEditingController();
  final TextEditingController jenisBarangController = TextEditingController();
  final TextEditingController kategoriBarangController =
      TextEditingController();
  bool isInsertDateEnabled = false;
  bool isExpDateEnabled = false;
  DateTime? selectedInsertDate;
  DateTime? selectedExpDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Text('Update Barang',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                  controller: namaBarangController, label: 'Nama Barang'),
              SizedBox(height: 12),
              _buildTextField(
                  controller: jenisBarangController, label: 'Jenis Barang'),
              SizedBox(height: 12),
              _buildTextField(
                  controller: kategoriBarangController,
                  label: 'Kategori Barang'),
              SizedBox(height: 16),
              _buildDateCheckbox(
                label: 'Update Expiration Date',
                isChecked: isExpDateEnabled,
                onChanged: (value) {
                  setState(() {
                    isExpDateEnabled = value ?? false;
                  });
                },
                onDateSelected: (date) {
                  setState(() {
                    selectedExpDate = date;
                  });
                },
                selectedDate: selectedExpDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel',
              style: TextStyle(fontSize: 16, color: Colors.blue)),
        ),
        ElevatedButton(
          onPressed: () async {
            final String? namaBarang = namaBarangController.text.isNotEmpty
                ? namaBarangController.text
                : null;
            final String? jenisBarang = jenisBarangController.text.isNotEmpty
                ? jenisBarangController.text
                : null;
            final String? kategoriBarang =
                kategoriBarangController.text.isNotEmpty
                    ? kategoriBarangController.text
                    : null;
            final String? insertDate =
                isInsertDateEnabled && selectedInsertDate != null
                    ? selectedInsertDate!.toLocal().toString().split(' ')[0]
                    : null;
            final String? expDate = isExpDateEnabled && selectedExpDate != null
                ? selectedExpDate!.toLocal().toString().split(' ')[0]
                : null;

            UpdateBarang(
              widget.barangId,
              nama_barang: namaBarang,
              jenis_barang: jenisBarang,
              kategori_barang: kategoriBarang,
              insert_date: insertDate,
              exp_date: expDate,
            );

            widget.onUpdated();

            Navigator.of(context).pop();
          },
          child: Text('Update',
              style: TextStyle(fontSize: 16, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateUpdate(
      BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != DateTime.now()) {
      onDateSelected(pickedDate);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDateCheckbox({
    required String label,
    required bool isChecked,
    required void Function(bool?) onChanged,
    required void Function(DateTime) onDateSelected,
    DateTime? selectedDate,
  }) {
    return Row(
      children: [
        Checkbox(
          value: isChecked,
          onChanged: onChanged,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (isChecked) {
                _selectDateUpdate(context, onDateSelected);
              }
            },
            child: AbsorbPointer(
              absorbing: !isChecked,
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: selectedDate != null
                      ? '${selectedDate.toLocal()}'.split(' ')[0]
                      : 'Select Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RequestTransferTab extends StatefulWidget {
  RequestTransferTab({Key? key}) : super(key: key);
  @override
  _RequestTransferTabState createState() => _RequestTransferTabState();
}

class _RequestTransferTabState extends State<RequestTransferTab> {
  late Future<List<Map<String, dynamic>>> fetchDataRequest;
  List<Map<String, dynamic>> allData = [];
  List<Map<String, dynamic>> filteredData = [];
  String searchQuery = "";
  DateTimeRange? dateRange;

  @override
  void initState() {
    super.initState();
    fetchDataRequest = fetchData();
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      List<Map<String, dynamic>>? data = await getMutasiBarangByCabangRequest();
      setState(() {
        allData = data ?? [];
        filteredData = allData;
      });
      return data ?? [];
    } catch (e) {
      print('Error fetching data for request: $e');
      return [];
    }
  }

  void filterData() {
    setState(() {
      filteredData = allData.where((request) {
        final cabangId = request['id_cabang_request'].toLowerCase();
        final items = (request['Items'] as List)
            .map((item) => item['nama_item'].toLowerCase())
            .join(", ");
        final queryMatch = cabangId.contains(searchQuery.toLowerCase()) ||
            items.contains(searchQuery.toLowerCase());

        if (dateRange != null) {
          final requestDate = DateTime.parse(request['tanggal_request']);
          final inDateRange = requestDate.isAfter(dateRange!.start) &&
              requestDate.isBefore(dateRange!.end);
          return queryMatch && inDateRange;
        }
        return queryMatch;
      }).toList();
    });
  }

  void pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: dateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateRange = picked;
        filterData();
      });
    }
  }

  // Helper method to format date to WIB
  String formatToWIB(String dateTimeString) {
    try {
      DateTime utcTime = DateTime.parse(dateTimeString).toUtc();
      // Adjust to WIB (UTC+7)
      DateTime wibTime = utcTime.add(Duration(hours: 7));
      // Format the date
      return DateFormat('yyyy-MM-dd HH:mm').format(wibTime);
    } catch (e) {
      return "Invalid Date";
    }
  }

  // Function to get branch name from its ID
  Future<String> getNamaCabang(String idCabang) async {
    try {
      // Directly call the getCabangByID function here
      final cabangList = await getCabangByID(idCabang);
      if (cabangList != null && cabangList.isNotEmpty) {
        return cabangList.first['nama_cabang'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Error';
    }
  }

  // Function to get status color based on the status value
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'denied':
        return Colors.red;
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.yellow.shade700;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmitRequestScreen(),
                  ),
                );
              },
              child: Text("Ajukan Request"),
            ),
            SizedBox(height: 20),
            // Search bar and date picker row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Search by cabang or item name",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filterData();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickDateRange,
                      icon: Icon(Icons.calendar_today),
                      label: Text("Date Range"),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          searchQuery = "";
                          dateRange = null;
                          filteredData = allData;
                        });
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Colors.black,
                      ),
                      label: Text(
                        "Clear Filter",
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (dateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "From: ${DateFormat('yyyy-MM-dd').format(dateRange!.start)} To: ${DateFormat('yyyy-MM-dd').format(dateRange!.end)}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchDataRequest,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error fetching data."));
                  } else if (filteredData.isEmpty) {
                    return Center(child: Text("No requests found."));
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 1,
                      child: DataTable(
                        columnSpacing: 10.0,
                        columns: [
                          DataColumn(label: Text("Tanggal Request (WIB)")),
                          DataColumn(label: Text("Cabang")),
                          DataColumn(label: Text("Barang-Jumlah")),
                          DataColumn(label: Text("Status")),
                        ],
                        rows: filteredData.map((request) {
                          final String tanggalRequest =
                              formatToWIB(request['tanggal_request']);
                          final String cabangId = request['id_cabang_request'];
                          final String items = (request['Items'] as List)
                              .map((item) =>
                                  "${item['nama_item']}-${item['jumlah_item']} ${item['nama_satuan']}")
                              .join("\n");
                          final String status = request['status'];
                          return DataRow(cells: [
                            DataCell(Text(tanggalRequest)),
                            DataCell(
                              FutureBuilder<String>(
                                future: getNamaCabang(cabangId),
                                builder: (context, cabangSnapshot) {
                                  if (cabangSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text("Loading...");
                                  } else if (cabangSnapshot.hasError) {
                                    return Text("Error");
                                  }
                                  return Text(cabangSnapshot.data ?? "Unknown");
                                },
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: (request['Items'] as List)
                                    .map<Widget>((item) {
                                  return Text(
                                    "${item['nama_item']} (${item['jumlah_item']} ${item['nama_satuan']})",
                                  );
                                }).toList(),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (status == 'confirmed')
                                    IconButton(
                                      icon: Icon(Icons.picture_as_pdf),
                                      onPressed: () async {
                                        // Existing PDF generation logic
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmTransferTab extends StatefulWidget {
  ConfirmTransferTab({Key? key}) : super(key: key);

  @override
  _ConfirmTransferTabState createState() => _ConfirmTransferTabState();
}

class _ConfirmTransferTabState extends State<ConfirmTransferTab> {
  late Future<List<Map<String, dynamic>>> futureData;
  List<Map<String, dynamic>> allData = [];
  List<Map<String, dynamic>> filteredData = [];
  String searchKeyword = '';
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      List<Map<String, dynamic>>? data = await getMutasiBarangByCabangConfirm();
      allData = data ?? [];
      applyFilters(); // Apply filters after fetching the data
      return allData;
    } catch (e) {
      print('Error fetching data: $e');
      return []; // Return an empty list in case of an error
    }
  }

  String formatToWIB(String dateTimeString) {
    try {
      DateTime utcTime = DateTime.parse(dateTimeString).toUtc();
      DateTime wibTime = utcTime.add(Duration(hours: 7));
      return DateFormat('yyyy-MM-dd HH:mm').format(wibTime);
    } catch (e) {
      return "Invalid Date";
    }
  }

  Future<String> getNamaCabang(String idCabang) async {
    try {
      final cabangList = await getCabangByID(idCabang);
      if (cabangList != null && cabangList.isNotEmpty) {
        return cabangList.first['nama_cabang'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Error';
    }
  }

  // Apply the search and date filters
  void applyFilters() {
    setState(() {
      filteredData = allData.where((transfer) {
        bool matchesSearch = searchKeyword.isEmpty ||
            transfer['id_cabang_request']
                .toString()
                .toLowerCase()
                .contains(searchKeyword.toLowerCase()) ||
            (transfer['Items'] as List).any((item) =>
                item['nama_item']
                    .toString()
                    .toLowerCase()
                    .contains(searchKeyword.toLowerCase()) ||
                item['nama_satuan']
                    .toString()
                    .toLowerCase()
                    .contains(searchKeyword.toLowerCase()));

        bool matchesDateRange = true;
        if (startDate != null && endDate != null) {
          DateTime transferDate = DateTime.parse(transfer['tanggal_request'])
              .toUtc()
              .add(Duration(hours: 7)); // Adjust for WIB time zone
          matchesDateRange = transferDate.isAfter(startDate!) &&
              transferDate.isBefore(endDate!);
        }

        return matchesSearch && matchesDateRange;
      }).toList();
    });
  }

  //untuk konfirmasi tab bagian delivered status
  void showInfoDialog(BuildContext context, Map<String, dynamic> transfer) {
    final String requestTime = formatToWIB(transfer['tanggal_request']);
    final String confirmTime = transfer['tanggal_konfirmasi'] != null
        ? formatToWIB(transfer['tanggal_konfirmasi'])
        : 'Not Confirmed';
    final String deliveredTime = transfer['tanggal_diambil'] != null
        ? formatToWIB(transfer['tanggal_diambil'])
        : 'Not Delivered';
    final String kodeSJ = transfer['Kode_SJ'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delivery Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Waktu Request: $requestTime"),
              Text("Waktu Konfirmasi: $confirmTime"),
              Text("Waktu Diambil: $deliveredTime"),
              Text("Kode Surat Jalan: $kodeSJ"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Confirm Item Transfer",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Search Bar for Nama Barang, Cabang & Satuan
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchKeyword = value;
                        applyFilters(); // Apply the filter when search text changes
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Barang/Cabang/Satuan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now(), // Restrict to today as last date
                          initialDateRange: startDate != null && endDate != null
                              ? DateTimeRange(start: startDate!, end: endDate!)
                              : null,
                        );
                        if (picked != null &&
                            picked.start != null &&
                            picked.end != null) {
                          setState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                            applyFilters(); // Apply the filter when date range is selected
                          });
                        }
                      },
                      child: Row(
                        children: [Icon(Icons.date_range), Text("Date Filter")],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            searchKeyword = '';
                            startDate = null;
                            endDate = null;
                            applyFilters(); // Clear filters
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.clear,
                              color: Colors.black,
                            ),
                            Text(
                              "Clear Filter",
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        )),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),

            // Date Range Filter (with icon)
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .center, // This centers the content of the row
              children: [
                if (startDate != null && endDate != null)
                  Expanded(
                    child: Text(
                      "${DateFormat('yyyy-MM-dd').format(startDate!)} - ${DateFormat('yyyy-MM-dd').format(endDate!)}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign
                          .center, // This ensures the text itself is centered
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: futureData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error fetching data."));
                  } else if (!snapshot.hasData || filteredData.isEmpty) {
                    return Center(child: Text("No transfers to confirm."));
                  }

                  final List<Map<String, dynamic>> data = filteredData;

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context)
                              .size
                              .width, // Ensure it takes full width
                        ),
                        child: DataTable(
                          columnSpacing: 16.0,
                          columns: [
                            DataColumn(label: Text("Tanggal Request (WIB)")),
                            DataColumn(label: Text("Cabang")),
                            DataColumn(label: Text("Details (Items)")),
                            DataColumn(
                              label: Padding(
                                padding: EdgeInsets.only(left: 70),
                                child: Text("Action"),
                              ),
                            ),
                          ],
                          rows: data.map((transfer) {
                            print("Barang Mutasi: $transfer");
                            final String tanggalRequest =
                                formatToWIB(transfer['tanggal_request']);
                            final String cabang = transfer['id_cabang_request'];
                            final String id_mutasi = transfer['_id'];
                            final String status =
                                transfer['status']; // Get the status
                            final String items = (transfer['Items'] as List)
                                .map((item) =>
                                    "${item['nama_item']}-${item['jumlah_item']} ${item['nama_satuan']}")
                                .join("\n");

                            return DataRow(cells: [
                              DataCell(Text(tanggalRequest)),
                              DataCell(
                                FutureBuilder<String>(
                                  future: getNamaCabang(cabang),
                                  builder: (context, cabangSnapshot) {
                                    if (cabangSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text("Loading...");
                                    } else if (cabangSnapshot.hasError) {
                                      return Text("Error");
                                    }
                                    return Text(
                                        cabangSnapshot.data ?? "Unknown");
                                  },
                                ),
                              ),
                              DataCell(Text(items)),
                              DataCell(Row(
                                children: [
                                  if (status == 'pending')
                                    ElevatedButton(
                                      onPressed: () async {
                                        await updateStatusToConfirmed(
                                            id_mutasi);
                                        setState(() {}); // Refresh the UI
                                      },
                                      child: Text("Accept"),
                                    ),
                                  if (status == 'pending')
                                    ElevatedButton(
                                      onPressed: () async {
                                        await updateStatusToDenied(id_mutasi);
                                        setState(() {}); // Refresh the UI
                                      },
                                      child: Text("Decline"),
                                    ),
                                  if (status == 'confirmed')
                                    ElevatedButton(
                                      onPressed: () async {
                                        await updateStatusToDelivered(
                                            id_mutasi);
                                        await getlowstocksatuan(context);

                                        //tidak berfungsi harus dituang
                                        await fetchExpiringBatches();
                                      },
                                      child: Text("Konfirmasi Barang Diambil"),
                                    ),
                                  if (status == 'denied')
                                    Padding(
                                      padding: EdgeInsets.only(left: 70),
                                      child: Text("Denied",
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  if (status == 'delivered')
                                    Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 70),
                                          child: Text("Delivered",
                                              style: TextStyle(
                                                  color: Colors.green)),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.info_outline),
                                          onPressed: () =>
                                              showInfoDialog(context, transfer),
                                        ),
                                      ],
                                    ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
