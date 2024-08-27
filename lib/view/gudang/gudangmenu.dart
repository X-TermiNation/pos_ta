import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ta_pos/view/gudang/responsive_header.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view/view-model-flutter/gudang_controller.dart';
import 'package:ta_pos/view/loginpage/login.dart';

String? selectedvalueJenis = "";
String? selectedvalueKategori = "";
String katakategori = "";
String Edit_katakategori = "";
bool _isEditUser = false;
late String? edit_selectedvalueKategori;
//untuk update barang
String temp_id_update = "";
bool noExp = false;
String satuan_idbarang = "";
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
  TextEditingController jumlah_satuan = TextEditingController();
  TextEditingController isi_satuan = TextEditingController();
  TextEditingController nama_satuan_initial = TextEditingController();
  TextEditingController harga_satuan_initial = TextEditingController();
  TextEditingController jumlah_satuan_initial = TextEditingController();
  TextEditingController isi_satuan_initial = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  TextEditingController _searchControllerBarangList = TextEditingController();
  String searchQuery = '';
  List<Map<String, dynamic>> _dataList = [];
  List<Map<String, dynamic>> satuanList = [];
  Map<String, dynamic>? selectedSatuan;
  String _jsonString = '';

  //get kategori dan jenis untuk combo box
  void fetchData() async {
    try {
      edit_selectedvalueKategori = await getFirstKategoriId();
      selectedvalueJenis = await getFirstJenisId();
      selectedvalueKategori = await getFirstKategoriId();
      // var barangdata = await getBarang(id_gudangs);
      // if (selectedvalueJenis.isEmpty) {
      //   selectedvalueJenis = "";
      //   if (selectedvalueKategori.isEmpty) {
      //     selectedvalueKategori = "";
      //     edit_selectedvalueKategori = "";
      //   }
      // }

      print(
          "data jenis dan kategori pertama: $selectedvalueJenis dan $selectedvalueKategori");
    } catch (error) {
      print('Error fetchdata kategori dan jenis: $error');
    }
  }

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

      // Ubah data menjadi format JSON dan masukkan ke dalam string jsonString
      String jsonString = json.encode(data);
      setState(() {
        _jsonString = jsonString;
        _dataList = List<Map<String, dynamic>>.from(json.decode(_jsonString));
      });
      // Sekarang, Anda dapat menggunakan jsonString sesuai kebutuhan
      print('JSON String: $jsonString');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getFirstKategoriId().then((value) => edit_selectedvalueKategori);
    fetchData();
    getdatagudang();
    fetchDataAndUseInJsonString();
    fetchDataKategori();
    getlowstocksatuan(context);
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

  //datepicker
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
                    flex: 2,
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
                          Text(
                            "Daftar Barang",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                            child: FutureBuilder(
                              future: barangdata,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                } else if (!snapshot.hasData ||
                                    snapshot.data == null) {
                                  return Center(
                                    child: Text('No data available'),
                                  );
                                } else {
                                  final List<Map<String, dynamic>>? data =
                                      snapshot.data;
                                  if (data == null) {
                                    return Center(
                                      child: Text('No data available'),
                                    );
                                  }

                                  // Filter the data based on the search query
                                  final filteredData = data.where((map) {
                                    final namaBarang =
                                        map['nama_barang']?.toLowerCase() ?? '';
                                    return namaBarang.contains(searchQuery);
                                  }).toList();

                                  if (filteredData.isEmpty) {
                                    return Center(
                                      child: Text('No items match your search'),
                                    );
                                  }

                                  final rows = filteredData.map((map) {
                                    return DataRow(cells: [
                                      DataCell(
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              barangdata = Future.delayed(
                                                  Duration(seconds: 1),
                                                  () => getBarang(id_gudangs));
                                            });
                                            edit_nama_barang.text =
                                                map['nama_barang'];
                                            String jenisBarang =
                                                map['jenis_barang'];
                                            String kategoriBarang =
                                                map['kategori_barang'];
                                            edit_nama_kategorijenis.text =
                                                "$jenisBarang / $kategoriBarang";
                                            edit_expdate_barang.text =
                                                map['exp_date'].toString();
                                            edit_insertdate_barang.text =
                                                map['insert_date'].toString();
                                            _isEditUser = true;
                                            temp_id_update = map['_id'];
                                            fetchsatuandetail();
                                          },
                                          child: Text(
                                            map['nama_barang'],
                                            style: TextStyle(fontSize: 16),
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
                                              barangdata = Future.delayed(
                                                  Duration(seconds: 1),
                                                  () => getBarang(id_gudangs));
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
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
                                    child: DataTable(
                                      columns: const <DataColumn>[
                                        DataColumn(
                                          label: Text('Nama Barang',
                                              style: TextStyle(fontSize: 16)),
                                        ),
                                        DataColumn(
                                          label: Text('Jenis/Kategori',
                                              style: TextStyle(fontSize: 16)),
                                        ),
                                        DataColumn(
                                          label: Text('Exp Date',
                                              style: TextStyle(fontSize: 16)),
                                        ),
                                        DataColumn(
                                          label: Text('Insert Date',
                                              style: TextStyle(fontSize: 16)),
                                        ),
                                        DataColumn(
                                          label: Text('Hapus Barang',
                                              style: TextStyle(fontSize: 16)),
                                        ),
                                      ],
                                      rows: rows,
                                    ),
                                  );
                                }
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
                    flex: 1,
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
                            "Expire Date: ${edit_expdate_barang.text != null && edit_expdate_barang.text.length >= 10 ? edit_expdate_barang.text.substring(0, 10) : "-"}",
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            "Insert Date : ${edit_insertdate_barang.text.isNotEmpty ? edit_insertdate_barang.text.toString().substring(0, 10) : "-"}",
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
                                child: Text(satuan['nama_satuan'] ?? 'No Name'),
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
                                    //belum diubah dari mongoose
                                    // UpdateBarang(
                                    //     temp_id_update,
                                    //     edit_nama_barang.text,
                                    //     Edit_katakategori,
                                    //     edit_expdate_barang.text,
                                    //     edit_jumlah_barang.text);
                                    setState(() {
                                      edit_nama_barang.text = "";
                                      edit_expdate_barang.text = "";
                                      edit_insertdate_barang.text = "";
                                      _isEditUser = false;
                                      temp_id_update = "";
                                      barangdata = Future.delayed(
                                          Duration(seconds: 1),
                                          () => getBarang(id_gudangs));
                                    });
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
                      ),
                    ),
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
                    Center(
                      child: Text(
                        "Tambah Barang",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
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
                                  return Text('No items available');
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
                    Divider(),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        "Satuan Barang",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
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
                        labelText: 'Harga Barang',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: jumlah_satuan_initial,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Field tidak boleh kosong';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Stok Satuan Barang',
                        prefixIcon: Icon(Icons.storage),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: isi_satuan_initial,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Isi satuan tidak boleh kosong';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Kuantitas per satuan',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: FilledButton(
                        onPressed: () async {
                          String formattedDateString =
                              _dateFormat.format(selectedDate);
                          DateTime insertedDate =
                              _dateFormat.parse(formattedDateString);
                          addbarang(
                              insertedDate,
                              noExp,
                              nama_barang.text,
                              katakategori,
                              nama_satuan_initial.text,
                              jumlah_satuan_initial.text,
                              isi_satuan_initial.text,
                              harga_satuan_initial.text,
                              context);
                          nama_kategori.text = "";
                          setState(() {
                            fetchData();
                            noExp = false;
                            nama_barang.text = "";
                            nama_satuan_initial.text = "";
                            jumlah_satuan_initial.text = "";
                            harga_satuan_initial.text = "";
                            isi_satuan_initial.text = "";
                            barangdata = Future.delayed(Duration(seconds: 1),
                                () => getBarang(id_gudangs));
                            fetchDataAndUseInJsonString();
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
                          'Tambah Barang',
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
            child: Center(
                child: Column(
              children: [
                SizedBox(
                  width: 100,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 700,
                      height: 650,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Tambah Jenis"),
                          SizedBox(
                            height: 100,
                          ),
                          TextFormField(
                            controller: nama_jenis,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Field tidak boleh kosong';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: 'Nama Jenis',
                            ),
                          ),
                          SizedBox(
                            height: 100,
                          ),
                          //search bar untuk barang
                          SizedBox(
                            height: 200,
                          ),
                          FilledButton(
                            onPressed: () {
                              addjenis(nama_jenis.text, context);
                              nama_jenis.text = "";
                              setState(() {
                                fetchData();
                                getJenis();
                              });
                            },
                            child: Text("Tambah Jenis"),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 650,
                      width: 700,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Tambah Kategori"),
                          SizedBox(
                            height: 100,
                          ),
                          TextFormField(
                            controller: nama_kategori,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Field tidak boleh kosong';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: 'Nama Kategori',
                            ),
                          ),
                          SizedBox(
                            height: 100,
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
                                  return Text('No items available');
                                }

                                // Ensure selectedvalueJenis is valid
                                if (selectedvalueJenis == null ||
                                    !entries.any((entry) =>
                                        entry.key == selectedvalueJenis)) {
                                  selectedvalueJenis = entries.first.key;
                                }

                                return DropdownButton<String>(
                                  value: selectedvalueJenis,
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
                          SizedBox(
                            height: 200,
                          ),
                          FilledButton(
                            onPressed: () {
                              addkategori(nama_kategori.text,
                                  selectedvalueJenis.toString(), context);
                              nama_kategori.text = "";
                              setState(() {
                                fetchData();
                                getKategori();
                              });
                            },
                            child: Text("Tambah Kategori"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            )),
          ),
          Container(
            width: 1400,
            height: 650,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //disini isi search bar untuk barang yang ada di gudang
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _updateSearchResults,
                        decoration: InputDecoration(
                          hintText: 'Cari nama barang...',
                        ),
                      ),
                      SingleChildScrollView(
                        child: Container(
                          height: 100,
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
                                title:
                                    Text(_searchResults[index]['nama_barang']),
                                subtitle: Text('Expire Date: $expDate'),
                                onTap: () {
                                  _searchController.text = _searchResults[index]
                                          ['nama_barang']
                                      .toString();
                                  setState(() {
                                    satuan_idbarang =
                                        _searchResults[index]['_id'].toString();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: nama_satuan,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Field tidak boleh kosong';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Nama Satuan',
                    ),
                  ),
                  TextFormField(
                    controller: harga_satuan,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga Barang tidak boleh kosong';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Harga Barang',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  TextFormField(
                    controller: jumlah_satuan,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Field tidak boleh kosong';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Stok Satuan Barang',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  TextFormField(
                    controller: isi_satuan,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Isi satuan tidak boleh kosong';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Kuantitas per satuan',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  SizedBox(
                    height: 200,
                  ),
                  FilledButton(
                    onPressed: () {
                      addsatuan(
                          satuan_idbarang,
                          nama_satuan.text,
                          jumlah_satuan.text.toString(),
                          harga_satuan.text.toString(),
                          isi_satuan.text.toString(),
                          context);
                      setState(() {
                        nama_satuan.text = "";
                        jumlah_satuan.text = "";
                        harga_satuan.text = "";
                        isi_satuan.text = "";
                        getlowstocksatuan(context);
                      });
                    },
                    child: Text("Tambah Satuan"),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          'Stock Alert',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
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
                            decoration: BoxDecoration(color: Colors.grey[300]),
                            children: [
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Nama Barang',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Nama Satuan',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Jumlah Stok',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Re-Stock',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
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
                                    child:
                                        Text(data['jumlah_satuan'].toString()),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        showQuantityDialog(
                                            data['id_barang'].toString(),
                                            data['id_satuan'].toString(),
                                            context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        textStyle:
                                            TextStyle(color: Colors.white),
                                      ),
                                      child: Text(
                                        'Re-Stock',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        confirmDeletion(
                                            context,
                                            data['id_barang'].toString(),
                                            data['id_satuan'].toString(),
                                            data['nama_satuan'],
                                            data['nama_barang']);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        textStyle:
                                            TextStyle(color: Colors.white),
                                      ),
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
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
          Container(
            color: Colors.blue,
            child: Center(
              child: Text('Mutasi Barang'),
            ),
          ),
          Container(
            height: 750,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  showConfirmationDialog(context);
                },
                child: Text('Log Out'),
              ),
            ),
          )
        ],
      ),
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
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Handle the confirm action
                          updatejumlahSatuan(id_barang, id_satuan, quantity,
                              "tambah", context);
                          Navigator.of(context).pop();
                          setState(() {});
                          // Close the dialog
                        },
                        child: Text('Confirm Stock'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
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
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await deletesatuan(id_barang, id_satuan, context);
                setState(() {
                  getlowstocksatuan(context);
                }); // Execute the delete operation
                Navigator.of(context).pop();
                // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Out'),
          content: Text('Anda Ingin Log Out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                GetStorage().erase();
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => loginscreen()));
                // Close the dialog
              },
              child: Text('Ya'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Tidak'),
            ),
          ],
        );
      },
    );
  }
}
