import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:get_storage/get_storage.dart';
import '../api_config.dart';

//getdiskon
Future<List<Map<String, dynamic>>> getDiskon() async {
  await ApiConfig().refreshConnectionIfNeeded();
  final dataStorage = GetStorage();
  final id_cabangs = dataStorage.read('id_cabang');
  final request =
      Uri.parse('${ApiConfig().baseUrl}/barang/diskonlist/$id_cabangs');
  final response = await http.get(request);
  final Map<String, dynamic> jsonData = json.decode(response.body);
  if (!jsonData.containsKey("data")) {
    return [];
  } else {
    List<dynamic> data = jsonData["data"];
    return data.cast<Map<String, dynamic>>();
  }
}

//fetch data barang diskon
Future<List<Map<String, dynamic>>> fetchDataDiskonItem(
    String id_gudangs) async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    List<Map<String, dynamic>> data = await getbarangdiskonlist(id_gudangs);
    print("data bawaan: $data");
    return data;
  } catch (error) {
    // Handle error
    print('Error: $error');
    throw Exception("error fetch diskon:$error");
  }
}

//barang diskon
Future<List<Map<String, dynamic>>> getbarangdiskonlist(String id_gudang) async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    final dataStorage = GetStorage();
    String id_cabangs = dataStorage.read('id_cabang');
    final request = Uri.parse(
        '${ApiConfig().baseUrl}/barang/baranglist/$id_gudang/$id_cabangs');
    final response = await http.get(request);
    if (response.statusCode == 200 || response.statusCode == 304) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      List<dynamic> data = jsonData["data"];
      print("ini data barang untuk diskon: $data");
      return data.cast<Map<String, dynamic>>();
    } else {
      CustomToast(message: "Data Barang Kosong!");
      return [];
    }
  } catch (e) {
    throw Exception("error:$e");
  }
}

//insert diskon
Future<void> tambahdiskon(
  String nama_diskon,
  String persentase_diskon,
  String DateStringStart,
  String DateStringEnd,
  List<String> selectedBarangIds,
  List<Map<String, dynamic>> databarang,
  BuildContext context,
) async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    final dataStorage = GetStorage();
    String id_cabangs = dataStorage.read('id_cabang');
    String id_gudang = dataStorage.read('id_gudang');

    final diskonadd = {
      'nama_diskon': nama_diskon,
      'id_cabang_reference': id_cabangs,
      'persentase_diskon': persentase_diskon,
      'start_date': DateStringStart,
      'end_date': DateStringEnd,
      'isActive': true,
    };

    if (nama_diskon.isNotEmpty && persentase_diskon.isNotEmpty) {
      final url = '${ApiConfig().baseUrl}/barang/tambahdiskon/$id_cabangs';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(diskonadd),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 304) {
        showToast(context, "Berhasil tambah diskon");

        // Ambil data diskon baru berdasarkan nama diskon dan cabang
        final request3 = Uri.parse(
            '${ApiConfig().baseUrl}/barang/diskonlist/$id_cabangs/$nama_diskon');
        final response3 = await http.get(request3);

        if (response3.statusCode == 200 ||
            response3.statusCode == 204 ||
            response3.statusCode == 304) {
          final jsonDiskon = json.decode(response3.body);
          final datadiskon = jsonDiskon["data"];
          if (datadiskon.isEmpty) {
            showToast(context, "Diskon tidak ditemukan setelah penambahan");
            return;
          }
          final diskonId = datadiskon[0]['_id'];
          for (var idBarang in selectedBarangIds) {
            final barang = databarang.firstWhere(
              (element) => element['_id'] == idBarang,
              orElse: () => <String, dynamic>{},
            );

            if (barang != null) {
              final diskonadd2 = {
                'nama_barang': barang['nama_barang'],
                'id_reference': barang['_id'].toString(),
                'jenis_barang': barang['jenis_barang'],
                'kategori_barang': barang['kategori_barang'],
              };

              final url2 =
                  '${ApiConfig().baseUrl}/barang/tambahdiskonbarang/$diskonId/$idBarang/$id_cabangs/$id_gudang';
              final response2 = await http.post(
                Uri.parse(url2),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(diskonadd2),
              );

              if (response2.statusCode == 200) {
                showToast(context,
                    "Berhasil tambah barang: ${barang['nama_barang']}");
              } else {
                showToast(
                    context, "Gagal tambah barang: ${barang['nama_barang']}");
              }
            } else {
              print("Barang dengan id $idBarang tidak ditemukan di databarang");
            }
          }
        } else {
          showToast(context, "Gagal mengambil data diskon terbaru");
        }
      } else {
        showToast(context, 'Gagal menambah data ke server');
      }
    } else {
      showToast(context, 'Field tidak boleh kosong!');
    }
  } catch (e) {
    print('Error tambah diskon: $e');
    showToast(context, 'Terjadi kesalahan: $e');
  }
}

//hapus diskon
void deletediskon(String id) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final dataStorage = GetStorage();
  String id_cabangs = dataStorage.read('id_cabang');
  final url = '${ApiConfig().baseUrl}/barang/deletediskon/$id/$id_cabangs';
  final response = await http.delete(Uri.parse(url));

  if (response.statusCode == 200) {
    // Data deleted successfully
    print('Data deleted successfully');
  } else {
    // Error occurred during data deletion
    print('Error deleting data. Status code: ${response.statusCode}');
  }
  await getDiskon();
}

//toggle diskon status
Future<void> toggleDiskonStatus(String idDiskon) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final dataStorage = GetStorage();
  String id_cabangs = dataStorage.read('id_cabang');
  final String url =
      '${ApiConfig().baseUrl}/barang/toggleDiskon/$idDiskon/$id_cabangs';
  try {
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Status diskon berhasil diubah: ${data['data']}');
    } else {
      print('Gagal mengubah status diskon: ${response.body}');
    }
  } catch (error) {
    print('Terjadi kesalahan: $error');
  }
}
