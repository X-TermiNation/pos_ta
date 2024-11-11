import 'package:flutter/material.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';

String convertToWIB(String utcDateTimeString) {
  DateTime utcDateTime = DateTime.parse(utcDateTimeString);
  DateTime wibDateTime = utcDateTime.add(Duration(hours: 7));
  String formattedDate = "${wibDateTime.day.toString().padLeft(2, '0')} "
      "${_getMonthName(wibDateTime.month)} "
      "${wibDateTime.year}, "
      "${wibDateTime.hour.toString().padLeft(2, '0')}:"
      "${wibDateTime.minute.toString().padLeft(2, '0')}";
  return "$formattedDate WIB";
}

String _getMonthName(int month) {
  const monthNames = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];
  return monthNames[month - 1];
}

class ConversionHistoryScreen extends StatefulWidget {
  final String idCabang;

  const ConversionHistoryScreen({Key? key, required this.idCabang})
      : super(key: key);

  @override
  _ConversionHistoryScreenState createState() =>
      _ConversionHistoryScreenState();
}

class _ConversionHistoryScreenState extends State<ConversionHistoryScreen> {
  late Future<List<dynamic>> _historyList;
  String _searchText = '';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _historyList = fetchConversionHistory(widget.idCabang);
  }

  // Filter the list based on search query and date range
  List<dynamic> _filterHistory(List<dynamic> historyList) {
    List<dynamic> filteredHistory = historyList;

    if (_searchText.isNotEmpty) {
      filteredHistory = filteredHistory.where((history) {
        String barangName = history['barang_id'] != null
            ? history['barang_id']['nama_barang']?.toLowerCase() ?? ''
            : '';
        return barangName.contains(_searchText.toLowerCase());
      }).toList();
    }

    if (_selectedDateRange != null) {
      filteredHistory = filteredHistory.where((history) {
        DateTime historyDate = DateTime.parse(history['tanggal_konversi']);
        return historyDate.isAfter(_selectedDateRange!.start) &&
            historyDate.isBefore(_selectedDateRange!.end);
      }).toList();
    }

    return filteredHistory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversion History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (query) {
                      setState(() {
                        _searchText = query;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search by Barang Name',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Tooltip(
                  message: "Range Tanggal Filter", // Tooltip message
                  child: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      // Set the maximum end date to today
                      final DateTime today = DateTime.now();
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: today, // Max end date is today
                        initialDateRange: _selectedDateRange,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              primaryColor: Colors.blue,
                              buttonTheme: ButtonThemeData(
                                textTheme: ButtonTextTheme.primary,
                              ),
                              // We can only adjust the general style here
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != _selectedDateRange) {
                        setState(() {
                          _selectedDateRange = picked;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _historyList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("No conversion history found."));
                } else {
                  final historyList = snapshot.data!;
                  final filteredHistory = _filterHistory(historyList);

                  return ListView.builder(
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final history = filteredHistory[index];
                      String utcDateTimeString = history['tanggal_konversi'];
                      String timezone = convertToWIB(utcDateTimeString);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: searchItemByID(history['barang_id']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListTile(
                                title: Text("Date: $timezone"),
                                subtitle: Text("Loading item data..."),
                              );
                            } else if (snapshot.hasError) {
                              return ListTile(
                                title: Text("Date: $timezone"),
                                subtitle: Text("Error fetching item data"),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data == null) {
                              return ListTile(
                                title: Text("Date: $timezone"),
                                subtitle: Text("Item not found"),
                              );
                            }

                            final itemData = snapshot.data!;
                            return ListTile(
                              title: Text("Date: $timezone"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Barang Name: ${itemData['nama_barang'] ?? 'N/A'}"),
                                  Text(
                                      "Barang ID: ${itemData['_id'] ?? 'N/A'}"),
                                  Text(
                                      "From ${history['satuan_asal']} (${history['jumlah_awal_sa']} to ${history['jumlah_akhir_sa']})"),
                                  Text(
                                      "To ${history['satuan_tujuan']} (${history['jumlah_awal_st']} to ${history['jumlah_akhir_st']})"),
                                  if (history['jumlah_sisa'] != null)
                                    Text(
                                        "Remaining: ${history['jumlah_sisa']}"),
                                  SizedBox(height: 8),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
