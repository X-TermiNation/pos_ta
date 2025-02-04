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
  bool isExp,
  String nama_barang,
  String katakategori,
  String nama_satuan,
  String jumlah_satuan,
  String isi_satuan,
  String harga_satuan,
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
    // String? expDateString;
    String? creationDateString;
    getdatagudang();
    String id_gudangs = dataStorage.read('id_gudang');

    final requestjenis = Uri.parse(
        'http://localhost:3000/barang/getjenisfromkategori/$katakategori');
    final datajenis = await http.get(requestjenis);
    final jenis = json.decode(datajenis.body);
    DateTime creationDate = DateTime.now();
    creationDateString = creationDate.toIso8601String();

    final Barangdata = {
      'nama_barang': nama_barang,
      'jenis_barang': jenis["data"]["nama_jenis"].toString(),
      'kategori_barang': katakategori,
      'initial_insert_date': creationDateString,
      'isExp': isExp,
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
        String? newSatuanId = await addsatuan(
            id_barang, nama_satuan, harga_satuan, isi_satuan, context);

        if (newSatuanId != null) {
          print('Newly added satuan _id: $newSatuanId');

          final baseSatuanUrl =
              'http://localhost:3000/barang/addinitialsatuan/$id_gudangs/$id_cabang/$id_barang/$newSatuanId';
          final updateResponse = await http.put(Uri.parse(baseSatuanUrl));

          if (updateResponse.statusCode == 200) {
            print('Base Satuan updated successfully');
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
Future<List<Map<String, dynamic>>> getBarang() async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  String idgudang = dataStorage.read('id_gudang');
  final request =
      Uri.parse('http://localhost:3000/barang/baranglist/$idgudang/$id_cabang');
  final response = await http.get(request);
  if (response.statusCode == 200 || response.statusCode == 304) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    print("ini data barang dari cabang: ${data.length}");
    return data.cast<Map<String, dynamic>>();
  } else {
    CustomToast(message: "Failed to load data barang: ${response.statusCode}");
    return [];
  }
}

//get barang mutasi
Future<List<Map<String, dynamic>>> getBarangMutasi(
    String? idcabang, String idgudang) async {
  final request =
      Uri.parse('http://localhost:3000/barang/baranglist/$idgudang/$idcabang');
  final response = await http.get(request);
  if (response.statusCode == 200 || response.statusCode == 304) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    print("ini data barang dari cabang: ${data.length}");
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
Future<String> addsatuan(String id_barang, String nama_satuan,
    String harga_satuan, String isi_satuan, BuildContext context) async {
  try {
    String jumlah_satuan = "0";
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
  return ""; // Return null in case of failure
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

//update stock satuan(tambah)
void updatejumlahSatuanTambah(
  String idBarang,
  String idSatuan,
  int jumlahSatuan,
  DateTime? expDate,
  String kodeAktivitas,
  String action,
  BuildContext context,
) async {
  try {
    // Periksa apakah barang kadaluarsa
    final barangData = await searchItemByID(idBarang);
    if (barangData == null) {
      showToast(context, "Barang tidak ditemukan");
      return;
    }

    final isKadaluarsa = barangData['isKadaluarsa'] ?? false;

    if (isKadaluarsa && expDate != null) {
      // Tambahkan ke batch jika kadaluarsa
      final dataStorage = GetStorage();
      String id_cabang = dataStorage.read('id_cabang');
      String idgudang = dataStorage.read('id_gudang');
      await addItemBatch(
          idCabang: id_cabang,
          idGudang: idgudang,
          barangId: idBarang,
          satuanId: idSatuan,
          jumlahStok: jumlahSatuan,
          tanggalExp: expDate.toIso8601String());
    }

    if (kodeAktivitas.isNotEmpty && action == 'tambah') {
      // Insert riwayat stok sebelum update
      await insertHistoryStok(
        id_barang: idBarang,
        satuan_id: idSatuan,
        tanggal_pengisian: DateTime.now(),
        jumlah_input: jumlahSatuan,
        jenis_aktivitas: "Masuk",
        Kode_Aktivitas: kodeAktivitas,
        id_cabang: GetStorage().read("id_cabang"),
      );
    }

    // Update jumlah satuan
    final satuanUpdatedata = {
      'jumlah_satuan': jumlahSatuan,
      'action': action,
    };
    final idCabang = GetStorage().read("id_cabang");
    final idGudang = GetStorage().read('id_gudang');
    final url =
        'http://localhost:3000/barang/editjumlahsatuan/$idBarang/$idCabang/$idGudang/$idSatuan';

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

//update jumlah (kurang)
void updatejumlahSatuanKurang(
  String idBarang,
  String idSatuan,
  int jumlahSatuan,
  String kodeAktivitas,
  String action,
  BuildContext context,
) async {
  try {
    if (kodeAktivitas.isNotEmpty && action == 'tambah') {
      // Insert riwayat stok sebelum update
      await insertHistoryStok(
        id_barang: idBarang,
        satuan_id: idSatuan,
        tanggal_pengisian: DateTime.now(),
        jumlah_input: jumlahSatuan,
        jenis_aktivitas: "Masuk",
        Kode_Aktivitas: kodeAktivitas,
        id_cabang: GetStorage().read("id_cabang"),
      );
    }

    // Update jumlah satuan
    final satuanUpdatedata = {
      'jumlah_satuan': jumlahSatuan,
      'action': action,
    };
    final idCabang = GetStorage().read("id_cabang");
    final idGudang = GetStorage().read('id_gudang');
    final url =
        'http://localhost:3000/barang/editjumlahsatuan/$idBarang/$idCabang/$idGudang/$idSatuan';

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

//get satuan mutasi
Future<List<Map<String, dynamic>>> getsatuanMutasi(String? id_cabang,
    String? id_gudangs, String id_barang, BuildContext context) async {
  try {
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
//cek untuk barang kadaluarsa blm ada untuk manage batch
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

    final barangInfo = await searchItemByID(id_barang);
    if (barangInfo == null) {
      showToast(context, "Error: Barang not found");
      return false;
    }

    if (barangInfo['isKadaluarsa'] == true) {
      final conversionrate = amountToIncrease / amountToDecrease;
      await convertBatch(
        cabangId: id_cabang,
        barangId: id_barang,
        oldSatuanId: id_satuanFrom,
        newSatuanId: id_satuanTo,
        conversionRate: conversionrate,
        transferQty: amountToDecrease,
      );
      //update closest batch
      await getClosestBatch(
          idCabang: id_cabang,
          idGudang: id_gudang,
          barangId: id_barang,
          satuanId: id_satuanFrom);
      await getClosestBatch(
          idCabang: id_cabang,
          idGudang: id_gudang,
          barangId: id_barang,
          satuanId: id_satuanTo);
    }
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
      return true;
    } else {
      throw Exception('Failed to convert satuan');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    return false;
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
  required String jenis_aktivitas,
  required String Kode_Aktivitas,
  required String id_cabang,
}) async {
  final getstorage = GetStorage();
  final String? User_email = getstorage.read('email_login');
  final url = Uri.parse("http://localhost:3000/barang/insertHistoryStok");

  final data = {
    'cabang_id': id_cabang,
    'barang_id': id_barang,
    'satuan_id': satuan_id,
    'tanggal_pengisian': tanggal_pengisian.toIso8601String(),
    'jumlah_input': jumlah_input,
    'jenis_aktivitas': jenis_aktivitas,
    'Kode_Aktivitas': Kode_Aktivitas,
    'User_email': User_email
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

//add supplier invoice
Future<Map<String, dynamic>> addInvoiceToSupplier({
  required String supplierId,
  required String invoiceNumber,
}) async {
  final url = Uri.parse(
      'http://localhost:3000/barang/addSupplierInvoice'); // Update with your actual URL if different
  try {
    // Prepare the request body
    final body = jsonEncode({
      'supplierId': supplierId,
      'invoiceNumber': invoiceNumber,
    });

    // Send the POST request
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    // Parse the response
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data; // Contains 'success' and 'message'
    } else {
      return {
        'success': false,
        'message':
            'Failed with status code ${response.statusCode}: ${response.body}',
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'An error occurred: $e'};
  }
}

//search supplier by invoice
Future<Map<String, dynamic>> fetchSupplierByInvoice(
    String invoiceNumber) async {
  const String baseUrl = 'http://localhost:3000/barang'; // Base API URL

  final Uri apiUrl =
      Uri.parse('$baseUrl/searchSupplierByInvoice/$invoiceNumber');

  try {
    // Make GET request
    final response = await http.get(apiUrl);

    // Check response status
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else if (response.statusCode == 404) {
      return {
        'success': false,
        'message': 'Supplier not found with the given invoice number.'
      };
    } else {
      return {
        'success': false,
        'message':
            'Unexpected error occurred. Status code: ${response.statusCode}'
      };
    }
  } catch (error) {
    return {'success': false, 'message': 'An error occurred: $error'};
  }
}

//mutasi
Future<Map<String, dynamic>?> insertMutasiBarang(
    Map<String, dynamic> data) async {
  try {
    final url = Uri.parse('http://localhost:3000/barang/mutasiBarang');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body); // Success response
    } else {
      print(
          'Failed to insert MutasiBarang. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception(
          'Barang Atau Satuan Tidak ada atau Error Terjadi! Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error inserting MutasiBarang: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>?> getMutasiBarangByCabangRequest() async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  try {
    final url = Uri.parse(
        'http://localhost:3000/barang/mutasiBarangRequest/$id_cabang');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
          jsonDecode(response.body)); // Success response
    } else {
      print(
          'Failed to fetch MutasiBarang. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error fetching MutasiBarang: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>?> getMutasiBarangByCabangConfirm() async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final String url =
      'http://localhost:3000/barang/mutasiBarangConfirm/$id_cabang';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else if (response.statusCode == 404) {
      print('No Mutasi Barang found for the given Cabang.');
      return [];
    } else {
      print('Failed to fetch Mutasi Barang: ${response.reasonPhrase}');
      return null;
    }
  } catch (e) {
    print('Error fetching Mutasi Barang: $e');
    return null;
  }
}

Future<void> updateStatusToConfirmed(String mutasiBarangId) async {
  final String url =
      'http://localhost:3000/barang/MutasiChangeConfirmed/$mutasiBarangId';

  try {
    final response = await http.put(Uri.parse(url));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print(responseData['message']); // Success message
    } else {
      print('Failed to update status: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error updating status to confirmed: $e');
  }
}

Future<void> updateStatusToDenied(String mutasiBarangId) async {
  final String url =
      'http://localhost:3000/barang/MutasiChangeDenied/$mutasiBarangId';

  try {
    final response = await http.put(Uri.parse(url));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print(responseData['message']); // Success message
    } else {
      print('Failed to update status: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error updating status to denied: $e');
  }
}

//set status to delivered mutasi
Future<void> updateStatusToDelivered(String mutasiBarangId) async {
  final String updateUrl =
      'http://localhost:3000/barang/MutasiChangeDelivered/$mutasiBarangId';
  try {
    // Fetch MutasiBarang details using the reusable function
    final mutasiData = await fetchMutasiBarangById(mutasiBarangId);

    if (mutasiData == null) {
      throw Exception(
          "Failed to fetch MutasiBarang details for ID: $mutasiBarangId");
    }

    // Check if 'Items' is present and not null
    final items = mutasiData['Items'];
    if (items == null || items.isEmpty) {
      throw Exception(
          "No items found in MutasiBarang with ID: $mutasiBarangId");
    }

    final now = DateTime.now();

    // Insert HistoryStok for both cabang
    for (var item in items) {
      // Print out the item for debugging
      print("Item: $item");

      final idBarangRequest = item['id_barang_cabang_request'];
      final satuanIdRequest = item['id_satuan_cabang_request'];
      final jumlahInput = item['jumlah_item'];

      // Validate if the required fields are not null
      if (idBarangRequest == null ||
          satuanIdRequest == null ||
          jumlahInput == null) {
        print(
            "Missing fields in item: idBarangRequest: $idBarangRequest, satuanIdRequest: $satuanIdRequest, jumlahInput: $jumlahInput");
        throw Exception("Missing required fields in MutasiItems");
      }
      final DateTime nowUtc = DateTime.now().toUtc();
      // Convert to WIB
      final DateTime nowWib = nowUtc.add(Duration(hours: 7));
      final String dateWib =
          "${nowWib.year}${nowWib.month.toString().padLeft(2, '0')}${nowWib.day.toString().padLeft(2, '0')}";
      final String timeWib =
          "${nowWib.hour.toString().padLeft(2, '0')}${nowWib.minute.toString().padLeft(2, '0')}${nowWib.second.toString().padLeft(2, '0')}";

      // Create Kode_Aktivitas using the formatted date and time
      final String kodeAktivitasRequest =
          "TRF_Masuk_${mutasiBarangId}_${dateWib}_${timeWib}";
      final String kodeAktivitasConfirm =
          "TRF_Keluar_${mutasiBarangId}_${dateWib}_${timeWib}";

      // Insert for request cabang (masuk)
      await insertHistoryStok(
        id_barang: idBarangRequest,
        satuan_id: satuanIdRequest,
        tanggal_pengisian: now,
        jumlah_input: jumlahInput,
        jenis_aktivitas: "transfer",
        Kode_Aktivitas: kodeAktivitasRequest,
        id_cabang: mutasiData['id_cabang_request'],
      );

      // Insert for confirm cabang (keluar)
      await insertHistoryStok(
        id_barang: item['id_barang_cabang_confirm'],
        satuan_id: item['id_satuan_cabang_confirm'],
        tanggal_pengisian: now,
        jumlah_input: jumlahInput,
        jenis_aktivitas: "transfer",
        Kode_Aktivitas: kodeAktivitasConfirm,
        id_cabang: mutasiData['id_cabang_confirm'],
      );
      //check kadaluarsa
      var barang = await searchItemByID(item['id_barang_cabang_confirm']);
      if (barang != null && barang['isKadaluarsa'] == true) {
        //mutasi batch manage
        await MutasiBatch(
          senderCabangId: mutasiData['id_cabang_confirm'],
          receiverCabangId: mutasiData['id_cabang_request'],
          barangIdSender: item['id_barang_cabang_confirm'],
          barangIdReceiver: idBarangRequest,
          satuanIdSender: item['id_satuan_cabang_confirm'],
          satuanIdReceiver: satuanIdRequest,
          transferQty: jumlahInput,
        );
        String senderGudang =
            await getIdGudang(mutasiData['id_cabang_confirm']) ?? "Unknown";
        String ReceiverdGudang =
            await getIdGudang(mutasiData['id_cabang_request']) ?? "Unknown";
        //sender/confirm
        await getClosestBatch(
            idCabang: mutasiData['id_cabang_confirm'],
            idGudang: senderGudang,
            barangId: item['id_barang_cabang_confirm'],
            satuanId: item['id_satuan_cabang_confirm']);
        //request/receiver
        await getClosestBatch(
            idCabang: mutasiData['id_cabang_request'],
            idGudang: ReceiverdGudang,
            barangId: idBarangRequest,
            satuanId: satuanIdRequest);
      }
    }

    // Update status to delivered
    final statusResponse = await http.put(Uri.parse(updateUrl));

    if (statusResponse.statusCode != 200) {
      throw Exception(
          'Failed to update status: ${statusResponse.reasonPhrase}');
    }

    // Print success message
    print(jsonDecode(statusResponse.body)['message']);
  } catch (e) {
    print('Error during updateStatusToDelivered: $e');
    throw Exception('Failed to complete updateStatusToDelivered: $e');
  }
}

Future<Map<String, dynamic>?> fetchMutasiBarangById(String id) async {
  final String url = 'http://localhost:3000/barang/getmutasiBarang/$id';
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Successfully fetched data, decode the JSON
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      // Handle "not found" case
      print("MutasiBarang with ID $id not found.");
      return null;
    } else {
      // Handle other error codes
      print("Error: ${response.statusCode} - ${response.reasonPhrase}");
      return null;
    }
  } catch (e) {
    // Handle network or other errors
    print("An error occurred: $e");
    return null;
  }
}

//konversi hierarki
Future<Map<String, dynamic>> insertConversion({
  required String sourceSatuanId,
  required String targetSatuanId,
  required double conversionRate,
}) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  String id_gudang = dataStorage.read('id_gudang');
  final response = await http.post(
    Uri.parse(
        'http://localhost:3000/barang/insert-conversion/$id_cabang/$id_gudang'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'sourceSatuanId': sourceSatuanId,
      'targetSatuanId': targetSatuanId,
      'conversionRate': conversionRate,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    return {
      'success': false,
      'message': 'Failed to insert conversion',
    };
  }
}

//fetch return name
Future<Map<String, dynamic>?> fetchSatuanHierarchyById(String satuanId) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  String id_gudang = dataStorage.read('id_gudang');
  final url =
      'http://localhost:3000/barang/conversions/$id_cabang/$id_gudang/$satuanId';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      print('No conversions found.');
      return null;
    } else {
      print('Failed to load satuan: ${response.reasonPhrase}');
      return null;
    }
  } catch (error) {
    print('Error fetching satuan hierarchy: $error');
    return null;
  }
}

//fetch return ID
Future<List<Map<String, dynamic>>> fetchUnitConversionsWithId(
    String sourceSatuanId, BuildContext context) async {
  final dataStorage = GetStorage();
  String idCabang = dataStorage.read('id_cabang');
  String idGudang = dataStorage.read('id_gudang');

  final url =
      'http://localhost:3000/barang/conversionsID/$idCabang/$idGudang/$sourceSatuanId';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (jsonData['success'] == true && jsonData.containsKey('data')) {
        List<dynamic> data = jsonData['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        showToast(context, 'No conversions found');
        return [];
      }
    } else {
      showToast(context,
          'Failed to fetch conversions. HTTP Error: ${response.statusCode}');
      return [];
    }
  } catch (error) {
    showToast(context, 'Error: $error');
    print('Error fetching unit conversions: $error');
    return [];
  }
}

//fetch conversion by target satuan
Future<Map<String, dynamic>?> fetchConversionByTarget(
    String idBarang, String sourceSatuanId, String targetSatuanId) async {
  final dataStorage = GetStorage();
  String idCabang = dataStorage.read('id_cabang');
  String idGudang = dataStorage.read('id_gudang');
  final String baseUrl =
      "http://localhost:3000/barang/conversionByTarget/$idCabang/$idGudang/$idBarang/$sourceSatuanId/$targetSatuanId";

  try {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data["data"];
    } else if (response.statusCode == 404) {
      print("Conversion not found");
      return null;
    } else {
      print("Failed to fetch conversion: ${response.statusCode}");
      return null;
    }
  } catch (error) {
    print("Error fetching conversion: $error");
    return null;
  }
}

Future<Map<String, dynamic>> addItemBatch({
  required String idCabang,
  required String idGudang,
  required String barangId,
  required String satuanId,
  required int jumlahStok,
  required String tanggalExp,
}) async {
  final String url = 'http://localhost:3000/barang/addItemBatch';

  try {
    final Map<String, dynamic> body = {
      'id_cabang': idCabang,
      'id_gudang': idGudang,
      'barangId': barangId,
      'satuanId': satuanId,
      'jumlahStok': jumlahStok,
      'tanggalExp': tanggalExp,
    };

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );
    await getClosestBatch(
        idCabang: idCabang,
        idGudang: idGudang,
        barangId: barangId,
        satuanId: satuanId);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      return {
        'success': false,
        'message':
            'Failed to add item batch: ${response.statusCode}, ${response.body}',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

Future<Map<String, dynamic>> getClosestBatch({
  required String idCabang,
  required String idGudang,
  required String barangId,
  required String satuanId,
}) async {
  final String url = 'http://localhost:3000/barang/closestBatch';

  try {
    final Uri uri = Uri.parse(url).replace(queryParameters: {
      'id_cabang': idCabang,
      'id_gudang': idGudang,
      'barangId': barangId,
      'satuanId': satuanId,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'], // Closest batch data
        };
      } else {
        return {
          'success': false,
          'message': data['message'],
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Server returned status code ${response.statusCode}',
      };
    }
  } catch (error) {
    return {
      'success': false,
      'message': 'An error occurred: $error',
    };
  }
}

//fetch batch expired in 30 days
Future<List<Map<String, dynamic>>> fetchExpiringBatches() async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  String id_gudang = dataStorage.read('id_gudang');
  final String url =
      'http://localhost:3000/barang/expiringBatches/$id_cabang/$id_gudang';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      final errorResponse = json.decode(response.body);
      print('Error: ${errorResponse['message']}');
      return [];
    }
  } catch (e) {
    print('Error occurred: $e');
    return [];
  }
}

//convert satuan batch management
Future<Map<String, dynamic>> convertBatch({
  required String cabangId,
  required String barangId,
  required String oldSatuanId,
  required String newSatuanId,
  required double conversionRate,
  required int transferQty,
}) async {
  const String apiUrl = "http://localhost:3000/barang/convertBatch";

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "cabang_id": cabangId,
        "barangId": barangId,
        "oldSatuanId": oldSatuanId,
        "newSatuanId": newSatuanId,
        "conversionRate": conversionRate,
        "transferQty": transferQty,
      }),
    );

    if (response.statusCode == 200) {
      return {
        "success": true,
        "data": jsonDecode(response.body),
      };
    } else {
      return {
        "success": false,
        "message":
            jsonDecode(response.body)["message"] ?? "Failed to convert batch.",
      };
    }
  } catch (error) {
    return {
      "success": false,
      "message": "An error occurred: $error",
    };
  }
}

Future<Map<String, dynamic>> MutasiBatch({
  required String senderCabangId,
  required String receiverCabangId,
  required String barangIdSender,
  required String barangIdReceiver,
  required String satuanIdSender,
  required String satuanIdReceiver,
  required int transferQty,
}) async {
  const String baseUrl = "http://localhost:3000/barang/mutasiBatch";

  try {
    // Construct the request body
    final Map<String, dynamic> requestBody = {
      "senderCabangId": senderCabangId,
      "receiverCabangId": receiverCabangId,
      "barangIdSender": barangIdSender,
      "barangIdReceiver": barangIdReceiver,
      "satuanIdSender": satuanIdSender,
      "satuanIdReceiver": satuanIdReceiver,
      "transferQty": transferQty,
    };

    // Make the POST request
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(requestBody),
    );

    // Check if the response is successful
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "success": true,
        "message": data["message"],
        "details": data["details"],
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        "success": false,
        "message": errorData["message"] ?? "Unknown error occurred.",
      };
    }
  } catch (e) {
    // Handle any exceptions
    return {
      "success": false,
      "message": "Failed to call API: ${e.toString()}",
    };
  }
}
