import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ta_pos/view-model-flutter/barang_controller.dart'; // Ensure this import exists

class AddHierarchyPage extends StatefulWidget {
  @override
  _AddHierarchyPageState createState() => _AddHierarchyPageState();
}

class _AddHierarchyPageState extends State<AddHierarchyPage> {
  String? selectedBarang; // Store the name of the selected barang
  String? selectedParentSatuan;
  String? selectedChildSatuan;
  double? conversionRate;

  List<Map<String, dynamic>> satuanList = []; // Data satuan tersedia
  List<Map<String, dynamic>> filteredSatuanList =
      []; // Filtered satuan list for child units
  List<Map<String, dynamic>> hierarchyList = []; // Hierarki satuan
  Map<String, dynamic>? selectedBarangData; // Store the selected barang data

  @override
  void initState() {
    super.initState();
  }

  // Fetch Satuan for the selected Barang
  Future<void> fetchSatuan(String barangId) async {
    try {
      // Get the selected barang data
      selectedBarangData =
          await searchItemByID(barangId); // Fetch the full barang data
      if (selectedBarangData != null) {
        List<Map<String, dynamic>> fetchedSatuan =
            await getsatuan(barangId, context);

        setState(() {
          // Store all satuan that are not the base satuan
          satuanList = fetchedSatuan
              .where((satuan) =>
                  satuan['_id'] !=
                  selectedBarangData!['base_satuan_id']) // Exclude base satuan
              .toList();
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching satuan: $error')));
    }
  }

  // Fetch Hierarchy when a parent satuan is selected
  Future<void> fetchHierarchy(String parentSatuanId) async {
    try {
      final response = await fetchSatuanHierarchyById(parentSatuanId);

      if (response != null) {
        List<Map<String, dynamic>> hierarchyData =
            List<Map<String, dynamic>>.from(response['data'] ?? []);
        setState(() {
          hierarchyList = hierarchyData;
          filteredSatuanList = satuanList
              .where((satuan) => satuan['nama_satuan'] != selectedParentSatuan)
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to fetch hierarchy')));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching hierarchy: $error')));
    }
  }

  // Add conversion logic
  void addConversion() async {
    if (selectedParentSatuan == null ||
        selectedChildSatuan == null ||
        conversionRate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please fill out all fields.')));
      return;
    }

    try {
      // Call the insertConversion API
      final response = await insertConversion(
        sourceSatuanId: selectedParentSatuan!,
        targetSatuanId: selectedChildSatuan!,
        conversionRate: conversionRate!,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conversion added successfully.')));

        // Refresh the hierarchy list
        await fetchHierarchy(selectedParentSatuan!);

        // Reset form fields
        setState(() {
          selectedParentSatuan = null;
          selectedChildSatuan = null;
          conversionRate = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to add conversion: ${response['message']}')));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding conversion: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Hierarki Satuan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Searchable Barang TypeAheadField
            TypeAheadField<Map<String, dynamic>>(
              suggestionsCallback: (pattern) async {
                List<Map<String, dynamic>> barangList = await getBarang();
                return barangList
                    .where((barang) => barang['nama_barang']
                        .toLowerCase()
                        .contains(pattern.toLowerCase()))
                    .toList();
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion['nama_barang']),
                );
              },
              onSelected: (selectedBarang) {
                setState(() {
                  this.selectedBarang = selectedBarang[
                      'nama_barang']; // Store the name instead of ID
                  fetchSatuan(selectedBarang[
                      '_id']); // Fetch related satuan for this barang
                });
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search Barang',
                    border: OutlineInputBorder(),
                    hintText: selectedBarang ?? "Select Barang",
                  ),
                );
              },
            ),

            SizedBox(height: 16.0),

            // Display selected Barang name
            if (selectedBarang != null)
              Text("Selected Barang: $selectedBarang"),

            // Tabel Hierarki
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 800),
                  child: Center(
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Parent Satuan')),
                        DataColumn(label: Text('Child Satuan')),
                        DataColumn(label: Text('Rasio')),
                      ],
                      rows: hierarchyList
                          .map((hierarchy) => DataRow(cells: [
                                DataCell(Text(hierarchy['source'])),
                                DataCell(Text(hierarchy['target'])),
                                DataCell(Text(
                                    hierarchy['conversionRate'].toString())),
                              ]))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.0),

            // Form for adding conversion hierarchy
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedParentSatuan,
                    items: satuanList
                        .map((satuan) => DropdownMenuItem<String>(
                              value: satuan['_id'].toString(),
                              child: Text(satuan['nama_satuan']),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedParentSatuan = value;
                        fetchHierarchy(selectedParentSatuan!);
                      });
                    },
                    decoration: InputDecoration(labelText: 'Satuan Parent'),
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedChildSatuan,
                    items: filteredSatuanList
                        .map((satuan) => DropdownMenuItem<String>(
                              value: satuan['_id'].toString(),
                              child: Text(satuan['nama_satuan']),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedChildSatuan = value;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Satuan Child'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.0),

            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Rasio Konversi'),
              onChanged: (value) {
                setState(() {
                  conversionRate = double.tryParse(value);
                });
              },
            ),

            SizedBox(height: 16.0),

            ElevatedButton(
              onPressed: selectedBarang != null &&
                      selectedParentSatuan != null &&
                      selectedChildSatuan != null &&
                      conversionRate != null &&
                      selectedParentSatuan != selectedChildSatuan
                  ? addConversion
                  : null,
              child: Text('Simpan Konversi'),
            ),
          ],
        ),
      ),
    );
  }
}
