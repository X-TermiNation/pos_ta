import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'package:get/get.dart';

Future<void> triggerCacheAllDataCabang() async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  String id_gudang = dataStorage.read('id_gudang');
  final url = Uri.parse(
      'http://localhost:3000/laporan/RefreshCacheAllDataCabang/$id_gudang/$id_cabang');

  try {
    final response = await http.post(url, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      print("Cache berhasil dibuat untuk cabang dan gudang tersebut.");
    } else {
      print("Gagal memicu cache. Status code: ${response.statusCode}");
    }
  } catch (e) {
    print("Terjadi error saat memicu cache: $e");
  }
}

Future<Map<String, dynamic>> getPendapatanReport({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url =
      Uri.parse('http://localhost:3000/laporan/report/pendapatan/$id_cabang');
  final headers = {"Content-Type": "application/json"};

  final body = jsonEncode({
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
  });

  try {
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "success": true,
        "message": data["message"],
        "data": data["data"],
      };
    } else {
      final error = jsonDecode(response.body);
      return {
        "success": false,
        "message": error["message"] ?? "Unknown error",
      };
    }
  } catch (e) {
    return {
      "success": false,
      "message": "Failed to connect: $e",
    };
  }
}

Future<Map<String, dynamic>> getPengeluaranReport({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url =
      Uri.parse('http://localhost:3000/laporan/report/pengeluaran/$id_cabang');
  final headers = {"Content-Type": "application/json"};

  final body = jsonEncode({
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
  });

  try {
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Response Body: ${response.body}");
      return {
        "success": true,
        "message": "Data retrieved successfully",
        "detail": data["detail"],
        "pengeluaran": data["pengeluaran"],
      };
    } else {
      final error = jsonDecode(response.body);
      return {
        "success": false,
        "message": error["message"] ?? "Unknown error",
      };
    }
  } catch (e) {
    return {
      "success": false,
      "message": "Failed to connect: $e",
    };
  }
}

class OpnameController {
  final String baseUrl = "http://localhost:3000/laporan";

  Future<Map<String, dynamic>> fetchOpnameReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dataStorage = GetStorage();
    String id_cabang = dataStorage.read('id_cabang');
    final url = Uri.parse('$baseUrl/report/opname/$id_cabang');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "startDate": startDate.toIso8601String(),
        "endDate": endDate.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal mengambil laporan opname");
    }
  }
}

class MutasiController {
  Future<Map<String, dynamic>?> fetchMutasi({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dataStorage = GetStorage();
    String id_cabang = dataStorage.read('id_cabang');
    final url =
        Uri.parse('http://localhost:3000/laporan/report/mutasi/$id_cabang');
    final body = jsonEncode({
      "startDate": startDate.toIso8601String(),
      "endDate": endDate.toIso8601String(),
    });

    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load mutasi data: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching mutasi data: $e');
      return null;
    }
  }
}

class AnalisaRevenueController extends GetxController {
  final String baseUrl = "http://localhost:3000/laporan";

  var analisa = <String, dynamic>{}.obs;
  var loading = false.obs;
  var errorMessage = "".obs;

  Future<void> fetchAnalisaRevenueData(DateTime start, DateTime end) async {
    loading.value = true;
    errorMessage.value = "";

    final dataStorage = GetStorage();
    String id_cabang = dataStorage.read('id_cabang') ?? '';

    final url = Uri.parse("$baseUrl/report/analisa-revenue/$id_cabang");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "startDate": start.toIso8601String(),
          "endDate": end.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        analisa.value = data["analisa"];
      } else {
        final error = jsonDecode(response.body)["error"] ?? "Unknown error";
        errorMessage.value = error;
        analisa.value = {};
      }
    } catch (e) {
      errorMessage.value = e.toString();
      analisa.value = {};
    }

    loading.value = false;
  }
}
