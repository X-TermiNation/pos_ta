import 'package:flutter/rendering.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:ta_pos/view/view-model-flutter/user_controller.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view/view-model-flutter/diskon_controller.dart';
import 'package:ta_pos/view/gudang/gudangmenu.dart';
import 'package:ta_pos/view/cabang/managecabang.dart';
import 'package:ta_pos/view/manager/CustomTab.dart';
import 'package:ta_pos/view/manager/content_view.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:fl_chart/fl_chart.dart';

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
  //search bar diskon filter
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredDiskon = [];
  List<Map<String, dynamic>> _diskonData = [];
  //search bar insert diskon
  String searchQuery = '';
  //selected Pegawai di daftar pegawai
  Map<String, dynamic>? selectedEmployee;
  //checkbox atur diskon
  List<bool> isCheckedList = [];
  List<Map<String, dynamic>> databarang = [];
  bool selectAll = false;

  void fetchDiskon() {
    diskondata = Future.delayed(Duration(seconds: 1), () => getDiskon());
    diskondata.then((data) {
      setState(() {
        _diskonData = data;
        _filteredDiskon = data;
      });
    });
  }

  //search bar table in diskon list
  void onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredDiskon = _diskonData; // Reset to original data
      });
    } else {
      setState(() {
        _filteredDiskon = _diskonData.where((map) {
          return map['nama_diskon']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              map['persentase_diskon'].toString().contains(query) ||
              map['start_date'].toString().substring(0, 10).contains(query) ||
              map['end_date'].toString().substring(0, 10).contains(query) ||
              getStatus(DateTime.parse(map['start_date']),
                      DateTime.parse(map['end_date']))
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void fetchUser() async {
    this.userlist = await getUsers();
  }

  //delete stock alert
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

  //quantity widget stock alert
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
    ContentView(tab: CustomTab(title: 'Stock Alert'), content: Container()),
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
    getlowstocksatuan(context);
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

  void filterSearchResults(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredBarang = databarang
        .where((barang) => barang['nama_barang']
            .toString()
            .toLowerCase()
            .contains(searchQuery))
        .toList();
    void toggleSelectAll(bool value) {
      setState(() {
        selectAll = value;
        isCheckedList = List.filled(filteredBarang.length, value);
      });
    }
    //search bar insert diskon

    contentView = [
      ContentView(
        tab: CustomTab(title: 'Home'),
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio:
                  1.8, // Adjust aspect ratio to fit content properly
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return DashboardCard(
                    title: 'Sales Overview',
                    child: SalesChart(),
                  );
                case 1:
                  return DashboardCard(
                    title: 'User Statistics',
                    child: UserStatsChart(),
                  );
                case 2:
                  return DashboardCard(
                    title: 'Revenue',
                    child: RevenueChart(),
                  );
                case 3:
                  return DashboardCard(
                    title: 'Performance',
                    child: PerformanceChart(),
                  );
                default:
                  return Container(); // Default empty container
              }
            },
          ),
        ),
      ),
      ContentView(
        tab: CustomTab(title: 'Daftar Diskon'),
        content: Center(
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  'Daftar Diskon',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: onSearch,
                    decoration: InputDecoration(
                      labelText: 'Search Diskon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: _filteredDiskon.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: DataTable(
                              headingRowColor: MaterialStateColor.resolveWith(
                                (states) =>
                                    Theme.of(context).colorScheme.primary,
                              ),
                              columnSpacing: 20,
                              dataRowColor: MaterialStateColor.resolveWith(
                                (states) =>
                                    Theme.of(context).colorScheme.surface,
                              ),
                              dataTextStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                              ),
                              headingTextStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              columns: const <DataColumn>[
                                DataColumn(
                                  label: Text('Nama Diskon'),
                                ),
                                DataColumn(
                                  label: Text('Persentase Diskon'),
                                ),
                                DataColumn(
                                  label: Text('Tanggal Mulai'),
                                ),
                                DataColumn(
                                  label: Text('Tanggal Berakhir'),
                                ),
                                DataColumn(
                                  label: Text('Status'),
                                ),
                                DataColumn(
                                  label: Text('Hapus Diskon'),
                                ),
                              ],
                              rows: _filteredDiskon.map<DataRow>((map) {
                                var percentage =
                                    map['persentase_diskon'].toString();
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        map['nama_diskon'].toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        "$percentage %",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        map['start_date']
                                            .toString()
                                            .substring(0, 10),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        map['end_date']
                                            .toString()
                                            .substring(0, 10),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        getStatus(
                                          DateTime.parse(map['start_date']),
                                          DateTime.parse(map['end_date']),
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () async {
                                          deletediskon(map['_id']);
                                          fetchDiskon();
                                        },
                                        child: Text('Delete',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      ContentView(
        tab: CustomTab(title: 'Atur Diskon'),
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text("Atur Diskon"),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: nama_diskon,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Field tidak boleh kosong';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Nama Diskon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.discount),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: persentase_diskon,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Field tidak boleh kosong';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Persentase Diskon (%)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected Date Start:',
                              style: TextStyle(fontSize: 14)),
                          InkWell(
                            onTap: () => _selectDateStart(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today),
                                  SizedBox(width: 8),
                                  Text(_dateFormat.format(selectedDateStart)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected Date End:',
                              style: TextStyle(fontSize: 14)),
                          InkWell(
                            onTap: () => _selectDateEnd(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today),
                                  SizedBox(width: 8),
                                  Text(_dateFormat.format(selectedDateEnd)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  onChanged: (value) => filterSearchResults(value),
                  decoration: InputDecoration(
                    labelText: 'Cari Barang',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectAll = !selectAll; // Toggle the active state
                      toggleSelectAll(selectAll); // Update the selection logic
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectAll
                          ? Colors.blueAccent
                          : Colors.grey, // Change color based on active state
                      border: Border.all(
                          color: Colors.grey,
                          width: 1.0), // Border color and width
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26, // Shadow color
                          blurRadius: 6, // Shadow blur radius
                          offset: Offset(0, 2), // Shadow offset
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select All',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: selectAll
                                  ? Colors.white
                                  : Colors
                                      .black, // Change text color based on active state
                            ),
                          ),
                          Icon(
                            selectAll
                                ? Icons.check_box
                                : Icons
                                    .check_box_outline_blank, // Change icon based on active state
                            color: selectAll ? Colors.white : Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: databarang.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: filteredBarang.length,
                          itemBuilder: (context, index) {
                            return CheckboxListTile(
                              title: Text(filteredBarang[index]['nama_barang']
                                  .toString()),
                              value: isCheckedList[index],
                              onChanged: (value) {
                                setState(() {
                                  isCheckedList[index] = value!;
                                  if (value == false) {
                                    selectAll = false;
                                  } else if (isCheckedList
                                      .every((checked) => checked)) {
                                    selectAll = true;
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      String formattedDateStringStart =
                          _dateFormat.format(selectedDateStart);
                      DateTime insertedDateStart =
                          _dateFormat.parse(formattedDateStringStart);
                      insertedDateStart =
                          insertedDateStart.add(Duration(days: 1));
                      String DateStringStart =
                          insertedDateStart.toIso8601String();

                      String formattedDateStringEnd =
                          _dateFormat.format(selectedDateEnd);
                      DateTime insertedDateEnd =
                          _dateFormat.parse(formattedDateStringEnd);
                      insertedDateEnd = insertedDateEnd.add(Duration(days: 1));
                      String DateStringEnd = insertedDateEnd.toIso8601String();

                      await tambahdiskon(
                        nama_diskon.text,
                        persentase_diskon.text,
                        DateStringStart,
                        DateStringEnd,
                        isCheckedList,
                        databarang,
                        context,
                      );

                      nama_diskon.clear();
                      persentase_diskon.clear();
                      selectedDateStart = DateTime.now();
                      selectedDateEnd = DateTime.now();
                      isCheckedList =
                          List<bool>.filled(databarang.length, false);

                      setState(() {
                        fetchDiskon();
                      });
                    },
                    label: Text(
                      "Tambah Diskon",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ContentView(
          tab: CustomTab(title: 'Stock Alert Barang'),
          content: Center(
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
                                TableCell(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Re-Stock',
                                      style: TextStyle(
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
                                      child: Text(
                                          data['jumlah_satuan'].toString()),
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
                        Text(
                          'Daftar Pegawai',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
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
                                          setState(() {
                                            selectedEmployee = map;
                                          });
                                        },
                                        child: Text(
                                          map['email'],
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                      map['fname'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    )),
                                    DataCell(Text(
                                      map['lname'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    )),
                                    DataCell(Text(
                                      map['role'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    )),
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
                                            } catch (e) {
                                              print("Failed to delete: $e");
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
                                        label: Text(
                                      'Email',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'First Name',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Last Name',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Role',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Hapus Pegawai',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                    )),
                                  ],
                                  rows: rows,
                                );
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}',
                                    style: TextStyle(color: Colors.white));
                              } else {
                                return CircularProgressIndicator();
                              }
                            }),
                      ],
                    ),
                  ),
                  Container(
                    width: 2.0,
                    height: 800.0,
                    color: Colors.grey, // Border divider color
                  ),
                  Container(
                    width: 600.0,
                    height: 800.0,
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Detail Pegawai",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center, // Center the title
                        ),
                        SizedBox(height: 30.0),
                        selectedEmployee != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        "First Name:",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18, // Increase text size
                                        ),
                                      ),
                                      Text(
                                        " ${selectedEmployee!['fname']}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18, // Increase text size
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.0),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        "Last Name:",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18, // Increase text size
                                        ),
                                      ),
                                      Text(
                                        "${selectedEmployee!['lname']}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18, // Increase text size
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.0),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        "Role:",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18, // Increase text size
                                        ),
                                      ),
                                      Text(
                                        "${selectedEmployee!['role']}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18, // Increase text size
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 30.0),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _isEditUser
                                          ? () {
                                              UpdateUser(
                                                  edit_fname.text,
                                                  edit_lname.text,
                                                  value2,
                                                  temp_id_update,
                                                  context);
                                              setState(() {
                                                edit_fname.text = "";
                                                edit_lname.text = "";
                                                _isEditUser = false;
                                                temp_id_update = "";
                                                fetchUser();
                                              });
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 50, vertical: 20),
                                      ),
                                      child: Text(
                                        'Update Pegawai',
                                        style: TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                "Select a Pegawai to see details",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Tambah Pegawai",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.0),
                    TextFormField(
                      controller: email,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        labelText: 'Enter Email',
                        labelStyle: TextStyle(color: Colors.grey[300]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: pass,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        labelText: 'Enter Password',
                        labelStyle: TextStyle(color: Colors.grey[300]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: fname,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        labelText: 'Enter First Name',
                        labelStyle: TextStyle(color: Colors.grey[300]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: lname,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        labelText: 'Enter Last Name',
                        labelStyle: TextStyle(color: Colors.grey[300]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[500]!),
                      ),
                      child: DropdownButton<String>(
                        value: value,
                        dropdownColor: Colors.grey[800],
                        iconEnabledColor: Colors.white,
                        style: TextStyle(color: Colors.white),
                        items: roles
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            this.value = value.toString();
                          });
                        },
                        underline: SizedBox(),
                      ),
                    ),
                    SizedBox(height: 32.0),
                    FilledButton(
                      onPressed: _isValidEmail
                          ? () async {
                              try {
                                tambahpegawai(email.text, pass.text, fname.text,
                                    lname.text, value);
                                fetchUser();
                                getUsers();
                                setState(() {
                                  showToast(context, 'Berhasil tambah data');
                                  email.text = "";
                                  pass.text = "";
                                  fname.text = "";
                                  lname.text = "";
                                  this.value = "Kasir";
                                });
                              } catch (e) {
                                showToast(context, "something went wrong: $e");
                              }
                            }
                          : null,
                      child: Text('Tambah Pegawai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[400],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: 80,
                  height: constraints.maxHeight,
                  color: Colors.grey[600],
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
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
                                  ),
                                ),
                              ),
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
                              SizedBox(height: 20),
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
                              SizedBox(height: 20),
                              Tooltip(
                                message: 'Manage Pegawai',
                                child: IconButton(
                                  icon: Icon(
                                    Icons.person_outline_sharp,
                                    size: 32,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isHomeExpanded) {
                                        isHomeExpanded = false;
                                      }
                                      isPegawaiExpanded = !isPegawaiExpanded;
                                    });
                                  },
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
                              SizedBox(height: 20),
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
                              SizedBox(height: 20),
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
                              SizedBox(height: 20),
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
                              SizedBox(height: 20),
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom >
                                              0
                                          ? 0
                                          : 16.0,
                                ),
                                child: Tooltip(
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
                                          builder: (context) => loginscreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: contentView[_selectedIndex].content,
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;

  DashboardCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class SalesChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.white30,
            width: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, 1),
              FlSpot(1, 1.5),
              FlSpot(2, 1.2),
              FlSpot(3, 2),
            ],
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

class UserStatsChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: Theme.of(context).colorScheme.primary,
            value: 40,
            title: '40%',
            radius: 60,
          ),
          PieChartSectionData(
            color: Theme.of(context).colorScheme.secondary,
            value: 30,
            title: '30%',
            radius: 60,
          ),
          PieChartSectionData(
            color: Colors.green,
            value: 20,
            title: '20%',
            radius: 60,
          ),
          PieChartSectionData(
            color: Colors.red,
            value: 10,
            title: '10%',
            radius: 60,
          ),
        ],
      ),
    );
  }
}

class RevenueChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(
                toY: 5, color: Theme.of(context).colorScheme.primary)
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
                toY: 6, color: Theme.of(context).colorScheme.secondary)
          ]),
          BarChartGroupData(
              x: 2, barRods: [BarChartRodData(toY: 4, color: Colors.green)]),
          BarChartGroupData(
              x: 3, barRods: [BarChartRodData(toY: 3, color: Colors.red)]),
        ],
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.white30,
            width: 1,
          ),
        ),
        titlesData: FlTitlesData(show: false),
      ),
    );
  }
}

class PerformanceChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.white30,
            width: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, 2),
              FlSpot(1, 1.5),
              FlSpot(2, 3),
              FlSpot(3, 1.5),
            ],
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
