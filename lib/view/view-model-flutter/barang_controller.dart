import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/view-model-flutter/gudang_controller.dart';

//cari barang dari id
Future<Map<String, dynamic>?> searchItemByID(String idBarang) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  String id_gudang = dataStorage.read('id_gudang');
  final String baseUrl =
      'http://localhost:3000/barang/searchItem'; // Adjust as needed
  final String url = '$baseUrl/$id_cabang/$id_gudang/$idBarang';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Parse the JSON response if successful
      return jsonDecode(response.body);
    } else {
      print('Error: ${response.statusCode} ${response.body}');
      return null; // Return null if item is not found or there's an error
    }
  } catch (e) {
    print('Failed to fetch item: $e');
    return null; // Return null in case of any exception
  }
}

//tambah barang
void addbarang(
  DateTime insertedDate,
  bool noExp,
  String nama_barang,
  String katakategori,
  String nama_satuan,
  String jumlah_satuan,
  String isi_satuan,
  String harga_satuan,
  String id_supplier,
  BuildContext context,
  XFile? selectedImage,
) async {
  if (nama_barang.isEmpty ||
      katakategori.isEmpty ||
      nama_satuan.isEmpty ||
      jumlah_satuan.isEmpty ||
      isi_satuan.isEmpty ||
      harga_satuan.isEmpty) {
    showToast(context, 'Pastikan semua field terisi dengan benar');
    return;
  }
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');

  try {
    String? expDateString;
    String? creationDateString;
    getdatagudang();
    String id_gudangs = dataStorage.read('id_gudang');

    final requestjenis = Uri.parse(
        'http://localhost:3000/barang/getjenisfromkategori/$katakategori');
    final datajenis = await http.get(requestjenis);
    final jenis = json.decode(datajenis.body);

    if (!noExp) {
      insertedDate = insertedDate.add(Duration(days: 1));
      expDateString = insertedDate.toIso8601String();
    } else {
      expDateString = '';
    }

    DateTime creationDate = DateTime.now();
    creationDateString = creationDate.toIso8601String();

    final Barangdata = {
      'nama_barang': nama_barang,
      'jenis_barang': jenis["data"]["nama_jenis"].toString(),
      'kategori_barang': katakategori,
      'insert_date': creationDateString,
      'exp_date': expDateString,
    };

    final url = 'http://localhost:3000/barang/addbarang/$id_gudangs/$id_cabang';
    var request = http.MultipartRequest('POST', Uri.parse(url));

    request.fields.addAll(
      Barangdata.map((key, value) => MapEntry(key, value.toString())),
    );

    // Add the selected image as a file if available
    if (selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'gambar_barang', selectedImage.path));
    } else {
      request.fields['gambar_barang'] = '';
    }

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);
    final Map<String, dynamic> jsonData = json.decode(responseData.body);

    if (responseData.statusCode == 200) {
      if (jsonData.containsKey('data')) {
        Map<String, dynamic> data = jsonData["data"];
        String id_barang = data['_id'];

        // Call addsatuan and get the newly added satuan _id
        String? newSatuanId = await addsatuan(id_barang, nama_satuan,
            jumlah_satuan, harga_satuan, isi_satuan, context);

        if (newSatuanId != null) {
          print('Newly added satuan _id: $newSatuanId');

          final baseSatuanUrl =
              'http://localhost:3000/barang/addinitialsatuan/$id_gudangs/$id_cabang/$id_barang/$newSatuanId';
          final updateResponse = await http.put(Uri.parse(baseSatuanUrl));

          if (updateResponse.statusCode == 200) {
            print('Base Satuan updated successfully');

            await insertHistoryStok(
                id_barang: id_barang,
                satuan_id: newSatuanId,
                tanggal_pengisian: DateTime.now(),
                jumlah_input: int.parse(jumlah_satuan),
                jenis_pengisian: "Initial",
                sumber_transaksi_id: id_supplier,
                id_cabang: id_cabang);

            showToast(context, 'Berhasil menambah data');
          } else {
            print('Failed to update Base Satuan: ${updateResponse.statusCode}');
          }
        } else {
          print('Failed to add satuan');
        }
      } else {
        print('Unexpected response format: ${responseData.body}');
      }
    } else {
      showToast(context, "Gagal menambahkan data");
      print('HTTP Error: ${responseData.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request barang: $error');
  }
}

