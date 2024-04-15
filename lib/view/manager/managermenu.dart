import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:ta_pos/view/view-model-flutter/user_controller.dart';
import 'package:ta_pos/view/view-model-flutter/diskon_controller.dart';
import 'package:ta_pos/view/gudang/gudangmenu.dart';
import 'package:ta_pos/view/cabang/managecabang.dart';
import 'package:ta_pos/view/manager/CustomTab.dart';
import 'package:ta_pos/view/manager/content_view.dart';
import 'custom_tab_bar.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/loginpage/login.dart';

late double _containerWidth;
late double _containerHeight;
late double _containerHeightInside;
var diskondata = Future.delayed(Duration(seconds: 1), () => getDiskon());
List<Map<String, dynamic>> _dataList = [];

bool key1 = true;
bool key2 = true;
bool key3 = true;
bool key4 = true;
bool bigScreen = false;

void normalstyle() {
  _containerWidth = 740;
  _containerHeight = 320;
  _containerHeightInside = 240;
}

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

  void _increasesize1() {
    setState(() {
      _containerWidth = 1500;
      _containerHeight = 800;
      key1 = true;
      key2 = false;
      key3 = false;
      key4 = false;
      bigScreen = true;
    });
  }

  void _increasesize2() {
    setState(() {
      _containerWidth = 1500;
      _containerHeight = 800;
      key1 = false;
      key2 = true;
      key3 = false;
      key4 = false;
      bigScreen = true;
    });
  }

  void _increasesize3() {
    setState(() {
      _containerWidth = 1500;
      _containerHeight = 800;
      key1 = false;
      key2 = false;
      key3 = true;
      key4 = false;
      bigScreen = true;
    });
  }

  void _increasesize4() {
    setState(() {
      _containerWidth = 1500;
      _containerHeight = 800;
      key1 = false;
      key2 = false;
      key3 = false;
      key4 = true;
      bigScreen = true;
    });
  }

  void _quitbigcreenmode() {
    setState(() {
      _containerWidth = 740;
      _containerHeight = 320;
      key1 = true;
      key2 = true;
      key3 = true;
      key4 = true;
      bigScreen = false;
    });
  }

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
        tab: CustomTab(title: 'Mutasi Barang'),
        content: Center(
          child: Container(color: Colors.blue, width: 100, height: 100),
        )),
    ContentView(
        tab: CustomTab(title: 'Lihat Laporan'),
        content: Center(
          child: Container(color: Colors.green, width: 100, height: 100),
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
    ContentView(tab: CustomTab(title: 'Grafik Trend'), content: Center()),
    ContentView(tab: CustomTab(title: 'Analisa Pendapatan'), content: Center()),
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

  @override
  void initState() {
    super.initState();
    final dataStorage = GetStorage();
    String id_gudangs = dataStorage.read('id_gudang');
    fetchUser();
    normalstyle();
    verify();
    setState(() {
      getbarangdiskonlist();
    });

    print(userlist);
    email.addListener(() {
      setState(() {
        _isValidEmail = _validateEmail(email.text);
        if (!_isValidEmail) {
          print('format email salah');
        }
      });
    });
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
  Widget build(BuildContext context) {
    //cek tanggal berlaku diskon
    DateTime currentDate = DateTime.now();
    bool isDateInRange(DateTime startDate, DateTime endDate) {
      return currentDate.isAtSameMomentAs(startDate) ||
          currentDate.isAtSameMomentAs(endDate) ||
          (currentDate.isAfter(startDate) && currentDate.isBefore(endDate));
    }

    String getStatus(DateTime startDate, DateTime endDate) {
      if (isDateInRange(startDate, endDate)) {
        return 'Aktif'; // Set your desired status when the current date is within the range
      } else {
        return 'Tidak Aktif'; // Set your desired status when the current date is outside the range
      }
    }

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    topPadding = screenHeight * 0.05;
    bottomPadding = screenHeight * 0.01;

    contentView = [
      ContentView(
          tab: CustomTab(title: 'Home'),
          content: Center(
            child: Container(
              color: Colors.black,
              width: 1500,
              height: 800,
              child: Stack(
                fit: StackFit.loose,
                children: [
                  Visibility(
                    visible: key1,
                    child: Positioned(
                        top: 0,
                        left: 0,
                        child: GestureDetector(
                            onTap: _increasesize1,
                            child: Container(
                                child: bigScreen
                                    ? Container(
                                        color: Colors.blue,
                                        width: _containerWidth,
                                        height: _containerHeight,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text('Atur Diskon'),
                                                TextFormField(
                                                    controller: nama_diskon,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Field tidak boleh kosong';
                                                      }
                                                      return null;
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                      border:
                                                          UnderlineInputBorder(),
                                                      labelText: 'Nama Diskon',
                                                    )),
                                                TextFormField(
                                                  controller: persentase_diskon,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Field tidak boleh kosong';
                                                    }
                                                    return null;
                                                  },
                                                  decoration:
                                                      const InputDecoration(
                                                    border:
                                                        UnderlineInputBorder(),
                                                    labelText:
                                                        'Persentase Diskon(%)',
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                ),
                                                Text(
                                                  'Selected Date Start:',
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                                Text(
                                                  //ini value date nya
                                                  _dateFormat.format(
                                                      selectedDateStart),
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                InkWell(
                                                  onTap: () =>
                                                      _selectDateStart(context),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons
                                                            .calendar_today),
                                                        SizedBox(width: 8),
                                                        Text('Start Date'),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Selected Date End:',
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                                Text(
                                                  //ini value date nya
                                                  _dateFormat
                                                      .format(selectedDateEnd),
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                InkWell(
                                                  onTap: () =>
                                                      _selectDateEnd(context),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons
                                                            .calendar_today),
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
                                                          scrollDirection:
                                                              Axis.vertical,
                                                          itemCount:
                                                              databarang.length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            return CheckboxListTile(
                                                              title: Text(databarang[
                                                                          index]
                                                                      [
                                                                      'nama_barang']
                                                                  .toString()),
                                                              value:
                                                                  isCheckedList[
                                                                      index],
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  isCheckedList[
                                                                          index] =
                                                                      value!;
                                                                  print(value);
                                                                });
                                                              },
                                                            );
                                                          },
                                                        ),
                                                ),

                                                FilledButton(
                                                    onPressed: () async {
                                                      String
                                                          formattedDateStringStart =
                                                          _dateFormat.format(
                                                              selectedDateStart);
                                                      DateTime
                                                          insertedDateStart =
                                                          _dateFormat.parse(
                                                              formattedDateStringStart);

                                                      String? DateStringStart;

                                                      insertedDateStart =
                                                          insertedDateStart.add(
                                                              Duration(
                                                                  days: 1));
                                                      DateStringStart =
                                                          insertedDateStart
                                                              .toIso8601String();

                                                      String
                                                          formattedDateStringEnd =
                                                          _dateFormat.format(
                                                              selectedDateEnd);
                                                      DateTime insertedDateEnd =
                                                          _dateFormat.parse(
                                                              formattedDateStringEnd);

                                                      String? DateStringEnd;

                                                      insertedDateEnd =
                                                          insertedDateEnd.add(
                                                              Duration(
                                                                  days: 1));
                                                      DateStringEnd =
                                                          insertedDateEnd
                                                              .toIso8601String();
                                                      await tambahdiskon(
                                                          nama_diskon.text,
                                                          persentase_diskon
                                                              .text,
                                                          DateStringStart,
                                                          DateStringEnd,
                                                          isCheckedList,
                                                          databarang,
                                                          context);

                                                      nama_diskon.text = "";
                                                      persentase_diskon.text =
                                                          "";
                                                      selectedDateStart =
                                                          DateTime.now();
                                                      selectedDateEnd =
                                                          DateTime.now();
                                                      for (var i = 0;
                                                          i <
                                                              isCheckedList
                                                                  .length;
                                                          i++) {
                                                        isCheckedList[i] =
                                                            false;
                                                      }
                                                      setState(() {
                                                        diskondata =
                                                            Future.delayed(
                                                                Duration(
                                                                    seconds: 1),
                                                                () =>
                                                                    getDiskon());
                                                      });
                                                    },
                                                    child:
                                                        Text("Tambah Diskon")),
                                                Container(
                                                    width: 1400,
                                                    height: 30,
                                                    child: Stack(
                                                      children: [
                                                        Positioned(
                                                            bottom: 0,
                                                            right: 0,
                                                            child: IconButton(
                                                                color: Colors
                                                                    .black,
                                                                onPressed:
                                                                    _quitbigcreenmode,
                                                                icon: Icon(Icons
                                                                    .aspect_ratio_sharp)))
                                                      ],
                                                    )),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        color: Colors.blue,
                                        width: _containerWidth,
                                        height: _containerHeight,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text('Edit Diskon'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )))),
                  ),
                  Visibility(
                    visible: key2,
                    child: Positioned(
                        bottom: 0,
                        left: 0,
                        child: GestureDetector(
                            onTap: _increasesize2,
                            child: bigScreen
                                ? Container(
                                    color: Colors.yellow,
                                    width: _containerWidth,
                                    height: _containerHeight,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Daftar Diskon'),
                                            SizedBox(
                                              height: 100,
                                            ),
                                            FutureBuilder(
                                                future: diskondata,
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    final rows = snapshot.data!
                                                        .map((map) {
                                                      var persentase =
                                                          map['persentase_diskon']
                                                              .toString();
                                                      return DataRow(cells: [
                                                        DataCell(Text(
                                                            map['nama_diskon']
                                                                .toString(),
                                                            style: TextStyle(
                                                                fontSize: 15))),
                                                        DataCell(Text(
                                                            "$persentase %",
                                                            style: TextStyle(
                                                                fontSize: 15))),
                                                        DataCell(Text(
                                                            map['start_date']
                                                                .toString()
                                                                .substring(
                                                                    0, 10),
                                                            style: TextStyle(
                                                                fontSize: 15))),
                                                        DataCell(Text(
                                                            map['end_date']
                                                                .toString()
                                                                .substring(
                                                                    0, 10),
                                                            style: TextStyle(
                                                                fontSize: 15))),
                                                        DataCell(
                                                          Text(
                                                            getStatus(
                                                                DateTime.parse(map[
                                                                    'start_date']),
                                                                DateTime.parse(map[
                                                                    'end_date'])),
                                                            style: TextStyle(
                                                                fontSize: 15),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              deletediskon(
                                                                  map['_id']);
                                                              setState(() {
                                                                diskondata = Future.delayed(
                                                                    Duration(
                                                                        seconds:
                                                                            1),
                                                                    () =>
                                                                        getDiskon());
                                                              });
                                                            },
                                                            child:
                                                                Text('Delete'),
                                                          ),
                                                        ),
                                                      ]);
                                                    }).toList();
                                                    return DataTable(
                                                      columns: const <DataColumn>[
                                                        DataColumn(
                                                            label: Text(
                                                                'Nama Diskon',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15))),
                                                        DataColumn(
                                                            label: Text(
                                                                'Persentase Diskon',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15))),
                                                        DataColumn(
                                                            label: Text(
                                                                'Tanggal Mulai',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15))),
                                                        DataColumn(
                                                            label: Text(
                                                                'Tanggal Berakhir',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15))),
                                                        DataColumn(
                                                            label: Text(
                                                                'Status',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15))),
                                                        DataColumn(
                                                            label: Text(
                                                                'Hapus Diskon',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15))),
                                                      ],
                                                      rows: rows,
                                                    );
                                                  } else if (snapshot
                                                      .hasError) {
                                                    // Show an error message.
                                                    return Text(
                                                        'Error: ${snapshot.error}');
                                                  } else {
                                                    // Show a loading indicator.
                                                    return CircularProgressIndicator();
                                                  }
                                                }),
                                            Container(
                                                width: 1400,
                                                height: 30,
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                        bottom: 0,
                                                        right: 0,
                                                        child: IconButton(
                                                            color: Colors.black,
                                                            onPressed:
                                                                _quitbigcreenmode,
                                                            icon: Icon(Icons
                                                                .aspect_ratio_sharp)))
                                                  ],
                                                )),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    color: Colors.yellow,
                                    width: _containerWidth,
                                    height: _containerHeight,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Daftar Diskon'),
                                          ],
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [Container()],
                                        ),
                                      ],
                                    ),
                                  ))),
                  ),
                  Visibility(
                    visible: key3,
                    child: Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                            onTap: _increasesize3,
                            child: bigScreen
                                ? Container(
                                    color: Colors.purple,
                                    width: _containerWidth,
                                    height: _containerHeight,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Stock alert'),
                                          ],
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 1400,
                                              height: 400,
                                              child: Stack(
                                                fit: StackFit.loose,
                                                children: [
                                                  Positioned(
                                                      bottom: 0,
                                                      right: 0,
                                                      child: IconButton(
                                                          color: Colors.black,
                                                          onPressed:
                                                              _quitbigcreenmode,
                                                          icon: Icon(Icons
                                                              .aspect_ratio_sharp)))
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    color: Colors.purple,
                                    width: _containerWidth,
                                    height: _containerHeight,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Stock alert'),
                                          ],
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [Container()],
                                        ),
                                      ],
                                    ),
                                  ))),
                  ),
                  Visibility(
                    visible: key4,
                    child: Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                            onTap: _increasesize4,
                            child: bigScreen
                                ? Container(
                                    color: Colors.green,
                                    width: _containerWidth,
                                    height: _containerHeight,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Analisa Revenue'),
                                          ],
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 1400,
                                              height: 400,
                                              child: Stack(
                                                fit: StackFit.loose,
                                                children: [
                                                  Positioned(
                                                      bottom: 0,
                                                      right: 0,
                                                      child: IconButton(
                                                          color: Colors.black,
                                                          onPressed:
                                                              _quitbigcreenmode,
                                                          icon: Icon(Icons
                                                              .aspect_ratio_sharp)))
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    color: Colors.green,
                                    width: _containerWidth,
                                    height: _containerHeight,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Analisa Revenue'),
                                          ],
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [Container()],
                                        ),
                                      ],
                                    ),
                                  ))),
                  )
                ],
              ),
            ),
          )),
      ContentView(
          tab: CustomTab(title: 'Mutasi Barang'),
          content: Center(
            child: Container(color: Colors.blue, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Lihat Laporan'),
          content: Center(
            child: Container(color: Colors.green, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Atur Pegawai'),
          content: Center(
            child: Container(
              color: Colors.white,
              width: 1400,
              height: 800,
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
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
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
              color: Colors.white,
              width: 1400,
              height: 800,
              alignment: Alignment.center,
              child: ButtonBar(
                alignment: MainAxisAlignment.center,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          child: const Text('Pindah Kasir'), onPressed: () {}),
                      ElevatedButton(
                          child: const Text('Pindah Gudang'),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GudangMenu()))),
                      FilledButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => managecabang()));
                          },
                          child: Text('Tambah Cabang')),
                      ElevatedButton(
                          child: const Text('Log Out'),
                          onPressed: () {
                            GetStorage().erase();
                            Navigator.push(
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
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: drawer(),
      key: scaffoldKey,
      body: Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: LayoutBuilder(
          builder: (context, Constraints) {
            if (Constraints.maxWidth > 715) {
              return desktopView();
            } else {
              return mobileView();
            }
          },
        ),
      ),
    );
  }

  Widget mobileView() {
    return Padding(
      padding:
          EdgeInsets.only(left: screenWidth * 0.05, right: screenWidth * 0.05),
      child: Container(
        width: screenWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              iconSize: screenWidth * 0.08,
              icon: Icon(Icons.menu_rounded),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            )
          ],
        ),
      ),
    );
  }

  Widget desktopView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTabBar(
          controller: tabController,
          tabs: contentView.map((e) => e.tab).toList(),
        ),
        Container(
          height: screenHeight * 0.85,
          child: TabBarView(
            controller: tabController,
            children: contentView.map((e) => e.content).toList(),
          ),
        ),
      ],
    );
  }

  Widget drawer() {
    return Drawer(
      child: ListView(
        children: [
              Container(
                height: screenHeight * 0.1,
              )
            ] +
            contentView
                .map((e) => Container(
                      child: ListTile(
                        title: Text(e.tab.title),
                        onTap: () {},
                      ),
                    ))
                .toList(),
      ),
    );
  }
}
