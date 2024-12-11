import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view/view-model-flutter/cabang_controller.dart';
import 'package:get_storage/get_storage.dart';

class SubmitRequestScreen extends StatefulWidget {
  @override
  _SubmitRequestScreenState createState() => _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends State<SubmitRequestScreen> {
  String? selectedBranchId;
  List<Map<String, dynamic>> branches = [];
  List<Map<String, dynamic>> availableItems = [];
  List<Map<String, dynamic>> items = [];
  String? id_cabang_temp = "";
  String? id_gudang_temp = "";

  @override
  void initState() {
    super.initState();
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    final dataStorage = GetStorage();
    String id_cabang_current = dataStorage.read('id_cabang');
    try {
      final response = await getallcabang(); // Fetch branches
      setState(() {
        // Filter out the current branch
        branches = response
            .where((branch) => branch["_id"] != id_cabang_current)
            .toList();
      });
    } catch (e) {
      print("Error fetching branches: $e");
    }
  }

  Future<void> fetchItems(String? idCabang, String idGudang) async {
    try {
      final response =
          await getBarangMutasi(idCabang, idGudang); // Fetch items by gudang ID
      setState(() {
        availableItems = response;
      });
    } catch (e) {
      print("Error fetching items: $e");
    }
  }

  Future<void> fetchSatuan(
      String? id_cabang, String? id_gudang, String idBarang, int index) async {
    try {
      final response =
          await getsatuanMutasi(id_cabang, id_gudang, idBarang, context);
      setState(() {
        items[index]["satuanOptions"] = response;
      });
    } catch (e) {
      print("Error fetching satuan: $e");
    }
  }

  void addItem() {
    setState(() {
      items.add({
        "item": null,
        "quantity": 0, // Set initial quantity to 0
        "satuan": null,
        "satuanOptions": <Map<String, dynamic>>[],
        "controller":
            TextEditingController(text: "0"), // Initialize controller with 0
      });
    });
  }

  void removeItem(int index) {
    setState(() {
      items[index]["controller"].dispose(); // Dispose of the controller
      items.removeAt(index);
    });
  }

  @override
  void dispose() {
    // Dispose all controllers when the screen is closed
    for (var item in items) {
      item["controller"]?.dispose();
    }
    super.dispose();
  }

  //submit request
  Future<void> submitRequest() async {
    if (selectedBranchId == null || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Please select a branch and add at least one item.")),
      );
      return;
    }

    try {
      final data = {
        "id_cabang_request": GetStorage().read('id_cabang'),
        "id_cabang_confirm": selectedBranchId,
        "tanggal_request": DateTime.now().toIso8601String(),
        "status": "pending",
        "Items": items.map((item) {
          return {
            "nama_item": availableItems.firstWhere((availableItem) =>
                availableItem["_id"] == item["item"])["nama_barang"],
            "id_barang_cabang_confirm": item["item"],
            "nama_satuan": item["satuanOptions"].firstWhere(
                (opt) => opt["_id"] == item["satuan"],
                orElse: () => <String, dynamic>{})["nama_satuan"],
            "id_satuan_cabang_confirm": item["satuan"],
            "jumlah_item": item["quantity"],
          };
        }).toList(),
      };

      final result = await insertMutasiBarang(data);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error atau Barang Tidak Terdaftar Pada Cabang.")),
        );
      }
    } catch (e) {
      print("Error submitting request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi Error!, $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Submit Request"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branch Dropdown
            DropdownButtonFormField<String>(
              value: selectedBranchId,
              hint: Text("Pilih Cabang"),
              onChanged: (value) async {
                setState(() {
                  selectedBranchId = value;
                  availableItems = [];
                  items = []; // Reset items when branch changes
                });
                final selectedBranch =
                    branches.firstWhere((branch) => branch["_id"] == value);
                await fetchItems(value, selectedBranch["Gudang"][0]["_id"]);
                setState(() {
                  id_cabang_temp = value.toString();
                  id_gudang_temp =
                      selectedBranch["Gudang"][0]["_id"].toString();
                });
              },
              items: branches
                  .map((branch) => DropdownMenuItem<String>(
                        value: branch["_id"] as String,
                        child: Text(branch["nama_cabang"] as String),
                      ))
                  .toList(),
              decoration: InputDecoration(
                labelText: "Cabang",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text("Items"),
            SizedBox(height: 10),
            // Items List
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 16.0), // Add spacing here
                    child: Row(
                      children: [
                        // Barang Dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: items[index]["item"],
                            hint: Text("Pilih Barang"),
                            onChanged: (value) async {
                              setState(() {
                                items[index]["item"] = value;
                                items[index]["satuan"] = null; // Reset satuan
                                items[index]
                                    ["satuanOptions"] = []; // Reset options
                              });
                              if (value != null) {
                                await fetchSatuan(id_cabang_temp,
                                    id_gudang_temp, value, index);
                              }
                            },
                            items: availableItems
                                .where((item) =>
                                    !items
                                        .any((e) => e["item"] == item["_id"]) ||
                                    item["_id"] ==
                                        items[index]
                                            ["item"]) // Allow current value
                                .map((item) {
                              return DropdownMenuItem<String>(
                                value: item["_id"] as String,
                                child: Text(item["nama_barang"] as String),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              labelText: "Barang",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        // Satuan Dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: items[index]["satuan"],
                            hint: Text("Pilih Satuan"),
                            onChanged: (value) {
                              setState(() {
                                items[index]["satuan"] = value;
                              });
                            },
                            items: (items[index]["satuanOptions"]
                                    is List<Map<String, dynamic>>)
                                ? (items[index]["satuanOptions"]
                                        as List<Map<String, dynamic>>)
                                    .map((satuan) => DropdownMenuItem<String>(
                                          value: satuan["_id"] as String,
                                          child: Text(
                                              satuan["nama_satuan"] as String),
                                        ))
                                    .toList()
                                : [], // Fallback to an empty list
                            decoration: InputDecoration(
                              labelText: "Satuan",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        // Jumlah Input
                        Expanded(
                          child: TextFormField(
                            controller: items[index]
                                ["controller"], // Use the controller
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Jumlah",
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (value) {
                              final input =
                                  int.tryParse(value) ?? 0; // Parse the input
                              final satuan = items[index]["satuan"];
                              final satuanData =
                                  items[index]["satuanOptions"]?.firstWhere(
                                (opt) => opt["_id"] == satuan,
                                orElse: () => {} as Map<String,
                                    dynamic>, // Cast to Map<String, dynamic>
                              );

                              final maxJumlah =
                                  satuanData != null && satuanData.isNotEmpty
                                      ? satuanData["jumlah_satuan"] ?? 0
                                      : 0;

                              if (input < 0 || input > maxJumlah) {
                                // Invalid input
                                setState(() {
                                  items[index]["quantity"] =
                                      0; // Reset quantity to 0
                                  items[index]["controller"].text =
                                      "0"; // Update controller to 0
                                });

                                // Show an error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Jumlah harus antara 0 dan $maxJumlah")),
                                );
                              } else {
                                // Valid input
                                setState(() {
                                  items[index]["quantity"] = input;
                                });
                              }
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        // Remove Button
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: addItem,
              icon: Icon(Icons.add),
              label: Text("Tambah Item"),
            ),
            SizedBox(height: 20),
            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await submitRequest();
                  print("Selected Branch: $selectedBranchId");
                  print("Items: $items");
                },
                child: Text("Submit Request"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
