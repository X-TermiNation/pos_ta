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
  TextEditingController harga_satuan = TextEditingController();
  TextEditingController nama_kategori = TextEditingController();
  TextEditingController nama_jenis = TextEditingController();
  TextEditingController edit_nama_barang = TextEditingController();
  TextEditingController edit_harga_barang = TextEditingController();
  TextEditingController edit_jumlah_barang = TextEditingController();
  TextEditingController edit_nama_kategori = TextEditingController();
  TextEditingController nama_satuan = TextEditingController();
  TextEditingController jumlah_satuan = TextEditingController();
  TextEditingController isi_satuan = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _dataList = [];
  String _jsonString = '';

  //get kategori dan jenis untuk combo box
  void fetchData() async {
    try {
      edit_selectedvalueKategori = await getFirstKategoriId();
      selectedvalueJenis = await getFirstJenisId();
      selectedvalueKategori = await getFirstKategoriId();
      var barangdata = await getBarang(id_gudangs);
      // if (selectedvalueJenis.isEmpty) {
      //   selectedvalueJenis = "";
      //   if (selectedvalueKategori.isEmpty) {
      //     selectedvalueKategori = "";
      //     edit_selectedvalueKategori = "";
      //   }
      // }

      print(
          "data jenis dan kategori pertama:$selectedvalueJenis dan $selectedvalueKategori");
    } catch (error) {
      print('Error fetchdata kategori dan jenis: $error');
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
      body: ResponsiveHeader(
        containers: [
          Container(
            width: 1500,
            height: 750,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      width: 950,
                      height: 650,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 0.1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                barangdata = Future.delayed(
                                    Duration(seconds: 1),
                                    () => getBarang(id_gudangs));
                              });
                            },
                            child: Text(
                              "Daftar Barang",
                              // Your text properties here
                            ),
                          ),
                          SizedBox(
                            height: 100,
                          ),
                          FutureBuilder(
                              future: barangdata,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator(); // Show loading indicator while waiting for data
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else if (!snapshot.hasData ||
                                    snapshot.data == null) {
                                  return Text('No data available');
                                } else {
                                  final List<Map<String, dynamic>>? data =
                                      snapshot.data;
                                  if (data == null) {
                                    return Text('No data available');
                                  }
                                  if (snapshot.hasData) {
                                    final rows = snapshot.data!.map((map) {
                                      print(map);
                                      return DataRow(cells: [
                                        DataCell(
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                barangdata = Future.delayed(
                                                    Duration(seconds: 1),
                                                    () =>
                                                        getBarang(id_gudangs));
                                              });
                                              edit_nama_barang.text =
                                                  map['nama_barang'];
                                              edit_harga_barang.text =
                                                  map['harga_barang']
                                                      .toString();
                                              edit_jumlah_barang.text =
                                                  map['Qty'].toString();
                                              _isEditUser = true;
                                              temp_id_update = map['_id'];
                                            },
                                            child: Text(map['nama_barang'],
                                                style: TextStyle(fontSize: 15)),
                                          ),
                                        ),
                                        DataCell(Text(
                                          '${map['jenis_barang']} / ${map['kategori_barang']}',
                                          style: TextStyle(fontSize: 15),
                                        )),
                                        DataCell(
                                          Text(
                                            map['exp_date'] != null
                                                ? map['exp_date']
                                                    .toString()
                                                    .substring(0, 10)
                                                : "-",
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ),
                                        DataCell(Text(
                                          map['insert_date'] != null
                                              ? map['insert_date']
                                                  .toString()
                                                  .substring(0, 10)
                                              : "-",
                                          style: TextStyle(fontSize: 15),
                                        )),
                                        DataCell(
                                          ElevatedButton(
                                            onPressed: () {
                                              deletebarang(map['_id']);
                                              setState(() {
                                                barangdata = Future.delayed(
                                                    Duration(seconds: 1),
                                                    () =>
                                                        getBarang(id_gudangs));
                                              });
                                            },
                                            child: Text('Delete'),
                                          ),
                                        ),
                                      ]);
                                    }).toList();
                                    return DataTable(
                                      columns: const <DataColumn>[
                                        DataColumn(
                                            label: Text('Nama Barang',
                                                style:
                                                    TextStyle(fontSize: 15))),
                                        DataColumn(
                                            label: Text('Jenis/Kategori',
                                                style:
                                                    TextStyle(fontSize: 15))),
                                        DataColumn(
                                            label: Text('Exp Date',
                                                style:
                                                    TextStyle(fontSize: 15))),
                                        DataColumn(
                                            label: Text('Insert Date',
                                                style:
                                                    TextStyle(fontSize: 15))),
                                        DataColumn(
                                            label: Text('Hapus Barang',
                                                style:
                                                    TextStyle(fontSize: 15))),
                                      ],
                                      rows: rows,
                                    );
                                  } else if (snapshot.hasError) {
                                    // Show an error message.
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    // Show a loading indicator.
                                    return CircularProgressIndicator();
                                  }
                                }
                              }),
                        ],
                      )),
                  Container(
                    width: 550.0,
                    height: 650.0,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 0.1,
                      ),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Update Barang"),
                        SizedBox(height: 20.0),
                        TextFormField(
                          controller: edit_nama_barang,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                          decoration:
                              InputDecoration(labelText: 'Edit Nama Barang'),
                        ),
                        SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Kategori Barang:"),
                            FutureBuilder<Map<String, String>>(
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

                                  var items = entries
                                      .map((entry) => DropdownMenuItem<String>(
                                            child: Text(entry.value),
                                            value: entry.key,
                                          ))
                                      .toList();

                                  // Ensure edit_selectedvalueKategori is valid
                                  if (edit_selectedvalueKategori == null ||
                                      !snapshot.data!.containsKey(
                                          edit_selectedvalueKategori)) {
                                    edit_selectedvalueKategori =
                                        entries.first.key;
                                  }

                                  return DropdownButton<String>(
                                    value: edit_selectedvalueKategori,
                                    items: items,
                                    onChanged: (value) {
                                      if (value != null) {
                                        final selectedEntry =
                                            snapshot.data?.entries.firstWhere(
                                          (entry) => entry.key == value,
                                        );
                                        if (selectedEntry != null) {
                                          setState(() {
                                            edit_selectedvalueKategori = value;
                                            Edit_katakategori =
                                                selectedEntry.value;
                                          });
                                        }
                                      }
                                    },
                                  );
                                } else {
                                  return Text('No data available');
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: edit_harga_barang,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Harga Barang tidak boleh kosong';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            labelText: 'Edit Harga Barang',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: edit_jumlah_barang,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Jumlah barang tidak boleh kosong';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            labelText: 'Edit Jumlah Barang',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        SizedBox(height: 32.0),
                        ElevatedButton(
                            onPressed: _isEditUser
                                ? () {
                                    UpdateBarang(
                                        temp_id_update,
                                        edit_nama_barang.text,
                                        Edit_katakategori,
                                        edit_harga_barang.text,
                                        edit_jumlah_barang.text);
                                    setState(() {
                                      edit_nama_barang.text = "";
                                      edit_harga_barang.text = "";
                                      edit_jumlah_barang.text = "";
                                      _isEditUser = false;
                                      temp_id_update = "";
                                      barangdata = Future.delayed(
                                          Duration(seconds: 1),
                                          () => getBarang(id_gudangs));
                                    });
                                  }
                                : null,
                            child: Text('Update Barang')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  TextFormField(
                    controller: nama_barang,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Nama Barang',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kategori Barang:"),
                      SizedBox(
                        width: 20,
                      ),
                      FutureBuilder<Map<String, String>>(
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
                    ],
                  ),
                  Text(
                    'Selected Date:',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    //ini value date nya
                    _dateFormat.format(selectedDate),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
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
                          SizedBox(height: 10),
                        ],
                      ),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today),
                              SizedBox(width: 8),
                              Text('Select Date'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 200,
                  ),
                  FilledButton(
                    onPressed: () async {
                      String formattedDateString =
                          _dateFormat.format(selectedDate);
                      DateTime insertedDate =
                          _dateFormat.parse(formattedDateString);
                      addbarang(insertedDate, noExp, nama_barang.text,
                          katakategori, context);
                      nama_kategori.text = "";
                      setState(() {
                        fetchData();
                        noExp = false;
                        nama_barang.text = "";
                        barangdata = Future.delayed(
                            Duration(seconds: 1), () => getBarang(id_gudangs));
                      });
                    },
                    child: Text('Tambah Barang'),
                  )
                ],
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
                    ),
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
                      });
                    },
                    child: Text("Tambah Satuan"),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.blue,
            child: Center(
              child: Text('Mutasi Barang'),
            ),
          ),
          Container(
            height: 800,
            color: Colors.white,
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