//get barang
Future<List<Map<String, dynamic>>> getBarang(String idgudang) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final request =
      Uri.parse('http://localhost:3000/barang/baranglist/$idgudang/$id_cabang');
  final response = await http.get(request);
  if (response.statusCode == 200 || response.statusCode == 304) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    print("ini data barang dari cabang: $data");
    return data.cast<Map<String, dynamic>>();
  } else {
    CustomToast(message: "Failed to load data barang: ${response.statusCode}");
    return [];
  }
}

//delete barang
void deletebarang(String id) async {
  final dataStorage = GetStorage();
  final id_cabang = dataStorage.read("id_cabang");
  final id_gudang = dataStorage.read("id_gudang");
  final url =
      'http://localhost:3000/barang/deletebarang/$id_gudang/$id_cabang/$id';
  final response = await http.delete(Uri.parse(url));
  if (response.statusCode == 200) {
    print('Data deleted successfully');
  } else {
    print('Error deleting data. Status code: ${response.statusCode}');
  }
}

//update barang
void UpdateBarang(String id,
    {String? nama_barang,
    String? jenis_barang,
    String? kategori_barang,
    String? insert_date,
    String? exp_date}) async {
  final Map<String, dynamic> updatedBarangData = {};
  updatedBarangData['_id'] = id;
  if (nama_barang != null) updatedBarangData['nama_barang'] = nama_barang;
  if (jenis_barang != null) updatedBarangData['jenis_barang'] = jenis_barang;
  if (kategori_barang != null)
    updatedBarangData['kategori_barang'] = kategori_barang;
  if (insert_date != null) updatedBarangData['insert_date'] = insert_date;
  if (exp_date != null) updatedBarangData['exp_date'] = exp_date;

  final dataStorage = GetStorage();
  final id_cabang = dataStorage.read("id_cabang");
  final id_gudang = dataStorage.read("id_gudang");
  final url = 'http://localhost:3000/barang/updatebarang/$id_gudang/$id_cabang';

  try {
    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        '_id': id,
        ...updatedBarangData,
      }),
    );

    if (response.statusCode == 200) {
      // Data updated successfully
      CustomToast(message: 'Data updated successfully');
    } else {
      // Error occurred during data update
      print('Error updating data. Status code: ${response.statusCode}');
    }
  } catch (error) {
    print('Error: $error');
  }
}

//kategori
//add kategori
//function add
void addkategori(String nama_kategori, String selectedvalueJenis,
    BuildContext context) async {
  try {
    final Kategoridata = {
      'nama_kategori': nama_kategori,
      'id_jenis': selectedvalueJenis,
    };
    final url = 'http://localhost:3000/barang/tambahkategori';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(Kategoridata),
    );
    if (response.statusCode == 200) {
      showToast(context, 'berhasil tambah data');
      getKategori();
    } else if (selectedvalueJenis.isEmpty) {
      showToast(context, "jenis tidak ada");
      print(response.statusCode);
    } else {
      showToast(context, "gagal menambahkan data");
      print(response.statusCode);
    }
  } catch (e) {
    print(e);
  }
}

//get kategori
Future<List<Map<String, dynamic>>> getKategori() async {
  final url = 'http://localhost:3000/barang/getkategori';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200 || response.statusCode == 304) {
    print('berhasil akses data');
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Gagal mengambil data dari server');
  }
}

Future<String> getFirstKategoriId() async {
  final url = 'http://localhost:3000/barang/getfirstkategori';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200 || response.statusCode == 304) {
    print('berhasil akses data kategori pertama');
    final Map<String, dynamic> jsonData = json.decode(response.body);
    print('API Response: $jsonData');
    if (jsonData.containsKey("data") && jsonData["data"] != null) {
      final Map<String, dynamic> data = jsonData["data"];
      if (data.isNotEmpty && data.containsKey("_id")) {
        String temp = data["_id"].toString();
        return data["_id"].toString();
      } else {
        throw Exception('No data available');
      }
    } else {
      // Handle the case where data is null or not present
      print("The 'data' field is null or not present.");
      return '';
    }
  } else {
    print(
        'API Error: ${response.statusCode} - ${response.body}'); // Log the error response
    throw Exception('Gagal mengambil data dari server');
  }
}

