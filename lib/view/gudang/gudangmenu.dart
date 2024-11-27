import 'package:flutter/material.dart';
import 'package:ta_pos/view/gudang/StockHistory.dart';
import 'package:ta_pos/view/gudang/SupplierHistory.dart';
import 'package:ta_pos/view/gudang/responsive_header.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
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
bool noExp = false;
String satuan_idbarang = "";
String base_satuan_id = "";
String nama_satuan_initial_spc = "No Satuan";
final dataStorage = GetStorage();
String id_gudangs = dataStorage.read('id_gudang');
var barangdata =
    Future.delayed(Duration(seconds: 1), () => getBarang(id_gudangs));

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
  TextEditingController edit_nama_barang = TextEditingController();
  TextEditingController edit_expdate_barang = TextEditingController();
  TextEditingController edit_insertdate_barang = TextEditingController();
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
      var data = await getBarang(id_gudangs);
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
      setState(() {
        itemsStock[index]['satuanList'] = List<Map<String, dynamic>>.from(data);
        itemsStock[index]['selectedSatuan'] =
            itemsStock[index]['satuanList'].isNotEmpty
                ? itemsStock[index]['satuanList'][0]
                : null;
        itemsStock[index]['ID_satuan'] =
            itemsStock[index]['selectedSatuan']?['_id'];
      });
    } catch (e) {
      showToast(context, 'Failed to fetch satuan data: $e');
    }
  }

  //konversi barang
  Map<String, dynamic>? selectedBarang;
  List<Map<String, dynamic>> konversi_satuanList = [];
  List<Map<String, dynamic>> konversi_basesatuan = [];
  String konversisearchQuery = "";
  Map<String, dynamic>? selectedSatuanFrom;
  Map<String, dynamic>? selectedSatuanTo;
  int jumlah_tambah = 0;
  int jumlah_kurang = 0;
  int stockAmount = 0;
  TextEditingController amountkonversifrom = TextEditingController();
  TextEditingController amountkonversito = TextEditingController();
  //
  void onBarangSelected(Map<String, dynamic> barang) async {
    konversi_satuanList = await getsatuan(barang["_id"].toString(), context);
    final satuan = await getSatuanById(
        barang["_id"].toString(), barang["base_satuan_id"].toString(), context);

    if (satuan != null) {
      konversi_basesatuan = [satuan]; // Wrap the result in a list
    } else {
      konversi_basesatuan = []; // Default to an empty list
    }
    setState(() {
      selectedBarang = barang;
      selectedSatuanFrom = null;
      selectedSatuanTo = null;
      stockAmount = 0;
      amountkonversifrom.text = stockAmount.toString();
    });
  }

  //untuk tombol konversi(masih dalam proses)
  void onConvert(String id_barang, String id_satuanFrom, String id_satuanTo) {
    num increase = stockAmount * selectedSatuanFrom!['isi_satuan'];
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
    getFirstKategoriId().then((value) => edit_selectedvalueKategori);
    getKategori();
    fetchData();
    getdatagudang();
    fetchDataAndUseInJsonString();
    fetchDataKategori();
    getlowstocksatuan(context);
    fetchBarangStock();
    loadSuppliers();
    print("id gudangnya:$id_gudangs");
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

  //datepicker tambah barang
  DateTime selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
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

      updatejumlahSatuan(
          idBarang, idSatuan, jumlahSatuan, kodeAktivitas, action, context);
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
    print("Supplier Data: $supplierData");
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
                                              data = snapshot.data;
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
                                              map['insert_date']
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
                                                      edit_expdate_barang.text =
                                                          map['exp_date']
                                                              .toString();
                                                      edit_insertdate_barang
                                                              .text =
                                                          map['insert_date']
                                                              .toString();
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
                                                map['exp_date'] != null
                                                    ? map['exp_date']
                                                        .toString()
                                                        .substring(0, 10)
                                                    : "-",
                                                style: TextStyle(fontSize: 16),
                                              )),
                                              DataCell(Text(
                                                map['insert_date'] != null
                                                    ? map['insert_date']
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
                                                      barangdata =
                                                          Future.delayed(
                                                              Duration(
                                                                  seconds: 1),
                                                              () => getBarang(
                                                                  id_gudangs));
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
                                                      label: Text('Exp Date')),
                                                  DataColumn(
                                                      label:
                                                          Text('Insert Date')),
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
                              style: TextStyle(fontSize: 18),
                            ),
                            Row(
                              children: [
                                Text(
                                  "$detailbarang_ID",
                                  style: TextStyle(fontSize: 18),
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
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              "Jenis/Kategori Barang: ${edit_nama_kategorijenis.text}",
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              "Expire Date: ${edit_expdate_barang.text.isNotEmpty && edit_expdate_barang.text.length >= 10 ? edit_expdate_barang.text.substring(0, 10) : "-"}",
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              "Insert Date : ${edit_insertdate_barang.text.isNotEmpty ? edit_insertdate_barang.text.substring(0, 10) : "-"}",
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 20.0),
                            Text(
                              "Satuan:",
                              style: TextStyle(fontSize: 18),
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
                                style: TextStyle(fontSize: 18),
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
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Jumlah Stock Satuan: ${selectedSatuan!['jumlah_satuan']}",
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Harga Satuan: Rp.${NumberFormat('#,###.00', 'id_ID').format(selectedSatuan!['harga_satuan'] ?? 0.0)}",
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Isi Satuan : ${selectedSatuan!['isi_satuan']}",
                                style: TextStyle(fontSize: 18),
                              ),
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
                          'Daftar Barang',
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
                                return CircularProgressIndicator();
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
                    SizedBox(height: 8),
                    Text(
                      'Selected Date:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _dateFormat.format(selectedDate),
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No Expiration Date'),
                            Checkbox(
                              value: noExp,
                              onChanged: (bool? value) {
                                setState(() {
                                  noExp = value ?? false;
                                  print(noExp);
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(width: 20),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blueAccent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Colors.blueAccent),
                                SizedBox(width: 8),
                                Text(
                                  'Select Date',
                                  style: TextStyle(color: Colors.blueAccent),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                          String formattedDateString =
                              _dateFormat.format(selectedDate);
                          DateTime insertedDate =
                              _dateFormat.parse(formattedDateString);
                          int base_number = 1;
                          addbarang(
                              insertedDate,
                              noExp,
                              nama_barang.text,
                              katakategori,
                              nama_satuan_initial.text,
                              "0",
                              base_number.toString(),
                              harga_satuan_initial.text,
                              context,
                              selectedImage);
                          setState(() {
                            barangdata = Future.delayed(Duration(seconds: 1),
                                () => getBarang(id_gudangs));
                            fetchDataAndUseInJsonString();
                            fetchData();
                            noExp = false;
                            nama_barang.text = "";
                            nama_satuan_initial.text = "";
                            harga_satuan_initial.text = "";
                            id_supplier_insert.text = "";
                            selectedImage = null;
                            fetchBarangStock();
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
                              DropdownButton<Map<String, dynamic>>(
                                value: selectedSatuanFrom,
                                hint: Text("From Satuan"),
                                isExpanded:
                                    true, // Makes the dropdown take full width
                                items: konversi_satuanList
                                    .where((satuan) =>
                                        satuan["_id"] !=
                                        selectedBarang!["base_satuan_id"])
                                    .map((satuan) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: satuan,
                                    child: Text(satuan["nama_satuan"]),
                                  );
                                }).toList(),
                                onChanged: (satuan) {
                                  setState(() {
                                    stockAmount = 0;
                                    amountkonversifrom.text =
                                        stockAmount.toString();
                                    selectedSatuanFrom = satuan;
                                  });
                                },
                              ),
                              // Stock information and other details
                              if (selectedSatuanFrom != null) ...[
                                SizedBox(height: 8),
                                Text(
                                    "Price: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(selectedSatuanFrom!['harga_satuan'])}"),
                                Text(
                                    "Amount: ${selectedSatuanFrom!['jumlah_satuan']}"),
                                Text(
                                    "Count: ${selectedSatuanFrom!['isi_satuan']}"),
                              ] else
                                SizedBox(height: 24),
                            ],
                          ),
                        ),

                        // Arrow Icon
                        Container(
                          width: 100,
                          child: Icon(Icons.arrow_forward, size: 50),
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
                                items: konversi_basesatuan.map((satuan) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: satuan,
                                    child: Text(satuan["nama_satuan"]),
                                  );
                                }).toList(),
                                onChanged: (satuan) {
                                  setState(() {
                                    stockAmount = 0;
                                    selectedSatuanTo = satuan;
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
                                Text(
                                    "Count: ${selectedSatuanTo!['isi_satuan']}"),
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
                                          amountkonversito.text = (stockAmount *
                                                  selectedSatuanFrom![
                                                      "isi_satuan"])
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
                                                (stockAmount *
                                                        selectedSatuanFrom![
                                                            "isi_satuan"])
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
                                                (stockAmount *
                                                        selectedSatuanFrom![
                                                            "isi_satuan"])
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
                                          amountkonversito.text = (stockAmount *
                                                  selectedSatuanFrom![
                                                      "isi_satuan"])
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
                                  selectedSatuanTo!['_id']);

                              setState(() {
                                selectedBarang = null;
                                selectedSatuanFrom = null;
                                selectedSatuanTo = null;
                                stockAmount = 0;
                                amountkonversifrom.text =
                                    stockAmount.toString();
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
                      Text(
                        "Tambah Satuan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                              String expDate =
                                  _searchResults[index]['exp_date'] != null
                                      ? _searchResults[index]['exp_date']
                                          .toString()
                                          .substring(0, 10)
                                      : "-";
                              return ListTile(
                                title: Text(
                                  _searchResults[index]['nama_barang'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('Expire Date: $expDate'),
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
                    onPressed: () {
                      addsatuan(
                          satuan_idbarang,
                          nama_satuan.text,
                          harga_satuan.text.toString(),
                          isi_satuan.text.toString(),
                          context);
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
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No low stock satuan found'));
                    } else {
                      return Container(
                        color: Colors.grey[900],
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(
                                  child: Text(
                                    'Stock Alert',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Table(
                              border: TableBorder.all(),
                              columnWidths: {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(2),
                                2: FlexColumnWidth(1),
                                3: FlexColumnWidth(1),
                                4: FlexColumnWidth(1),
                              },
                              children: [
                                TableRow(
                                  decoration:
                                      BoxDecoration(color: Colors.blue[300]),
                                  children: [
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          'Nama Barang',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          'Nama Satuan',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          'Jumlah Stok',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    // TableCell(
                                    //   child: Padding(
                                    //     padding: EdgeInsets.all(8.0),
                                    //     child: Text(
                                    //       'Re-Stock',
                                    //       style: TextStyle(
                                    //           fontWeight: FontWeight.bold),
                                    //     ),
                                    //   ),
                                    // ),
                                    // TableCell(
                                    //   child: Padding(
                                    //     padding: EdgeInsets.all(8.0),
                                    //     child: Text(
                                    //       'Delete',
                                    //       style: TextStyle(
                                    //           fontWeight: FontWeight.bold),
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                                ...snapshot.data!.map((data) {
                                  return TableRow(
                                    children: [
                                      TableCell(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(data['nama_barang']),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(data['nama_satuan']),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                              data['jumlah_satuan'].toString()),
                                        ),
                                      ),
                                      // TableCell(
                                      //   child: Padding(
                                      //     padding: EdgeInsets.all(8.0),
                                      //     child: ElevatedButton(
                                      //       onPressed: () {
                                      //         showQuantityDialog(
                                      //           data['id_barang'].toString(),
                                      //           data['id_satuan'].toString(),
                                      //           context,
                                      //         );
                                      //         setState(() {});
                                      //       },
                                      //       style: ElevatedButton.styleFrom(
                                      //         backgroundColor: Colors.purple,
                                      //         textStyle: TextStyle(
                                      //             color: Colors.white),
                                      //       ),
                                      //       child: Text(
                                      //         'Re-Stock',
                                      //         style: TextStyle(
                                      //           fontSize: 12,
                                      //           color: Colors.black,
                                      //           fontWeight: FontWeight.bold,
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ),
                                      // ),
                                      // TableCell(
                                      //   child: Padding(
                                      //     padding: EdgeInsets.all(8.0),
                                      //     child: ElevatedButton(
                                      //       onPressed: () {
                                      //         confirmDeletion(
                                      //           context,
                                      //           data['id_barang'].toString(),
                                      //           data['id_satuan'].toString(),
                                      //           data['nama_satuan'],
                                      //           data['nama_barang'],
                                      //         );
                                      //       },
                                      //       style: ElevatedButton.styleFrom(
                                      //         backgroundColor: Colors.purple,
                                      //         textStyle: TextStyle(
                                      //             color: Colors.white),
                                      //       ),
                                      //       child: Text(
                                      //         'Delete',
                                      //         style: TextStyle(
                                      //           fontSize: 12,
                                      //           color: Colors.black,
                                      //           fontWeight: FontWeight.bold,
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
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
                                    items: item['satuanList'].map<
                                        DropdownMenuItem<Map<String, dynamic>>>(
                                      (satuan) {
                                        return DropdownMenuItem<
                                            Map<String, dynamic>>(
                                          value: satuan,
                                          child: Text(satuan['nama_satuan'] ??
                                              'Unknown'),
                                        );
                                      },
                                    ).toList(),
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
                        onPressed: () {
                          if (ReStock_InvoiceNumber.text.isNotEmpty &&
                              itemsStock.length != 0) {
                            updateMultipleItems(itemsStock, selectedSupplierId,
                                ReStock_InvoiceNumber.text, 'tambah', context);
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
                    onPressed: () {
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
              edit_expdate_barang.text = "";
              edit_insertdate_barang.text = "";
              _isEditUser = false;
              temp_id_update = "";
              barangdata = Future.delayed(
                  Duration(seconds: 1), () => getBarang(id_gudangs));
            });
          },
        );
      },
    );
  }

  void showQuantityDialog(
      String id_barang, String id_satuan, BuildContext context) {
    int quantity = 1;

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Quantity'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Quantity:'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (quantity > 1) {
                              quantity--;
                            }
                          });
                        },
                      ),
                      Text(quantity.toString()),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: id_supplier_stock_alert,
                    decoration: InputDecoration(
                      labelText: 'ID Supplier Stock',
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
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (id_supplier_stock_alert.text.isNotEmpty) {
                            // Handle the confirm action
                            final kodeAktivitas = generateKodeAktivitas(
                                id_supplier_stock_alert.text, 'MSK');
                            updatejumlahSatuan(id_barang, id_satuan, quantity,
                                kodeAktivitas, "tambah", context);
                            await getlowstocksatuan(context);
                            Navigator.of(context).pop();
                            setState(() {});
                          } else {
                            CustomToast(
                                message: "ID Supplier tidak boleh kosong");
                          }
                        },
                        child: Text('Confirm Stock'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
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

class RequestTransferTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Request Item Transfer",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: "Document Title",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: "Transfer Details",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Handle file upload logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Document uploaded successfully")),
              );
            },
            child: Text("Upload Document"),
          ),
          Spacer(),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Handle submit logic here
              },
              child: Text("Submit Request"),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfirmTransferTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Confirm Item Transfer",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // TODO: Replace with dynamic data count
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text("Request #${index + 1}"),
                    subtitle: Text("Request details for item transfer."),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Accept logic here
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GiveItemScreen(),
                          ),
                        );
                      },
                      child: Text("Accept"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GiveItemScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Give Item for Transfer"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Transfer Item Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Handle transfer logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Item transfer initiated")),
                );
              },
              child: Text("Initiate Transfer"),
            ),
          ],
        ),
      ),
    );
  }
}
