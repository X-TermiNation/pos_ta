import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:ta_pos/view/cabang/daftarcabang.dart';
import 'package:ta_pos/view/manager/DeliveryHistory.dart';
import 'package:ta_pos/view/manager/chatWhatsapp.dart';
import 'package:ta_pos/view/view-model-flutter/transaksi_controller.dart';
import 'package:ta_pos/view/view-model-flutter/user_controller.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view/view-model-flutter/diskon_controller.dart';
import 'package:ta_pos/view/gudang/gudangmenu.dart';
import 'package:ta_pos/view/manager/CustomTab.dart';
import 'package:ta_pos/view/manager/content_view.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:sliding_up_panel/sliding_up_panel.dart';

List<Map<String, dynamic>> _dataList = [];
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
  void fetchDiskon() {
    diskondata = Future.delayed(Duration(seconds: 1), () => getDiskon());
    diskondata.then((data) {
      setState(() {
        _diskonData = data;
        _currentPagediskon = 0; // Reset to the first page
        _updatePaginationDiskon(); // Update the data displayed based on the current page
      });
    });
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

  //selected Pegawai di daftar pegawai
  // Map<String, dynamic>? selectedEmployee;

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
    setState(() {
      isWebSocketConnected = false; // Reset connection status
    });

    // Set up WebSocket connection
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/ws'), // WebSocket server URL
    );

    // Listen for location updates from the WebSocket server
    channel.stream.listen((message) {
      // Parse the incoming message
      Map<String, dynamic> data = jsonDecode(message);

      // Check if the message contains latitude and longitude
      if (data.containsKey('latitude') &&
          data.containsKey('longitude') &&
          data.containsKey('id_transaksi')) {
        setState(() {
          isWebSocketConnected =
              true; // WebSocket is active when data is received
          _courierPosition = LatLng(data['latitude'], data['longitude']);
          id_transaksi = data['id_transaksi'];
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
      setState(() {
        isWebSocketConnected = false;
      });
    }, onDone: () {
      print('WebSocket connection closed.');
      setState(() {
        isWebSocketConnected = false; // WebSocket is inactive when closed
        id_transaksi = "";
        _deliveryData = null;
      });
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  // Function to refresh WebSocket connection
  void _refreshWebSocketConnection() {
    // Close the current WebSocket connection and reinitialize it
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
                      : Padding(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          child: SingleChildScrollView(
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                                headingTextStyle: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                columns: const <DataColumn>[
                                  DataColumn(label: Text('Nama Diskon')),
                                  DataColumn(label: Text('Persentase Diskon')),
                                  DataColumn(label: Text('Tanggal Mulai')),
                                  DataColumn(label: Text('Tanggal Berakhir')),
                                  DataColumn(label: Text('Hapus Diskon')),
                                ],
                                rows: _filteredDiskon.map<DataRow>((map) {
                                  var percentage =
                                      map['persentase_diskon'].toString();
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                          Text(map['nama_diskon'].toString())),
                                      DataCell(Text("$percentage %")),
                                      DataCell(
                                        Text(map['start_date']
                                            .toString()
                                            .substring(0, 10)),
                                      ),
                                      DataCell(
                                        Text(map['end_date']
                                            .toString()
                                            .substring(0, 10)),
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
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant, // For contrast with the table
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                          icon: Icon(Icons.arrow_back_ios, size: 16),
                          label: Text("Previous"),
                        ),
                        Text(
                          "Page ${_currentPagediskon + 1} of ${(_diskonData.length / _rowsPerPagediskon).ceil()}",
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                          icon: Icon(Icons.arrow_forward_ios, size: 16),
                          label: Text("Next"),
                        ),
                      ],
                    ),
                  ),
                )
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
                      selectAll = !selectAll;
                      toggleSelectAll(selectAll);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectAll ? Colors.blueAccent : Colors.grey,
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
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
          tab: CustomTab(title: 'Atur Pegawai'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Daftar Pegawai',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 30),
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _searchControllerPegawai,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search Pegawai',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Expanded to take up available space
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FutureBuilder(
                            future: getUsers(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                // Filter data based on search term
                                List<Map<String, dynamic>> filteredDataPegawai =
                                    snapshot.data!.where((map) {
                                  final email =
                                      map['email'].toString().toLowerCase();
                                  final fname =
                                      map['fname'].toString().toLowerCase();
                                  final lname =
                                      map['lname'].toString().toLowerCase();
                                  final role =
                                      map['role'].toString().toLowerCase();

                                  final queryLower =
                                      searchQueryPegawai.toLowerCase();

                                  return email.contains(queryLower) ||
                                      fname.contains(queryLower) ||
                                      lname.contains(queryLower) ||
                                      role.contains(queryLower);
                                }).toList();

                                final rows = filteredDataPegawai
                                    .skip(_currentPagepegawai *
                                        _rowsPerPagepegawai)
                                    .take(_rowsPerPagepegawai)
                                    .map((map) {
                                  return DataRow(cells: [
                                    DataCell(
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showEmployeeDetails(context, map);
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
                                      "${map['fname']} ${map['lname']}",
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
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]);
                                }).toList();
                                return ListView(
                                  children: [
                                    DataTable(
                                      headingRowColor:
                                          MaterialStateColor.resolveWith(
                                        (states) => Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      columnSpacing: 20,
                                      dataRowColor:
                                          MaterialStateColor.resolveWith(
                                        (states) => Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                      dataTextStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 16,
                                      ),
                                      headingTextStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      columns: const <DataColumn>[
                                        DataColumn(
                                          label: Text('Email'),
                                        ),
                                        DataColumn(
                                          label: Text('Full Name'),
                                        ),
                                        DataColumn(
                                          label: Text('Role'),
                                        ),
                                        DataColumn(
                                          label: Text('Hapus Pegawai'),
                                        ),
                                      ],
                                      rows: rows,
                                    ),
                                  ],
                                );
                              } else if (snapshot.hasError) {
                                return Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(color: Colors.white),
                                );
                              } else {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _currentPagepegawai > 0
                                  ? () {
                                      setState(() {
                                        _currentPagepegawai--;
                                      });
                                    }
                                  : null,
                              icon: Icon(Icons.arrow_back_ios, size: 16),
                              label: Text("Previous"),
                            ),
                          ),
                          Text(
                            "Page ${_currentPagepegawai + 1} of ${(_filteredDataPegawai.length / _rowsPerPagepegawai).ceil()}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: (_currentPagepegawai + 1) *
                                          _rowsPerPagepegawai <
                                      _filteredDataPegawai.length
                                  ? () {
                                      setState(() {
                                        _currentPagepegawai++;
                                      });
                                    }
                                  : null,
                              icon: Icon(Icons.arrow_forward_ios, size: 16),
                              label: Text("Next"),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.email, color: Colors.grey[300]),
                      ),
                    ),
                    SizedBox(height: 16.0),
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
                            visiblepass
                                ? Icons.visibility
                                : Icons.visibility_off,
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
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 5, horizontal: 20),
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
                                tambahpegawai(
                                    email.text,
                                    pass.text,
                                    fname.text,
                                    lname.text,
                                    alamat.text,
                                    no_telp.text,
                                    value);
                                fetchUser();
                                getUsers();
                                setState(() {
                                  showToast(context, 'Berhasil tambah data');
                                  email.text = "";
                                  pass.text = "";
                                  fname.text = "";
                                  lname.text = "";
                                  alamat.text = "";
                                  no_telp.text = "";
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DeliveryHistoryScreen()));
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
                                      builder: (context) => DaftarCabang()));
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
                            flushCache();
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
                                      flushCache();
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