Future<void> fetchDataKategori() async {
  try {
    final items = await getKategori();
    print("ini data Kategori :$items");
  } catch (error) {
    print('Error: $error');
  }
}

Future<Map<String, String>> getNamaKategoriMap(
    List<Map<String, dynamic>> array) async {
  final map = Map<String, String>();
  final objects = await array;
  for (final object in objects) {
    map[object['_id']] = object['nama_kategori'];
  }
  return map;
}

Future<Map<String, String>> getmapkategori() async {
  final Kategori = await getKategori();
  final namaKategoriMap = await getNamaKategoriMap(Kategori);
  print(namaKategoriMap);
  return namaKategoriMap;
}

//jenis

//add jenis
void addjenis(String nama_jenis, BuildContext context) async {
  final Jenisdata = {
    'nama_jenis': nama_jenis,
  };
  final url = 'http://localhost:3000/barang/tambahjenis';
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(Jenisdata),
  );
  if (response.statusCode == 200) {
    showToast(context, 'berhasil tambah data');
  } else {
    showToast(context, "gagal menambahkan data");
  }
}

Future<List<Map<String, dynamic>>> getJenis() async {
  final url = 'http://localhost:3000/barang/getjenis';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200 || response.statusCode == 304) {
    print('berhasil akses data jenis');
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Gagal mengambil data dari server');
  }
}

Future<String> getFirstJenisId() async {
  final url = 'http://localhost:3000/barang/getfirstjenis';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200 || response.statusCode == 304) {
    print('berhasil akses data jenis pertama');
    final Map<String, dynamic> jsonData = json.decode(response.body);
    print('API Response: $jsonData');
    final Map<String, dynamic> data = jsonData["data"];
    if (data != null && data.containsKey("_id")) {
      String temp = data["_id"].toString();
      return data["_id"].toString();
    } else {
      throw Exception('No data available');
    }
  } else {
    print(
        'API Error: ${response.statusCode} - ${response.body}'); // Log the error response
    throw Exception('Gagal mengambil data dari server');
  }
}

Future<void> fetchDatajenis() async {
  try {
    final items = await getJenis();
    print("ini data Kategori :$items");
  } catch (error) {
    print('Error: $error');
  }
}

Future<Map<String, String>> getNamaJenisMap(
    List<Map<String, dynamic>> array) async {
  final map = Map<String, String>();
  final objects = await array;
  for (final object in objects) {
    map[object['_id']] = object['nama_jenis'];
  }
  return map;
}

Future<Map<String, Map<String, dynamic>>> getMapFromjenis(
    List<Map<String, dynamic>> list) async {
  final map = <String, Map<String, dynamic>>{};

  for (final item in list) {
    final id = item['_id'];
    if (id is String) {
      map[id] = item;
    }
  }

  return map;
}

Future<Map<String, String>> getmapjenis() async {
  final Jenis = await getJenis();
  final namaJenismap = await getNamaJenisMap(Jenis);
  print(namaJenismap);
  return namaJenismap;
}

