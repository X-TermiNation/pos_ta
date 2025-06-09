import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:ta_pos/view-model-flutter/gudang_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../api_config.dart';

String idcabangglobal = "";
//verify
Future<void> verify() async {
  await ApiConfig().refreshConnectionIfNeeded();
  String uriString = "${ApiConfig().baseUrl}/user/verify";
  Uri uri = Uri.parse(uriString);
  final response = await http.get(uri);
}

//delete redis cache
Future<void> flushCache() async {
  await ApiConfig().refreshConnectionIfNeeded();
  final dataStorage = GetStorage();

  final id_cabang = dataStorage.read('id_cabang');
  final id_gudang = dataStorage.read('id_gudang');

  if (id_cabang == null || id_gudang == null) {
    print('id_cabang atau id_gudang tidak ditemukan di storage!');
    return;
  }

  final url = Uri.parse(
      '${ApiConfig().baseUrl}/user/flush-cache/$id_cabang/$id_gudang');

  try {
    final response = await http.post(url);

    if (response.statusCode == 200) {
      GetStorage().erase();
      final responseData = json.decode(response.body);
      print('Cache flushed successfully: ${responseData['message']}');
    } else {
      print('Flush cache failed: ${response.statusCode}');
    }
  } catch (error) {
    print('Error flushing cache: $error');
  }
}

//get user
Future<List<Map<String, dynamic>>> getUsers() async {
  await ApiConfig().refreshConnectionIfNeeded();
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    print('Offline: menggunakan lokal.');
  }
  final dataStorage = GetStorage();
  String id_cabangs = dataStorage.read('id_cabang');
  final request = Uri.parse('${ApiConfig().baseUrl}/user/list/$id_cabangs');

  try {
    final response = await http.get(request);
    if (response.body.isEmpty) return [];
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    return data.cast<Map<String, dynamic>>();
  } catch (e) {
    print("Gagal ambil user: $e");
    return [];
  }
}

//get owner
Future<void> getOwner() async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    final Uri uri = await Uri.parse('${ApiConfig().baseUrl}/user/owner');
    final response = await http.get(uri);
    if (response.statusCode == 200 || response.statusCode == 304) {
      chkOwner = true;
    } else {
      chkOwner = false;
    }
  } catch (e) {
    print('Error cek owner: $e');
  }
}

//print data user
Future<void> fetchData() async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    final dataStorage = GetStorage();
    String id_cabangs = dataStorage.read('id_cabang');
    if (id_cabangs.isNotEmpty) {
      final items = await getUsers();
      print("ini data :$items");
    }
  } catch (error) {
    print('Error fetch data: $error');
  }
}

//login
Future<int> loginbtn(String email, String pass) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    print('Offline: menggunakan lokal.');
  }
  String uriString = "${ApiConfig().baseUrl}/user/loginmanager";
  Uri uri = Uri.parse(uriString);
  final response = await http.post(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'email': email,
      'password': pass,
    }),
  );

  if (response.statusCode == 200) {
    int signcode = jsonDecode(response.body)['signcode'];
    idcabangglobal = jsonDecode(response.body)['userCabangId'];
    final dataStorage = GetStorage();
    dataStorage.erase();
    dataStorage.write('id_cabang', idcabangglobal);
    dataStorage.write('email_login', email);
    await getdatagudang();
    print("ini signcode:$signcode");
    return signcode;
  } else {
    CustomToast(message: 'email atau password salah');
    return 0;
  }
}

Future<int> loginOwner(String email, String pass) async {
  await ApiConfig().refreshConnectionIfNeeded();
  String uriString = "${ApiConfig().baseUrl}/user/loginOwner";
  Uri uri = Uri.parse(uriString);
  final response = await http.post(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'email': email,
      'password': pass,
    }),
  );

  if (response.statusCode == 200) {
    int signcode = jsonDecode(response.body)['signcode'];
    return signcode;
  } else {
    CustomToast(message: 'email atau password salah');
    return 0;
  }
}

void tambahOwner(String email, String pass, String fname, String lname) async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    final Owneradd = {
      'email': email,
      'password': pass,
      'fname': fname,
      'lname': lname,
    };

    if (email != "" && pass != "" && fname != "" && lname != "") {
      final url = '${ApiConfig().baseUrl}/user/addOwner';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(Owneradd),
      );
      if (response.statusCode == 200) {
        print('berhasil tambah data pegawai');
      } else {
        print('Gagal menambah data pegawai ke server');
      }
    } else {
      print('Field tidak boleh kosong!');
    }
  } catch (e) {
    print('Error tambah pegawai: $e');
  }
}

//
Future<String> tambahpegawai(
  String email,
  String pass,
  String fname,
  String lname,
  String alamat,
  String no_telp,
  String role,
) async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    final useradd = {
      'email': email,
      'password': pass,
      'fname': fname,
      'lname': lname,
      'alamat': alamat,
      'no_telp': no_telp,
      'role': role,
    };

    final dataStorage = GetStorage();
    String id_cabang = dataStorage.read('id_cabang');

    if (email.isNotEmpty &&
        pass.isNotEmpty &&
        fname.isNotEmpty &&
        lname.isNotEmpty &&
        alamat.isNotEmpty &&
        no_telp.isNotEmpty) {
      final url = '${ApiConfig().baseUrl}/user/addUser/$id_cabang';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(useradd),
      );

      if (response.statusCode == 200) {
        print('Berhasil tambah data pegawai');
        return 'success';
      } else if (response.statusCode == 400) {
        print('email sudah terdaftar sebelumnya!');
        return 'email_exist';
      } else {
        print('Gagal menambah data pegawai ke server');
        return 'server_error';
      }
    } else {
      print('Field tidak boleh kosong!');
      return 'empty_field';
    }
  } catch (e) {
    print('Error tambah pegawai: $e');
    return 'error';
  }
}

//delete user
void deleteuser(String id, BuildContext context) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url = '${ApiConfig().baseUrl}/user/deleteuser/$id/$id_cabang';
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

//update user
void UpdateUser(String fname, String lname, String role, String id,
    BuildContext context) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final updatedUserData = {
    'fname': fname.toString(),
    'lname': lname.toString(),
    'role': role.toString()
  };
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url = '${ApiConfig().baseUrl}/user/updateuser/$id/$id_cabang';
  try {
    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatedUserData),
    );

    if (response.statusCode == 200) {
      // Data updated successfully
      showToast(context, 'Data updated successfully');
    } else {
      // Error occurred during data update
      print('Error updating data. Status code: ${response.statusCode}');
    }
  } catch (error) {
    print('Error update user: $error');
  }
}
