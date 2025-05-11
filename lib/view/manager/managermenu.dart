import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:ta_pos/view-model-flutter/laporan_controller.dart';
import 'package:ta_pos/view/cabang/daftarcabang.dart';
import 'package:ta_pos/view/manager/DeliveryHistory.dart';
import 'package:ta_pos/view/manager/analisa_pendapatan.dart';
import 'package:ta_pos/view/manager/chatWhatsapp.dart';
import 'package:ta_pos/view-model-flutter/transaksi_controller.dart';
import 'package:ta_pos/view-model-flutter/user_controller.dart';
import 'package:ta_pos/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view-model-flutter/diskon_controller.dart';
import 'package:ta_pos/view/gudang/gudangmenu.dart';
import 'package:ta_pos/view/manager/laporanMenu.dart';
import 'package:ta_pos/view/manager/CustomTab.dart';
import 'package:ta_pos/view/manager/content_view.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view/manager/grafikTrend.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:sliding_up_panel/sliding_up_panel.dart';

var diskondata = Future.delayed(Duration(seconds: 1), () => getDiskon());
late bool logOwner;

class ManagerMenu extends StatefulWidget {
  const ManagerMenu({super.key});

  @override
  State<ManagerMenu> createState() => _ManagerMenuState();
}

class _ManagerMenuState extends State<ManagerMenu>
    with SingleTickerProviderStateMixin {
  //web socket check for courier tracking
  LatLng? _courierPosition;
  late WebSocketChannel channel;
  bool isWebSocketConnected = false;

  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  TextEditingController fname = TextEditingController();
  TextEditingController lname = TextEditingController();
  TextEditingController alamat = TextEditingController();
  TextEditingController no_telp = TextEditingController();
  TextEditingController edit_fname = TextEditingController();
  TextEditingController edit_lname = TextEditingController();
  TextEditingController nama_diskon = TextEditingController();
  TextEditingController persentase_diskon = TextEditingController();
  //search bar and pagination diskon list
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredDiskon = [];
  List<Map<String, dynamic>> _diskonData = [];
  int _rowsPerPagediskon = 10;
  int _currentPagediskon = 0;
  //search bar insert diskon
  String searchQueryDiskon = '';
  //checkbox atur diskon
  List<bool> isCheckedList = [];
  List<Map<String, dynamic>> databarang = [];
  bool selectAll = false;
  //func list diskon
  void fetchDiskon() async {
    var data = await getDiskon();
    if (data != null) {
      setState(() {
        _diskonData = data;
        _currentPagediskon = 0;
        _updatePaginationDiskon();
      });
    } else {
      print("Failed to fetch diskon data!");
    }
  }

  void _updatePaginationDiskon() {
    setState(() {
      // Calculate the starting index and the ending index for the current page
      int start = _currentPagediskon * _rowsPerPagediskon;
      int end = start + _rowsPerPagediskon;

      // Slice the data to show only the current page's data
      _filteredDiskon = _diskonData.sublist(
        start,
        end.clamp(0, _diskonData.length),
      );
    });
  }

  //search bar table in diskon list
  void onSearch(String query) {
    // Normalize query for case-insensitive search
    final lowerQuery = query.toLowerCase();

    // Check if the query is empty
    if (query.isEmpty) {
      setState(() {
        _filteredDiskon = _diskonData; // Reset to original data
      });
    } else {
      setState(() {
        _filteredDiskon = _diskonData.where((map) {
          // Ensure the fields are converted to String for comparison
          final namaDiskon = map['nama_diskon']?.toString().toLowerCase() ?? '';
          final persentaseDiskon = map['persentase_diskon']?.toString() ?? '';
          final startDate =
              map['start_date']?.toString().substring(0, 10) ?? '';
          final endDate = map['end_date']?.toString().substring(0, 10) ?? '';
          final status = getStatus(DateTime.parse(map['start_date']),
                  DateTime.parse(map['end_date']))
              .toLowerCase();

          return namaDiskon.contains(lowerQuery) ||
              persentaseDiskon.contains(query) ||
              startDate.contains(query) ||
              endDate.contains(query) ||
              status.contains(lowerQuery);
        }).toList();
      });
    }
  }

  //pegawai component
  TextEditingController _searchControllerPegawai = TextEditingController();
  List<Map<String, dynamic>> userlist = [];
  List<Map<String, dynamic>> _dataPegawai = [];
  List<Map<String, dynamic>> _filteredDataPegawai = [];
  String searchQueryPegawai = "";
  int _rowsPerPagepegawai = 5;
  int _currentPagepegawai = 1;
  void _updatePaginationPegawai() {
    setState(() {
      // Ensure that there is data to paginate
      if (_dataPegawai.isEmpty) {
        _filteredDataPegawai = [];
        return;
      }

      // Calculate the start and end indices for slicing the data
      int start = _currentPagepegawai * _rowsPerPagepegawai;
      int end = start + _rowsPerPagepegawai;

      // Slice the data to show only the current page's data
      _filteredDataPegawai = _dataPegawai.sublist(
        start,
        end.clamp(0, _dataPegawai.length),
      );
    });
  }

  void _filterDataPegawai(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredDataPegawai = _dataPegawai; // Reset to original data
      });
    } else {
      setState(() {
        _filteredDataPegawai = _dataPegawai.where((map) {
          return map['email']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              map['fname']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              map['lname']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              map['role']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();
      });
    }
    _updatePaginationPegawai();
  }

  //logout popup
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 16,
          child: Container(
            padding: EdgeInsets.all(20),
            height: 200,
            width: 300,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red[300]!,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Do you want to Log Out?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child:
                          Text('Cancel', style: TextStyle(color: Colors.blue)),
                    ),
                    TextButton(
                      onPressed: () {
                        flushCache();
                        GetStorage().erase();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => loginscreen()),
                            );
                          }
                        });
                      },
                      child: Text('Log Out',
                          style: TextStyle(color: Colors.red[300])),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //tampilkan semua pegawai
  void fetchUser() async {
    this.userlist = await getUsers();

    setState(() {
      _dataPegawai = userlist;
      _currentPagepegawai = 0; // Reset to the first page
      _updatePaginationPegawai(); // Update the data displayed based on the current page
    });
  }

  var scaffoldKey = GlobalKey<ScaffoldState>();
  //frontend stuff
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
  bool visiblepass = false;
  String diskon_idbarang = "";
  String temp_id_update = "";
  String value = 'Kasir';
  String value2 = 'Kasir';
  final roles = ['Kasir', 'Admin Gudang', 'Kurir'];
  //delivery info only
  PanelController _panelController = PanelController();
  List<dynamic>? _deliveryData;
  String id_transaksi = "";

  bool _validateEmail(String email) {
    RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Function to initialize the WebSocket connection for tracking
  void _initializeWebSocket() {
    if (!mounted) return;

    setState(() {
      isWebSocketConnected = false;
    });

    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/ws'),
    );

    channel.stream.listen(
      (message) {
        if (!mounted) return;
        Map<String, dynamic> data = jsonDecode(message);

        if (data.containsKey('latitude') &&
            data.containsKey('longitude') &&
            data.containsKey('id_transaksi')) {
          setState(() {
            isWebSocketConnected = true;
            _courierPosition = LatLng(data['latitude'], data['longitude']);
            id_transaksi = data['id_transaksi'];
          });
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        if (!mounted) return;
        setState(() {
          isWebSocketConnected = false;
        });
      },
      onDone: () {
        print('WebSocket connection closed.');
        if (!mounted) return;
        setState(() {
          isWebSocketConnected = false;
          id_transaksi = "";
          _deliveryData = null;
        });
      },
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  // Function to refresh WebSocket connection
  void _refreshWebSocketConnection() {
    channel.sink.close();
    _initializeWebSocket();
    _getDeliveryData();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Refreshing WebSocket connection...'),
    ));
  }

  Future<void> _getDeliveryData() async {
    if (id_transaksi != "") {
      final deliveryData = await showDeliveryByTransID(id_transaksi, context);
      if (deliveryData != null) {
        if (!mounted) return;
        setState(() {
          _deliveryData = deliveryData;
        });
      }
    } else {
      print("id_transaksi kosong");
    }
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
        tab: CustomTab(title: 'WhatsApp ChatBot'),
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
    _initializeWebSocket();
    setState(() {
      getbarangdiskonlist();
    });
    print("diskon data Flutter:$diskondata");
    _searchControllerPegawai.addListener(() {
      setState(() {
        searchQueryPegawai = _searchControllerPegawai.text;
        _filterDataPegawai(searchQueryPegawai);
      });
    });
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
      searchQueryDiskon = query.toLowerCase();
    });
  }

  //widget row khusus detail pegawai
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredBarang = databarang
        .where((barang) => barang['nama_barang']
            .toString()
            .toLowerCase()
            .contains(searchQueryDiskon))
        .toList();
    void toggleSelectAll(bool value) {
      setState(() {
        selectAll = value;
        isCheckedList = List.filled(filteredBarang.length, value);
      });
    }

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
            width: 900,
            height: 850,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 12),
                Text(
                  'Daftar Diskon',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: onSearch,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(10),
                      labelText: 'Search Diskon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: _filteredDiskon.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth),
                                  child: DataTable(
                                    headingRowHeight: 56,
                                    dividerThickness: 1,
                                    headingRowColor:
                                        MaterialStateColor.resolveWith(
                                      (states) =>
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    columnSpacing: 16,
                                    dataRowColor:
                                        MaterialStateColor.resolveWith(
                                      (states) =>
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                    dataTextStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14,
                                    ),
                                    headingTextStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Nama Diskon')),
                                      DataColumn(label: Text('Persentase')),
                                      DataColumn(label: Text('Mulai')),
                                      DataColumn(label: Text('Berakhir')),
                                      DataColumn(label: Text('Aktif')),
                                      DataColumn(label: Text('Hapus')),
                                    ],
                                    rows: _filteredDiskon.map<DataRow>((map) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(map['nama_diskon'])),
                                          DataCell(Text(
                                              "${map['persentase_diskon']} %")),
                                          DataCell(Text(map['start_date']
                                              .toString()
                                              .substring(0, 10))),
                                          DataCell(Text(map['end_date']
                                              .toString()
                                              .substring(0, 10))),
                                          DataCell(Switch(
                                            value: map['isActive'],
                                            onChanged: (val) async {
                                              await toggleDiskonStatus(
                                                  map['_id']);
                                              setState(() {
                                                fetchDiskon();
                                              });
                                            },
                                            activeColor: Colors.green,
                                            inactiveThumbColor: Colors.red,
                                          )),
                                          DataCell(
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () async {
                                                deletediskon(map['_id']);
                                                setState(() {
                                                  fetchDiskon();
                                                });
                                              },
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12, top: 6),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _currentPagediskon > 0
                              ? () {
                                  setState(() {
                                    _currentPagediskon--;
                                    _updatePaginationDiskon();
                                  });
                                }
                              : null,
                          icon: Icon(Icons.arrow_back_ios, size: 14),
                          label:
                              Text("Previous", style: TextStyle(fontSize: 14)),
                        ),
                        Text(
                          "Page ${_currentPagediskon + 1} of ${(_diskonData.length / _rowsPerPagediskon).ceil()}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed:
                              (_currentPagediskon + 1) * _rowsPerPagediskon <
                                      _diskonData.length
                                  ? () {
                                      setState(() {
                                        _currentPagediskon++;
                                        _updatePaginationDiskon();
                                      });
                                    }
                                  : null,
                          icon: Icon(Icons.arrow_forward_ios, size: 14),
                          label: Text("Next", style: TextStyle(fontSize: 14)),
                        ),
                      ],
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
        content: Center(
          child: Container(
            width: 900,
            height: 800,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                "Tambah Diskon",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: nama_diskon,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Field tidak boleh kosong'
                                      : null,
                              decoration: InputDecoration(
                                labelText: 'Nama Diskon',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.discount),
                              ),
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: persentase_diskon,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Field tidak boleh kosong'
                                      : null,
                              decoration: InputDecoration(
                                labelText: 'Persentase Diskon (%)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.percent),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Tanggal Mulai'),
                                      InkWell(
                                        onTap: () => _selectDateStart(context),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.grey),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.calendar_today),
                                              SizedBox(width: 8),
                                              Text(_dateFormat
                                                  .format(selectedDateStart)),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Tanggal Berakhir'),
                                      InkWell(
                                        onTap: () => _selectDateEnd(context),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.grey),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.calendar_today),
                                              SizedBox(width: 8),
                                              Text(_dateFormat
                                                  .format(selectedDateEnd)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            TextField(
                              onChanged: (value) => filterSearchResults(value),
                              decoration: InputDecoration(
                                labelText: 'Cari Barang',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                            SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectAll = !selectAll;
                                  toggleSelectAll(selectAll);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectAll
                                      ? Colors.blueAccent
                                      : Colors.grey[300],
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Select All',
                                      style: TextStyle(
                                        color: selectAll
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    Icon(
                                      selectAll
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: selectAll
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: databarang.isEmpty
                                  ? Center(child: CircularProgressIndicator())
                                  : ListView.builder(
                                      itemCount: filteredBarang.length,
                                      itemBuilder: (context, index) {
                                        return CheckboxListTile(
                                          title: Text(filteredBarang[index]
                                                  ['nama_barang']
                                              .toString()),
                                          value: isCheckedList[index],
                                          onChanged: (value) {
                                            setState(() {
                                              isCheckedList[index] = value!;
                                              selectAll =
                                                  isCheckedList.every((e) => e);
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
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final start = _dateFormat
                            .parse(_dateFormat.format(selectedDateStart))
                            .add(Duration(days: 1))
                            .toIso8601String();
                        final end = _dateFormat
                            .parse(_dateFormat.format(selectedDateEnd))
                            .add(Duration(days: 1))
                            .toIso8601String();
                        if (nama_diskon.text.isNotEmpty &&
                            persentase_diskon.text.isNotEmpty) {
                          if (isCheckedList.contains(true)) {
                            await tambahdiskon(
                              nama_diskon.text,
                              persentase_diskon.text,
                              start,
                              end,
                              isCheckedList,
                              databarang,
                              context,
                            );
                          } else {
                            showToast(context,
                                "Minimal memilih satu barang!, pendaftaran gagal...");
                          }
                        } else {
                          showToast(context, "Field tidak boleh kosong!");
                        }

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
                      label: Text("Tambah Diskon",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      ContentView(
        tab: CustomTab(title: 'Analisa Pendapatan'),
        content: AnalisaPendapatanView(),
      ),
      ContentView(
          tab: CustomTab(title: 'Analisa Penghasilan'),
          content: Center(
            child: Container(color: Colors.green, width: 100, height: 100),
          )),
      ContentView(
          tab: CustomTab(title: 'Grafik Trend'), content: GrafikTrendWidget()),
      ContentView(
        tab: CustomTab(title: 'Lihat Laporan'),
        content: const Center(
          child: ReportNavigationWrapper(),
        ),
      ),
      ContentView(
        tab: CustomTab(title: 'Atur Pegawai'),
        content: Center(
          child: Container(
            width: 900,
            height: 850,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                SizedBox(height: 12),
                Text(
                  'Daftar Pegawai',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchControllerPegawai,
                    onChanged: (val) {
                      setState(() {
                        searchQueryPegawai = val;
                      });
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(10),
                      labelText: 'Search Pegawai',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FutureBuilder(
                      future: getUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          List<Map<String, dynamic>> filteredDataPegawai =
                              snapshot.data!.where((map) {
                            final email = map['email'].toString().toLowerCase();
                            final fname = map['fname'].toString().toLowerCase();
                            final lname = map['lname'].toString().toLowerCase();
                            final role = map['role'].toString().toLowerCase();
                            final queryLower = searchQueryPegawai.toLowerCase();
                            return email.contains(queryLower) ||
                                fname.contains(queryLower) ||
                                lname.contains(queryLower) ||
                                role.contains(queryLower);
                          }).toList();

                          _filteredDataPegawai =
                              filteredDataPegawai; // ensure for pagination

                          final rows = filteredDataPegawai
                              .skip(_currentPagepegawai * _rowsPerPagepegawai)
                              .take(_rowsPerPagepegawai)
                              .map((map) {
                            return DataRow(cells: [
                              DataCell(GestureDetector(
                                onTap: () {
                                  _showEmployeeDetails(context, map);
                                },
                                child: Text(
                                  map['email'],
                                  style: TextStyle(fontSize: 14),
                                ),
                              )),
                              DataCell(Text(
                                "${map['fname']} ${map['lname']}",
                                style: TextStyle(fontSize: 14),
                              )),
                              DataCell(Text(
                                map['role'],
                                style: TextStyle(fontSize: 14),
                              )),
                              DataCell(
                                Visibility(
                                    visible: map['role'] != 'Manager',
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 20),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          try {
                                            deleteuser(map['_id'], context);
                                            fetchUser();
                                            getUsers();
                                          } catch (e) {
                                            print("Failed to delete: $e");
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                      ),
                                    )),
                              ),
                            ]);
                          }).toList();

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth),
                                  child: DataTable(
                                    headingRowHeight: 56,
                                    dividerThickness: 1,
                                    headingRowColor:
                                        MaterialStateColor.resolveWith(
                                            (states) => Theme.of(context)
                                                .colorScheme
                                                .primary),
                                    columnSpacing: 16,
                                    dataRowColor:
                                        MaterialStateColor.resolveWith(
                                            (states) => Theme.of(context)
                                                .colorScheme
                                                .surface),
                                    dataTextStyle: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    headingTextStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Email')),
                                      DataColumn(label: Text('Full Name')),
                                      DataColumn(label: Text('Role')),
                                      DataColumn(label: Text('Hapus Pegawai')),
                                    ],
                                    rows: rows,
                                  ),
                                ),
                              );
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12, top: 6),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _currentPagepegawai > 0
                              ? () {
                                  setState(() {
                                    _currentPagepegawai--;
                                  });
                                }
                              : null,
                          icon: Icon(Icons.arrow_back_ios, size: 14),
                          label:
                              Text("Previous", style: TextStyle(fontSize: 14)),
                        ),
                        Text(
                          "Page ${_currentPagepegawai + 1} of ${(_filteredDataPegawai.length / _rowsPerPagepegawai).ceil()}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed:
                              (_currentPagepegawai + 1) * _rowsPerPagepegawai <
                                      _filteredDataPegawai.length
                                  ? () {
                                      setState(() {
                                        _currentPagepegawai++;
                                      });
                                    }
                                  : null,
                          icon: Icon(Icons.arrow_forward_ios, size: 14),
                          label: Text("Next", style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ContentView(
        tab: CustomTab(title: 'Tambah Pegawai'),
        content: Container(
          color: Colors.black,
          child: Center(
            child: Container(
              width: 800,
              height: 800,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(10),
              ),
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
                  // Email
                  TextFormField(
                    controller: email,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      labelText: 'Enter Email',
                      labelStyle: TextStyle(color: Colors.grey[300]),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.email, color: Colors.grey[300]),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  // Password
                  TextFormField(
                    controller: pass,
                    obscureText: !visiblepass,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      labelText: 'Enter Password',
                      labelStyle: TextStyle(color: Colors.grey[300]),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.grey[300]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          visiblepass ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[300],
                        ),
                        onPressed: () {
                          setState(() {
                            visiblepass = !visiblepass;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  // First Name
                  TextFormField(
                    controller: fname,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      labelText: 'Enter First Name',
                      labelStyle: TextStyle(color: Colors.grey[300]),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.person, color: Colors.grey[300]),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  // Last Name
                  TextFormField(
                    controller: lname,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      labelText: 'Enter Last Name',
                      labelStyle: TextStyle(color: Colors.grey[300]),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.person, color: Colors.grey[300]),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  // Address
                  TextFormField(
                    controller: alamat,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      labelText: 'Enter Address',
                      labelStyle: TextStyle(color: Colors.grey[300]),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon:
                          Icon(Icons.location_on, color: Colors.grey[300]),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  // Phone
                  TextFormField(
                    controller: no_telp,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      labelText: 'Enter Phone Number',
                      labelStyle: TextStyle(color: Colors.grey[300]),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.phone, color: Colors.grey[300]),
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  SizedBox(height: 16.0),
                  // Dropdown Role
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
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
                  Spacer(),
                  Align(
                    alignment: Alignment
                        .center, // atau Alignment.center kalau mau di tengah
                    child: SizedBox(
                      width: 200, // ubah sesuai kebutuhan, misal 150 atau 180
                      child: FilledButton(
                        onPressed: (_isValidEmail &&
                                email.text.isNotEmpty &&
                                pass.text.isNotEmpty &&
                                fname.text.isNotEmpty &&
                                lname.text.isNotEmpty &&
                                alamat.text.isNotEmpty &&
                                no_telp.text.isNotEmpty)
                            ? () async {
                                String result = await tambahpegawai(
                                  email.text,
                                  pass.text,
                                  fname.text,
                                  lname.text,
                                  alamat.text,
                                  no_telp.text,
                                  value,
                                );

                                if (result == 'success') {
                                  showToast(context, 'Daftar Berhasil!');
                                  setState(() {
                                    email.clear();
                                    pass.clear();
                                    fname.clear();
                                    lname.clear();
                                    alamat.clear();
                                    no_telp.clear();
                                    this.value = "Kasir";
                                  });
                                } else if (result == 'email_exist') {
                                  showToast(context,
                                      'Email sudah terdaftar,daftar gagal!');
                                  setState(() {
                                    email.clear();
                                    pass.clear();
                                    fname.clear();
                                    lname.clear();
                                    alamat.clear();
                                    no_telp.clear();
                                    this.value = "Kasir";
                                  });
                                } else if (result == 'empty_field') {
                                  showToast(
                                      context, 'Field tidak boleh kosong!');
                                  setState(() {
                                    email.clear();
                                    pass.clear();
                                    fname.clear();
                                    lname.clear();
                                    alamat.clear();
                                    no_telp.clear();
                                    this.value = "Kasir";
                                  });
                                } else if (result == 'server_error') {
                                  showToast(context,
                                      'Gagal menambah data pegawai ke server');
                                  setState(() {
                                    email.clear();
                                    pass.clear();
                                    fname.clear();
                                    lname.clear();
                                    alamat.clear();
                                    no_telp.clear();
                                    this.value = "Kasir";
                                  });
                                } else {
                                  showToast(
                                      context, 'Terjadi kesalahan. Coba lagi!');
                                }
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      !_isValidEmail
                                          ? 'Format email tidak valid.'
                                          : 'Semua field harus diisi.',
                                    ),
                                  ),
                                );
                              },
                        child: Text('Tambah Pegawai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[400],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ContentView(
        tab: CustomTab(title: ' '),
        content: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: 'Refresh WebSocket Connection',
                  onPressed: _refreshWebSocketConnection,
                ),
                IconButton(
                  icon: Icon(Icons.history),
                  tooltip: 'Delivery History',
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DeliveryHistoryScreen()));
                      }
                    });
                  },
                ),
              ],
            ),
            Expanded(
              child: SlidingUpPanel(
                controller: _panelController,
                minHeight: 80, // Height of the closed panel
                maxHeight: MediaQuery.of(context).size.height * 0.4,
                panel: _deliveryData != null
                    ? _buildDeliveryPanel()
                    : Center(child: CircularProgressIndicator()),
                body: Expanded(
                  child: Center(
                    child: isWebSocketConnected && _courierPosition != null
                        ? FlutterMap(
                            options: MapOptions(
                              initialCenter:
                                  _courierPosition!, // Center the map on the courier
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _courierPosition!,
                                    width: 80.0,
                                    height: 80.0,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Text(isWebSocketConnected
                            ? 'Waiting for location updates...'
                            : 'WebSocket not connected or no in-progress delivery.'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ContentView(
          tab: CustomTab(title: 'WhatsApp Bisnis'),
          content: Center(
            child: ChatbotManagerScreen(),
          )),
      ContentView(
        tab: CustomTab(title: 'Pengaturan'),
        content: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (logOwner) ...[
                  FilledButton.icon(
                    icon: Icon(Icons.business),
                    label: Text('Manage Cabang'),
                    style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(48)),
                    onPressed: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DaftarCabang()),
                          );
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  icon: Icon(Icons.point_of_sale),
                  label: Text('Pindah Kasir'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(48)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text('Information'),
                        content: Text('Silahkan Log In Menggunakan App kasir'),
                        actions: [
                          TextButton(
                            child: Text('OK'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.inventory),
                  label: Text('Pindah Gudang'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(48)),
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GudangMenu()),
                        );
                      }
                    });
                  },
                ),
                SizedBox(height: 24),
                Divider(color: Colors.grey[600]),
                SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: Icon(Icons.logout),
                  label: Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[300],
                    minimumSize: Size.fromHeight(48),
                    side: BorderSide(color: Colors.red[300]!),
                  ),
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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
                  color: Colors.blueGrey[900],
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
                                          message: 'Tambah Diskon',
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
                                          message: 'Analisa Pendapatan',
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.auto_graph_rounded,
                                              size: 28,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () => _onItemTapped(3),
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
                                            onPressed: () => _onItemTapped(4),
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
                                            onPressed: () => _onItemTapped(5),
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
                                            onPressed: () => _onItemTapped(6),
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
                                          Icons.person_search_rounded,
                                          size: 28,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _onItemTapped(7),
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
                                        onPressed: () => _onItemTapped(8),
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
                                  onPressed: () => _onItemTapped(9),
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
                                  onPressed: () => _onItemTapped(10),
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
                                  onPressed: () => _onItemTapped(11),
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

  void _showEmployeeDetails(
      BuildContext context, Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: Text(
            'Detail Pegawai',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("First Name:", employee['fname']),
                _buildDetailRow("Last Name:", employee['lname']),
                _buildDetailRow("Email:", employee['email']),
                _buildDetailRow("Alamat:", employee['alamat']),
                _buildDetailRow("No. Telp:", employee['no_telp']),
                _buildDetailRow("Role:", employee['role']),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(color: Colors.blueAccent),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  //sliding panel delivery info
  Widget _buildDeliveryPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Ongoing Delivery:',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for better contrast
              ),
            ),
            SizedBox(height: 10),
            _deliveryData != null && isWebSocketConnected
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID Delivery: ${_deliveryData![0]['_id']}',
                        style: TextStyle(color: Colors.white), // White text
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Alamat Tujuan: ${_deliveryData![0]['alamat_tujuan']}',
                        style: TextStyle(color: Colors.white), // White text
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No. Telp Customer: ${_deliveryData![0]['no_telp_cust']}',
                        style: TextStyle(color: Colors.white), // White text
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ID Transaksi: ${id_transaksi}',
                        style: TextStyle(color: Colors.white), // White text
                      ),
                    ],
                  )
                : Center(
                    child: Container(
                    color: Colors.black,
                    child: CircularProgressIndicator(),
                  )),
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

class ReportNavigationWrapper extends StatefulWidget {
  const ReportNavigationWrapper({super.key});

  @override
  State<ReportNavigationWrapper> createState() =>
      _ReportNavigationWrapperState();
}

class _ReportNavigationWrapperState extends State<ReportNavigationWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheData();
  }

  Future<void> _loadCacheData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await triggerCacheAllDataCabang();
    } catch (e) {
      print('❌ Error loading cache: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading data...', style: TextStyle(fontSize: 16)),
            ],
          )
        : const ReportNavigationWidget();
  }
}