//satuan
Future<String?> addsatuan(
    String id_barang,
    String nama_satuan,
    String jumlah_satuan,
    String harga_satuan,
    String isi_satuan,
    BuildContext context) async {
  try {
    final satuandata = {
      'nama_satuan': nama_satuan,
      'jumlah_satuan': jumlah_satuan,
      'harga_satuan': harga_satuan,
      'isi_satuan': isi_satuan
    };
    final dataStorage = GetStorage();
    final id_cabang = dataStorage.read("id_cabang");
    String id_gudangs = dataStorage.read('id_gudang');

    final url =
        'http://localhost:3000/barang/addsatuan/$id_barang/$id_cabang/$id_gudangs';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(satuandata),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      showToast(context, 'Berhasil menambah data');
      return responseData['data']
          ['_id']; // Return only the _id of the newly added satuan
    } else {
      showToast(context, "Gagal menambahkan data");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
  return null; // Return null in case of failure
}

//delete satuan
Future<void> deletesatuan(
    String id_barang, String id_satuan, BuildContext context) async {
  try {
    final dataStorage = GetStorage();
    final id_cabang = dataStorage.read("id_cabang");
    String id_gudangs = dataStorage.read('id_gudang');
    final url =
        'http://localhost:3000/barang/deletesatuan/$id_barang/$id_cabang/$id_gudangs/$id_satuan';

    final response = await http.delete(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      if (context.mounted) {
        showToast(context, 'Berhasil menghapus data');
      }
    } else {
      if (context.mounted) {
        showToast(context, "Gagal menghapus data");
      }
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    if (context.mounted) {
      showToast(context, "Error: $error");
    }
    print('Exception during HTTP request: $error');
  }
}

//update stock satuan
void updatejumlahSatuan(String id_barang, String id_satuan, int jumlah_satuan,
    String action, BuildContext context) async {
  try {
    final satuanUpdatedata = {
      'jumlah_satuan': jumlah_satuan,
      'action': action,
    };
    final dataStorage = GetStorage();
    final id_cabang = dataStorage.read("id_cabang");
    String id_gudangs = dataStorage.read('id_gudang');
    final url =
        'http://localhost:3000/barang/editjumlahsatuan/$id_barang/$id_cabang/$id_gudangs/$id_satuan';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(satuanUpdatedata),
    );

    if (response.statusCode == 200) {
      print('Berhasil menambah data');
    } else {
      showToast(context, "Gagal menambahkan data");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
}

Future<List<Map<String, dynamic>>> getlowstocksatuan(
    BuildContext context) async {
  try {
    final dataStorage = GetStorage();
    final id_cabang = dataStorage.read("id_cabang");
    String id_gudangs = dataStorage.read('id_gudang');
    final url =
        'http://localhost:3000/barang/getlowstocksatuan/$id_cabang/$id_gudangs';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200 || response.statusCode == 304) {
      print('berhasil akses data jenis');
      final Map<String, dynamic> jsonData = json.decode(response.body);
      List<dynamic> data = jsonData["data"];
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Gagal mengambil data dari server');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    return [];
  }
}

Future<List<Map<String, dynamic>>> getsatuan(
    String id_barang, BuildContext context) async {
  try {
    final dataStorage = GetStorage();
    final id_cabang = dataStorage.read("id_cabang");
    String id_gudangs = dataStorage.read('id_gudang');
    final url =
        'http://localhost:3000/barang/getsatuan/$id_barang/$id_cabang/$id_gudangs';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200 || response.statusCode == 304) {
      print('berhasil akses data jenis');
      final Map<String, dynamic> jsonData = json.decode(response.body);
      List<dynamic> data = jsonData["data"];
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Gagal mengambil data dari server');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    return [];
  }
}

//konversi satuan
Future<bool> convertSatuan(
  String id_barang,
  String id_satuanFrom,
  String id_satuanTo,
  int amountToDecrease,
  int amountToIncrease,
  BuildContext context,
) async {
  try {
    final dataStorage = GetStorage();
    final id_cabang = dataStorage.read("id_cabang");
    final id_gudang = dataStorage.read('id_gudang');
    final url =
        'http://localhost:3000/barang/konversi_satuan/$id_barang/$id_cabang/$id_gudang/$id_satuanFrom/$id_satuanTo';

    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amountToDecrease': amountToDecrease,
        'amountToIncrease': amountToIncrease,
      }),
    );

    if (response.statusCode == 200) {
      print('Satuan conversion successful');
      final Map<String, dynamic> jsonData = json.decode(response.body);
      // Optionally handle the response data as needed
      return true; // Indicate success
    } else {
      throw Exception('Failed to convert satuan');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    return false; // Indicate failure
  }
}

Future<Map<String, dynamic>?> getSatuanById(
    String idBarang, String idSatuan, BuildContext context) async {
  try {
    // Fetch id_cabang and id_gudang from GetStorage
    final dataStorage = GetStorage();
    String idCabang = dataStorage.read('id_cabang');
    String idGudang = dataStorage.read('id_gudang');

    // Define the URL with the provided parameters
    final url =
        'http://localhost:3000/barang/searchsatuanbyId/$idCabang/$idGudang/$idBarang/$idSatuan';

    // Make the GET request
    final response = await http.get(Uri.parse(url));

    // Check the status code
    if (response.statusCode == 200) {
      // Parse the JSON response
      final Map<String, dynamic> jsonData = json.decode(response.body);

      // Check if the response contains data
      if (jsonData.containsKey('data')) {
        return jsonData['data'];
      } else {
        showToast(context, 'Data not found');
        return null;
      }
    } else if (response.statusCode == 404) {
      showToast(context, 'Satuan not found');
      return null;
    } else {
      showToast(
          context, 'Failed to fetch data. HTTP Error: ${response.statusCode}');
      return null;
    }
  } catch (error) {
    showToast(context, 'Error: $error');
    print('Exception during HTTP request: $error');
    return null;
  }
}

Future<List<dynamic>> fetchConversionHistory(String idCabang) async {
  final url =
      Uri.parse("http://localhost:3000/barang/getHistoryByCabang/$idCabang");

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Decode the JSON response into a List of history records
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception("Failed to load conversion history");
    }
  } catch (error) {
    print("Error fetching conversion history: $error");
    return [];
  }
}

