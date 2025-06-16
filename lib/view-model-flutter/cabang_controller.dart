import 'package:flutter/material.dart';
import 'package:ta_pos/view-model-flutter/models_flutter/user_model.dart';
import 'package:ta_pos/view-model-flutter/gudang_controller.dart';
import 'package:ta_pos/view-model-flutter/user_controller.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../api_config.dart';

Future<List<Map<String, dynamic>>> getallcabang() async {
  await ApiConfig().refreshConnectionIfNeeded();
  final url = '${ApiConfig().baseUrl}/cabang/showAllcabang';
  final response = await http.get(Uri.parse(url));
  if (response.body.isEmpty) {
    return [];
  }
  final Map<String, dynamic> jsonData = json.decode(response.body);
  List<dynamic> data = jsonData["data"];
  return data.cast<Map<String, dynamic>>();
}

//delete cabang
void deletecabang(String id, BuildContext context) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final url = '${ApiConfig().baseUrl}/cabang/delete/$id';
  final response = await http.delete(Uri.parse(url));
  if (response.statusCode == 200) {
    // Data deleted successfully
    showToast(context, "Data Berhasil Dihapus!");
    print('Data deleted successfully');
  } else {
    // Error occurred during data deletion
    CustomToast(message: "Terjadi Kesalahan!");
    print('Error deleting data. Status code: ${response.statusCode}');
  }
}

Future<String> getdatacabang(String email) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final url = '${ApiConfig().baseUrl}/user/cariUserbyEmail/$email';
  final response = await http.get(Uri.parse(url));
  // Check the response status code
  if (response.statusCode == 304 || response.statusCode == 200) {
    // The request was successful
    final jsonData = json.decode(response.body);
    final user = User.fromJson(jsonData['data']);
    final id_cabang = user.id_cabang.toString();
    // Return the user's id_cabang
    print("id dari login page:$id_cabang");
    idcabangglobal = user.id_cabang;
    print("ini dari function: $idcabangglobal");
    return idcabangglobal;
  } else {
    // The request failed
    final errorMessage = json.decode(response.body)['message'];
    // Throw an error
    throw Exception('Error fetching user: $errorMessage');
  }
}

Future<List<Map<String, dynamic>>?> getCabangByID(String id) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final String apiUrl = '${ApiConfig().baseUrl}/cabang/caricabangbyID/$id';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 200) {
        return List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        print("Error: ${jsonData['message']}");
        return null;
      }
    } else {
      print("Failed to fetch data. Status code: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Exception occurred: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> fetchCabangStatistikRingkasan({
  required String idCabang,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final url =
      Uri.parse('${ApiConfig().baseUrl}/cabang/statistikringkasan/$idCabang');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      print('Error fetching statistik ringkasan: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Exception fetching statistik ringkasan: $e');
    return null;
  }
}

Future<Map<String, dynamic>> getCabangStatistikRingkasan(
    String idCabang, String startDate, String endDate) async {
  // 1. Dapatkan id_gudang terlebih dahulu
  final String? idGudang = await getIdGudang(idCabang);

  if (idGudang == null) {
    throw Exception('Gagal mendapatkan ID Gudang untuk cabang $idCabang');
  }

  final url = Uri.parse(
      '${ApiConfig().baseUrl}/cabang/getStatistikRingkasan/$idCabang');

  print('Fetching statistik cabang dari: $url');
  print(
      'Start: $startDate, End: $endDate, Gudang ID: $idGudang'); // Tambahkan log idGudang

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    // 2. Sertakan id_gudang dalam body request
    body: jsonEncode({
      'startDate': startDate,
      'endDate': endDate,
      'id_gudang': idGudang, // <-- Tambahkan ini!
    }),
  );

  print('Response Status: ${response.statusCode}');
  print('Response Body: ${response.body}');

  if (response.statusCode == 200) {
    try {
      final decoded = jsonDecode(response.body);
      print('Decoded Response: $decoded');
      return decoded;
    } catch (e) {
      print('JSON Decode Error: $e');
      throw Exception('Gagal decode response statistik cabang');
    }
  } else {
    // Lebih detail saat throw exception
    String errorMessage = 'Gagal mengambil data statistik cabang';
    try {
      final errorBody = jsonDecode(response.body);
      if (errorBody.containsKey('error')) {
        errorMessage = errorBody['error'];
      }
    } catch (e) {
      // Abaikan jika body bukan JSON atau tidak ada 'error'
    }
    throw Exception('$errorMessage (Status: ${response.statusCode})');
  }
}
