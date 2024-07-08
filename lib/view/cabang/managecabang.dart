import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/loginpage/login_owner.dart';
import 'package:ta_pos/view/view-model-flutter/startup_controller.dart';
import 'package:ta_pos/view/view-model-flutter/gudang_controller.dart';
import 'package:ta_pos/view/view-model-flutter/cabang_controller.dart';

bool switchmode = false;

class managecabang extends StatefulWidget {
  const managecabang({super.key});

  @override
  State<managecabang> createState() => _managecabangState();
}

class _managecabangState extends State<managecabang> {
  List<Map<String, dynamic>> datacabang = [];

  @override
  void initState() {
    super.initState();
    fetchdatacabang();
  }

  Future<void> fetchdatacabang() async {
    try {
      List<Map<String, dynamic>> fetchedData = await getallcabang();
      setState(() {
        datacabang = fetchedData;
      });
    } catch (e) {
      print('fetch cabang error:$e');
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    TextEditingController nama_cabang = new TextEditingController();
    TextEditingController alamat_cabang = new TextEditingController();
    TextEditingController no_telp = new TextEditingController();
    TextEditingController alamat_gudang = new TextEditingController();
    TextEditingController email = TextEditingController();
    TextEditingController pass = TextEditingController();
    TextEditingController fname = TextEditingController();
    TextEditingController lname = TextEditingController();
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Daftar Cabang"),
        FutureBuilder(
            future: getallcabang(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final rows = snapshot.data!.map((map) {
                  return DataRow(cells: [
                    DataCell(
                      Text(map['nama_cabang'], style: TextStyle(fontSize: 15)),
                    ),
                    DataCell(
                        Text(map['alamat'], style: TextStyle(fontSize: 15))),
                    DataCell(
                        Text(map['no_telp'], style: TextStyle(fontSize: 15))),
                    DataCell(
                      Visibility(
                        visible: map['role'] != 'Manager',
                        child: ElevatedButton(
                          onPressed: () {
                            try {
                              setState(() {
                                deletecabang(map['_id'], context);
                                fetchdatacabang();
                                getallcabang();
                              });
                            } catch (e) {
                              print("gagal delete: $e");
                            }
                          },
                          child: Text('Delete'),
                        ),
                      ),
                    ),
                  ]);
                }).toList();

                return DataTable(
                  columns: const <DataColumn>[
                    DataColumn(
                        label: Text('Nama Cabang',
                            style: TextStyle(fontSize: 15))),
                    DataColumn(
                        label: Text('Alamat', style: TextStyle(fontSize: 15))),
                    DataColumn(
                        label: Text('No Telp', style: TextStyle(fontSize: 15))),
                    DataColumn(
                        label: Text('Hapus Cabang',
                            style: TextStyle(fontSize: 15))),
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
            }),
        switchmode
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Text(
                        "Buat Akun Manager",
                      )),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 25),
                      border: UnderlineInputBorder(),
                      labelText: 'Enter Email',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 25),
                      border: UnderlineInputBorder(),
                      labelText: 'Enter Password',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: fname,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 25),
                      border: UnderlineInputBorder(),
                      labelText: 'Enter First Name',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: lname,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 25),
                      border: UnderlineInputBorder(),
                      labelText: 'Enter Last Name',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: FilledButton(
                      onPressed: () {
                        tambahmanager_Owner(email.text, pass.text, fname.text,
                            lname.text, context);
                        final dataStorage = GetStorage();
                        setState(() {
                          email.text = "";
                          pass.text = "";
                          fname.text = "";
                          lname.text = "";
                          if (dataStorage.read('switchmode')) {
                            switchmode = dataStorage.read('switchmode');
                          }
                        });
                      },
                      child: Text("Selesai"),
                    ),
                  )
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tambah Cabang Baru"),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: nama_cabang,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 25),
                      border: UnderlineInputBorder(),
                      labelText: 'Enter Nama Cabang',
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: alamat_cabang,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 25),
                      border: UnderlineInputBorder(),
                      labelText: 'Enter alamat Cabang',
                    ),
                  ),
                  TextFormField(
                    controller: no_telp,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 25),
                      border: UnderlineInputBorder(),
                      labelText: 'Enter Nomor Telepon Cabang',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Text("Input Informasi Gudang"),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: alamat_gudang,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 25),
                      border: UnderlineInputBorder(),
                      labelText: 'Enter Alamat Gudang',
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: FilledButton(
                        onPressed: () {
                          nambahcabangngudang_Owner(
                              nama_cabang.text,
                              alamat_cabang.text,
                              no_telp.text,
                              alamat_gudang.text,
                              context);
                          final dataStorage = GetStorage();
                          setState(() {
                            alamat_cabang.text = "";
                            no_telp.text = "";
                            alamat_gudang.text = "";
                            nama_cabang.text = "";
                            if (dataStorage.read('switchmode')) {
                              switchmode = dataStorage.read('switchmode');
                            }
                          });
                        },
                        child: Text("Submit")),
                  ),
                  Text(
                      "Pastikan data benar karena saat menekan tombol, data akan langsung tersimpan!",
                      style: TextStyle(color: Colors.red)),
                  SizedBox(
                    height: 30,
                  ),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: FilledButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => login_owner()));
                            },
                            child: Icon(
                              Icons.logout_rounded,
                              color: Colors.black,
                              size: 25,
                            )),
                      ))
                ],
              ),
      ],
    ));
  }
}