Future<Map<String, dynamic>> addSupplier(
    Map<String, dynamic> supplierData) async {
  const String apiUrl = "http://localhost:3000/barang/add-supplier";

  try {
    // Send a POST request with the supplier data as JSON
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(supplierData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return {
        "error": "Failed to add supplier",
        "statusCode": response.statusCode,
        "message": response.body,
      };
    }
  } catch (error) {
    return {
      "error": "Failed to connect to the server",
      "exception": error.toString(),
    };
  }
}

//get supplier by cabang
Future<List<Map<String, dynamic>>> fetchSuppliersByCabang() async {
  final getstorage = GetStorage();
  final String? idCabang = getstorage.read('id_cabang');
  final url = Uri.parse('http://localhost:3000/barang/getSuppliers/$idCabang');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> suppliers = json.decode(response.body);
      return suppliers.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 404) {
      print("No suppliers found for cabang ID: $idCabang");
      return [];
    } else {
      print("Error: ${response.statusCode}");
      return [];
    }
  } catch (error) {
    print("Error fetching suppliers: $error");
    return [];
  }
}

//insert stock history
Future<void> insertHistoryStok({
  required String id_barang,
  required String satuan_id,
  required DateTime tanggal_pengisian,
  required int jumlah_input,
  required String jenis_pengisian,
  required String sumber_transaksi_id,
  required String id_cabang,
}) async {
  final url = Uri.parse("http://localhost:3000/barang/insertHistoryStok");

  final data = {
    'cabang_id': id_cabang,
    'barang_id': id_barang,
    'satuan_id': satuan_id,
    'tanggal_pengisian': tanggal_pengisian.toIso8601String(),
    'jumlah_input': jumlah_input,
    'jenis_pengisian': jenis_pengisian,
    'sumber_transaksi_id': sumber_transaksi_id,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      print("HistoryStok entry inserted successfully");
    } else {
      print("Failed to insert HistoryStok entry: ${response.body}");
    }
  } catch (error) {
    print("Error inserting HistoryStok: $error");
  }
}

//get history stock by cabang
Future<List<dynamic>> fetchHistoryStokByCabang(String idCabang) async {
  final url = 'http://localhost:3000/barang/gethistorystok/$idCabang';
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('data')) {
        return data['data'];
      } else {
        print('Unexpected response format: ${response.body}');
        return [];
      }
    } else if (response.statusCode == 404) {
      print('No HistoryStok found for cabang ID: $idCabang');
      return [];
    } else {
      throw Exception('Failed to load HistoryStok data');
    }
  } catch (error) {
    print('Error fetching HistoryStok data: $error');
    return [];
  }
}
