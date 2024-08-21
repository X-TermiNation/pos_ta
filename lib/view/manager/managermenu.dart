import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:ta_pos/view/view-model-flutter/user_controller.dart';
import 'package:ta_pos/view/view-model-flutter/diskon_controller.dart';
import 'package:ta_pos/view/gudang/gudangmenu.dart';
import 'package:ta_pos/view/cabang/managecabang.dart';
import 'package:ta_pos/view/manager/CustomTab.dart';
import 'package:ta_pos/view/manager/content_view.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/loginpage/login.dart';

List<Map<String, dynamic>> _dataList = [];
var diskondata = Future.delayed(Duration(seconds: 1), () => getDiskon());
late bool logOwner;

bool key1 = true;
bool key2 = true;
bool key3 = true;
bool key4 = true;
bool bigScreen = false;

class ManagerMenu extends StatefulWidget {
  const ManagerMenu({super.key});

  @override
  State<ManagerMenu> createState() => _ManagerMenuState();
}

class _ManagerMenuState extends State<ManagerMenu>
    with SingleTickerProviderStateMixin {
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  TextEditingController fname = TextEditingController();
  TextEditingController lname = TextEditingController();
  TextEditingController edit_fname = TextEditingController();
  TextEditingController edit_lname = TextEditingController();
  TextEditingController nama_diskon = TextEditingController();
  TextEditingController persentase_diskon = TextEditingController();
  List<Map<String, dynamic>> userlist = [];

  void fetchDiskon() {
    diskondata = Future.delayed(Duration(seconds: 1), () => getDiskon());
  }

  void fetchUser() async {
    this.userlist = await getUsers();
  }

  var scaffoldKey = GlobalKey<ScaffoldState>();
  //frontend stuff
  late TabController tabController = TabController(length: 8, vsync: this);
  late double screenHeight;
  late double screenWidth;
  late double topPadding;
  late double bottomPadding;
  bool isHomeExpanded = false;
  bool isPegawaiExpanded = false;
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  //check boolean
  bool _isValidEmail = false;
  bool _isEditUser = false;
  String diskon_idbarang = "";
  String temp_id_update = "";
  String value = 'Kasir';
  String value2 = 'Kasir';
  final roles = ['Kasir', 'Admin Gudang', 'Kurir'];

//untuk diskon barang
  List<bool> isCheckedList = [];
//diskon check
  List<Map<String, dynamic>> databarang = [];

  bool _validateEmail(String email) {
    RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  List<ContentView> contentView = [
    ContentView(
      tab: CustomTab(title: 'Home'),
      content: Container(),
    ),
    ContentView(
      tab: CustomTab(title: 'Daftar Diskon'),
      content: Container(),
    ),
    ContentView(
      tab: CustomTab(title: 'Edit Diskon'),
      content: Container(),
    ),
    ContentView(
      tab: CustomTab(title: 'Stock Alert'),
      content: Container(),
    ),
    ContentView(
      tab: CustomTab(title: 'Analisa Revenue'),
      content: Container(),
    ),
    ContentView(tab: CustomTab(title: 'Analisa Pendapatan'), content: Center()),
    ContentView(tab: CustomTab(title: 'Grafik Trend'), content: Center()),
    ContentView(
        tab: CustomTab(title: 'Laporan'),
        content: Center(
          child: Container(color: Colors.green, width: 100, height: 100),
        )),
    ContentView(
        tab: CustomTab(title: 'Mutasi Barang'),
        content: Center(
          child: Container(color: Colors.blue, width: 100, height: 100),
        )),
    ContentView(
        tab: CustomTab(title: 'Atur Pegawai'),
        content: Center(
          child: Container(color: Colors.green, width: 100, height: 100),
        )),
    ContentView(
        tab: CustomTab(title: 'Tracking Kurir'),
        content: Center(
          child: Container(color: Colors.green, width: 100, height: 100),
        )),
    ContentView(
        tab: CustomTab(title: 'WhatsApp Bisnis'),
        content: Center(
          child: Container(color: Colors.green, width: 100, height: 100),
        )),
    ContentView(tab: CustomTab(title: 'Pengaturan'), content: Center()),
  ];
  void getbarangdiskonlist() async {
    final dataStorage = GetStorage();
    String id_gudangs = dataStorage.read('id_gudang');
    databarang = await fetchDataDiskonItem(id_gudangs);
    if (databarang.isNotEmpty) {
      isCheckedList = List.generate(databarang.length, (index) => false);
    }
    print("baranglist untuk diskon:$databarang");
  }

  //datepicker value
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  DateTime selectedDateStart = DateTime.now();
  Future<void> _selectDateStart(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDateStart) {
      setState(() {
        selectedDateStart = picked;
      });
    }
  }

  DateTime selectedDateEnd = DateTime.now();
  Future<void> _selectDateEnd(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateEnd,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDateEnd) {
      setState(() {
        selectedDateEnd = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUser();
    fetchDiskon();
    verify();
    setState(() {
      getbarangdiskonlist();
    });
    print("diskon data Flutter:$diskondata");

    email.addListener(() {
      setState(() {
        _isValidEmail = _validateEmail(email.text);
        if (!_isValidEmail) {
          print('format email salah');
        }
      });
    });
  }

  //cek tanggal berlaku diskon
  DateTime currentDate = DateTime.now();
  bool isDateInRange(DateTime startDate, DateTime endDate) {
    return currentDate.isAtSameMomentAs(startDate) ||
        currentDate.isAtSameMomentAs(endDate) ||
        (currentDate.isAfter(startDate) && currentDate.isBefore(endDate));
  }

  String getStatus(DateTime startDate, DateTime endDate) {
    if (isDateInRange(startDate, endDate)) {
      return 'Aktif';
    } else {
      return 'Tidak Aktif';
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    topPadding = screenHeight * 0.05;
    bottomPadding = screenHeight * 0.01;
    contentView = [
      ContentView(
          tab: CustomTab(title: 'Home'),
          content: Center(
            child: Container(child: Text("Home Page need Re-Design")),
          )),
      ContentView(
        tab: CustomTab(title: 'Daftar Diskon'),
        content: Center(
          child: Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black87,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Daftar Diskon',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder(
                      future: getDiskon(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final rows = snapshot.data!.map((map) {
                            var persentase =
                                map['persentase_diskon'].toString();
                            return DataRow(cells: [
                              DataCell(Text(
                                map['nama_diskon'].toString(),
                                style: TextStyle(fontSize: 15),
                              )),
                              DataCell(Text(
                                "$persentase %",
                                style: TextStyle(fontSize: 15),
                              )),
                              DataCell(Text(
                                map['start_date'].toString().substring(0, 10),
                                style: TextStyle(fontSize: 15),
                              )),
                              DataCell(Text(
                                map['end_date'].toString().substring(0, 10),
                                style: TextStyle(fontSize: 15),
                              )),
                              DataCell(Text(
                                getStatus(
                                  DateTime.parse(map['start_date']),
                                  DateTime.parse(map['end_date']),
                                ),
                                style: TextStyle(fontSize: 15),
                              )),
                              DataCell(
                                ElevatedButton(
                                  onPressed: () async {
                                    deletediskon(map['_id']);
                                    setState(() {
                                      fetchDiskon();
                                      getDiskon();
                                    });
                                  },
                                  child: Text('Delete'),
                                ),
                              ),
                            ]);
                          }).toList();

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const <DataColumn>[
                                DataColumn(
                                  label: Text(
                                    'Nama Diskon',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Persentase Diskon',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Tanggal Mulai',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Tanggal Berakhir',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Hapus Diskon',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                              rows: rows,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        } else {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ContentView(
        tab: CustomTab(title: 'Atur Diskon'),
        content: Center(
          child: Expanded(
              child: Container(
            color: Colors.black,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Atur Diskon'),
                    TextFormField(
                        controller: nama_diskon,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Field tidak boleh kosong';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Nama Diskon',
                        )),
                    TextFormField(
                      controller: persentase_diskon,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Field tidak boleh kosong';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Persentase Diskon(%)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    Text(
                      'Selected Date Start:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      //ini value date nya
                      _dateFormat.format(selectedDateStart),
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () => _selectDateStart(context),
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
                            Text('Start Date'),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      'Selected Date End:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      //ini value date nya
                      _dateFormat.format(selectedDateEnd),
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () => _selectDateEnd(context),
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
                            Text('End Date'),
                          ],
                        ),
                      ),
                    ),
                    //lokasi untuk multi checklist barang
                    Container(
                      height: 200,
                      child: databarang.length == 0
                          ? CircularProgressIndicator()
                          : ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: databarang.length,
                              itemBuilder: (context, index) {
                                return CheckboxListTile(
                                  title: Text(databarang[index]['nama_barang']
                                      .toString()),
                                  value: isCheckedList[index],
                                  onChanged: (value) {
                                    setState(() {
                                      isCheckedList[index] = value!;
                                      print(value);
                                    });
                                  },
                                );
                              },
                            ),
                    ),

                    FilledButton(
                        onPressed: () async {
                          String formattedDateStringStart =
                              _dateFormat.format(selectedDateStart);
                          DateTime insertedDateStart =
                              _dateFormat.parse(formattedDateStringStart);

                          String? DateStringStart;

                          insertedDateStart =
                              insertedDateStart.add(Duration(days: 1));
                          DateStringStart = insertedDateStart.toIso8601String();

                          String formattedDateStringEnd =
                              _dateFormat.format(selectedDateEnd);
                          DateTime insertedDateEnd =
                              _dateFormat.parse(formattedDateStringEnd);

                          String? DateStringEnd;

                          insertedDateEnd =
                              insertedDateEnd.add(Duration(days: 1));
                          DateStringEnd = insertedDateEnd.toIso8601String();
                          await tambahdiskon(
                              nama_diskon.text,
                              persentase_diskon.text,
                              DateStringStart,
                              DateStringEnd,
                              isCheckedList,
                              databarang,
                              context);

                          nama_diskon.text = "";
                          persentase_diskon.text = "";
                          selectedDateStart = DateTime.now();
                          selectedDateEnd = DateTime.now();
                          for (var i = 0; i < isCheckedList.length; i++) {
                            isCheckedList[i] = false;
                          }
                          setState(() {
                            fetchDiskon();
                          });
                        },
                        child: Text("Tambah Diskon")),
                  ],
                ),
              ],
            ),
          )),
        ),
      ),
      ContentView(
          tab: CustomTab(title: 'Stock Alert Barang'),
          content: Center(
            child: Container(color: Colors.blue, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Analisa Pendapatan'),
          content: Center(
            child: Container(color: Colors.blue, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Analisa Penghasilan'),
          content: Center(
            child: Container(color: Colors.green, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Grafik Trend'),
          content: Center(
            child: Container(color: Colors.green, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Lihat Laporan'),
          content: Center(
            child: Container(color: Colors.green, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Mutasi Barang'),
          content: Center(
            child: Container(color: Colors.blue, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Atur Pegawai'),
          content: Center(
            child: Container(
              color: Colors.black,
              width: double.maxFinite,
              height: double.maxFinite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 800,
                    height: 800,
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
                        SizedBox(height: 50),
                        Text('Daftar Pegawai', style: TextStyle(fontSize: 20)),
                        SizedBox(height: 100),
                        FutureBuilder(
                            future: getUsers(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final rows = snapshot.data!.map((map) {
                                  return DataRow(cells: [
                                    DataCell(
                                      GestureDetector(
                                        onTap: () {
                                          edit_fname.text = map['fname'];
                                          edit_lname.text = map['lname'];
                                          _isEditUser = true;
                                          temp_id_update = map['_id'];
                                        },
                                        child: Text(map['email'],
                                            style: TextStyle(fontSize: 15)),
                                      ),
                                    ),
                                    DataCell(Text(map['fname'],
                                        style: TextStyle(fontSize: 15))),
                                    DataCell(Text(map['lname'],
                                        style: TextStyle(fontSize: 15))),
                                    DataCell(Text(map['role'],
                                        style: TextStyle(fontSize: 15))),
                                    DataCell(
                                      Visibility(
                                        visible: map['role'] != 'Manager',
                                        child: ElevatedButton(
                                          onPressed: () {
                                            try {
                                              setState(() {
                                                deleteuser(map['_id'], context);
                                                fetchUser();
                                                getUsers();
                                              });
                                              print("userlist:$userlist");
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
                                        label: Text('Email',
                                            style: TextStyle(fontSize: 15))),
                                    DataColumn(
                                        label: Text('First Name',
                                            style: TextStyle(fontSize: 15))),
                                    DataColumn(
                                        label: Text('Last Name',
                                            style: TextStyle(fontSize: 15))),
                                    DataColumn(
                                        label: Text('Role',
                                            style: TextStyle(fontSize: 15))),
                                    DataColumn(
                                        label: Text('Hapus Pegawai',
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
                      ],
                    ),
                  ),
                  Container(
                    width: 600.0,
                    height: 800.0,
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text("Update Pegawai"),
                        SizedBox(height: 20.0),
                        TextFormField(
                          controller: edit_fname,
                          decoration:
                              InputDecoration(labelText: 'New First Name'),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: edit_lname,
                          decoration:
                              InputDecoration(labelText: 'New Last Name'),
                        ),
                        SizedBox(height: 16.0),
                        DropdownButton<String>(
                          value: value2,
                          items: roles
                              .map((item) => DropdownMenuItem(
                                  value: item, child: Text(item)))
                              .toList(),
                          onChanged: (value2) {
                            setState(() {
                              this.value2 = value2.toString();
                            });
                          },
                        ),
                        SizedBox(height: 32.0),
                        ElevatedButton(
                            onPressed: _isEditUser
                                ? () {
                                    UpdateUser(edit_fname.text, edit_lname.text,
                                        value2, temp_id_update, context);
                                    setState(() {
                                      edit_fname.text = "";
                                      edit_lname.text = "";
                                      _isEditUser = false;
                                      temp_id_update = "";
                                      fetchUser();
                                    });
                                  }
                                : null,
                            child: Text('Update Pegawai')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
      ContentView(
          tab: CustomTab(title: 'Tambah Pegawai'),
          content: Container(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Tambah Pegawai",
                        style: TextStyle(color: Colors.white),
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
                      DropdownButton<String>(
                        value: value,
                        items: roles
                            .map((item) => DropdownMenuItem(
                                value: item, child: Text(item)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            this.value = value.toString();
                          });
                        },
                      ),
                      SizedBox(height: 32.0),
                      FilledButton(
                          onPressed: _isValidEmail
                              ? () async {
                                  try {
                                    tambahpegawai(email.text, pass.text,
                                        fname.text, lname.text, value);
                                    fetchUser();
                                    getUsers();
                                    setState(() {
                                      showToast(
                                          context, 'Berhasil tambah data');
                                      email.text = "";
                                      pass.text = "";
                                      fname.text = "";
                                      lname.text = "";
                                      this.value = "Kasir";
                                    });
                                  } catch (e) {
                                    showToast(
                                        context, "something went wrong: $e");
                                  }
                                }
                              : null,
                          child: Text('Tambah Pegawai'))
                    ],
                  ),
                ),
              ))),
      ContentView(
          tab: CustomTab(title: 'Tracking Kurir'),
          content: Center(
            child: Container(color: Colors.green, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'WhatsApp Bisnis'),
          content: Center(
            child: Container(color: Colors.green, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Pengaturan'),
          content: Center(
            child: Container(
              color: Colors.black,
              width: double.maxFinite,
              alignment: Alignment.center,
              child: ButtonBar(
                alignment: MainAxisAlignment.center,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (logOwner)
                        FilledButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => managecabang()));
                            },
                            child: Text('Manage Cabang')),
                      ElevatedButton(
                          child: const Text('Pindah Kasir'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Information'),
                                  content: Text(
                                      'Silahkan Log In Menggunakan App kasir'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }),
                      ElevatedButton(
                          child: const Text('Pindah Gudang'),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GudangMenu()))),
                      ElevatedButton(
                          child: const Text('Log Out'),
                          onPressed: () {
                            GetStorage().erase();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => loginscreen()));
                          }),
                    ],
                  )
                ],
              ),
            ),
          )),
    ];

    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black87,
        primaryColor: Colors.grey[500] ?? Colors.grey,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[400] ?? Colors.grey,
          secondary: Colors.grey[300] ?? Colors.grey,
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        key: scaffoldKey,
        body: Row(
          children: [
            Container(
                width: 80,
                color: Colors.blue.shade100,
                child: Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GestureDetector(
                              onTap: () => _onItemTapped(0),
                              child: Tooltip(
                                message: "Home",
                                child: Icon(
                                  Icons.home,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                              ))),
                      Column(
                        children: [
                          Tooltip(
                            message: 'General',
                            child: IconButton(
                              icon: Icon(
                                Icons.menu,
                                size: 32,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isPegawaiExpanded) {
                                    isPegawaiExpanded = false;
                                  }
                                  isHomeExpanded = !isHomeExpanded;
                                });
                              },
                            ),
                          ),
                          if (isHomeExpanded)
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Daftar Diskon',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.discount_rounded,
                                      size: 28,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _onItemTapped(1),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Edit Diskon',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.edit_note_rounded,
                                      size: 28,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _onItemTapped(2),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Stock Alert',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.warning_amber_rounded,
                                      size: 28,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _onItemTapped(3),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Analisa Pendapatan',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.auto_graph_rounded,
                                      size: 28,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _onItemTapped(4),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Analisa Penghasilan',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.attach_money_rounded,
                                      size: 32,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _onItemTapped(5),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Grafik Trend',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.grade_sharp,
                                      size: 32,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _onItemTapped(6),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Laporan',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.book_outlined,
                                      size: 32,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _onItemTapped(7),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Tooltip(
                        message: 'Mutasi Barang',
                        child: IconButton(
                          icon: Icon(
                            Icons.warehouse_sharp,
                            size: 32,
                            color: Colors.blue,
                          ),
                          onPressed: () => _onItemTapped(8),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Tooltip(
                        message: 'Manage Pegawai',
                        child: IconButton(
                          icon: Icon(
                            Icons.person_outline_sharp,
                            size: 32,
                            color: Colors.blue,
                          ),
                          onPressed: () => setState(() {
                            if (isHomeExpanded) {
                              isHomeExpanded = false;
                            }
                            isPegawaiExpanded = !isPegawaiExpanded;
                          }),
                        ),
                      ),
                      if (isPegawaiExpanded)
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Daftar Pegawai',
                              child: IconButton(
                                icon: Icon(
                                  Icons.discount_rounded,
                                  size: 28,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _onItemTapped(9),
                              ),
                            ),
                            Tooltip(
                              message: 'Tambah Pegawai',
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit_note_rounded,
                                  size: 28,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _onItemTapped(10),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(
                        height: 20,
                      ),
                      Tooltip(
                        message: 'Tracking Kurir',
                        child: IconButton(
                          icon: Icon(
                            Icons.delivery_dining_outlined,
                            size: 32,
                            color: Colors.blue,
                          ),
                          onPressed: () => _onItemTapped(11),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Tooltip(
                        message: 'WhatsApp Bisnis',
                        child: IconButton(
                          icon: Icon(
                            Icons.wechat_sharp,
                            size: 32,
                            color: Colors.blue,
                          ),
                          onPressed: () => _onItemTapped(12),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Tooltip(
                        message: 'Settings',
                        child: IconButton(
                          icon: Icon(
                            Icons.settings_outlined,
                            size: 32,
                            color: Colors.blue,
                          ),
                          onPressed: () => _onItemTapped(13),
                        ),
                      ),
                      Spacer(),
                      Tooltip(
                        message: 'Logout',
                        child: IconButton(
                          icon: Icon(
                            Icons.logout,
                            size: 32,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            GetStorage().erase();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => loginscreen()));
                          },
                        ),
                      ),
                    ],
                  ),
                )),
            Expanded(
              child: contentView[_selectedIndex].content,
            ),
          ],
        ),
      ),
    );
  }
}
