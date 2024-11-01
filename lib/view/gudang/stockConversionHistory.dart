import 'package:flutter/material.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';

String convertToWIB(String utcDateTimeString) {
  // Parse the UTC timestamp string to DateTime
  DateTime utcDateTime = DateTime.parse(utcDateTimeString);

  // Convert to WIB by adding 7 hours
  DateTime wibDateTime = utcDateTime.add(Duration(hours: 7));

  // Manually format the DateTime to a readable string (e.g., "31 Oct 2024, 17:00")
  String formattedDate = "${wibDateTime.day.toString().padLeft(2, '0')} "
      "${_getMonthName(wibDateTime.month)} "
      "${wibDateTime.year}, "
      "${wibDateTime.hour.toString().padLeft(2, '0')}:"
      "${wibDateTime.minute.toString().padLeft(2, '0')}";

  return "$formattedDate WIB";
}

// Helper function to get month name without locale
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

class ConversionHistoryScreen extends StatelessWidget {
  final String idCabang;

  const ConversionHistoryScreen({Key? key, required this.idCabang})
      : super(key: key);

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
      body: FutureBuilder(
        future: fetchConversionHistory(idCabang), // Fetch history by cabang ID
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No conversion history found."));
          } else {
            final historyList = snapshot.data!;
            return ListView.builder(
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final history = historyList[index];
                String utcDateTimeString =
                    history['tanggal_konversi']; // Get as String
                String timezone = convertToWIB(utcDateTimeString);

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: searchItemByID(
                        history['barang_id']), // Call searchItemByID here
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          title: Text("Date: $timezone"),
                          subtitle: Text("Loading item data..."),
                        );
                      } else if (snapshot.hasError) {
                        return ListTile(
                          title: Text("Date: $timezone"),
                          subtitle: Text("Error fetching item data"),
                        );
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return ListTile(
                          title: Text("Date: $timezone"),
                          subtitle: Text("Item not found"),
                        );
                      }

                      final itemData = snapshot.data!; // Get the item data

                      return ListTile(
                        title: Text("Date: $timezone"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Barang Name: ${itemData['nama_barang'] ?? 'N/A'}"),
                            Text("Barang ID: ${itemData['_id'] ?? 'N/A'}"),
                            Text(
                                "From ${history['satuan_asal']} (${history['jumlah_awal_sa']} to ${history['jumlah_akhir_sa']})"),
                            Text(
                                "To ${history['satuan_tujuan']} (${history['jumlah_awal_st']} to ${history['jumlah_akhir_st']})"),
                            if (history['jumlah_sisa'] != null)
                              Text("Remaining: ${history['jumlah_sisa']}"),
                            SizedBox(height: 8), // Add space between sections
                            // Displaying Barang Name and ID
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
    );
  }
}
