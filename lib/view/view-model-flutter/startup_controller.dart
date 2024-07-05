import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ta_pos/view/startup/daftar_owner2.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/startup/daftar_owner3.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:ta_pos/view/view-model-flutter/user_controller.dart';

void tambahOwner(String email, String pass, String fname, String lname,
    BuildContext context) async {
  try {
    final owneradd = {
      'email': email,
      'password': pass,
      'fname': fname,
      'lname': lname,
    };
    final url = 'http://localhost:3000/user/addOwner';
    if (email.isNotEmpty &&
        pass.isNotEmpty &&
        fname.isNotEmpty &&
        lname.isNotEmpty) {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(owneradd),
      );
      if (response.statusCode == 200) {
        showToast(context, 'Berhasil menambah akun!');
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => daftar_owner2()));
      } else {
        showToast(context, 'Gagal menambah data ke server');
      }
    } else {
      showToast(context, 'Field tidak boleh kosong!');
    }
  } catch (e) {
    print('Error: $e');
  }
}

//function nambah cabang dan gudang (gabung jadi satu sj)
void nambahcabangngudang(String nama_cabang, String alamat_cabang,
    String no_telp, String alamat_gudang, BuildContext context) async {
  try {
    final addcabang = {
      'nama_cabang': nama_cabang,
      'alamat': alamat_cabang,
      'no_telp': no_telp,
    };
    if (nama_cabang.isNotEmpty &&
        alamat_cabang.isNotEmpty &&
        alamat_cabang.isNotEmpty &&
        no_telp.isNotEmpty) {
      final url = 'http://localhost:3000/cabang/tambahcabang';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(addcabang),
      );
      if (response.statusCode == 200) {
        String namacabang = nama_cabang;
        final url3 = 'http://localhost:3000/cabang/caricabang/$namacabang';
        final response3 = await http.get(Uri.parse(url3));
        final Map<String, dynamic> jsonData = json.decode(response3.body);
        print(jsonData);
        final idcabang = jsonData["data"][0]["_id"].toString();
        if (jsonData.isNotEmpty) {
          final addgudang = {
            'alamat': alamat_cabang,
          };
          final url2 = 'http://localhost:3000/gudang/tambahgudang/$idcabang';
          final response2 = await http.post(
            Uri.parse(url2),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(addgudang),
          );

          if (response2.statusCode == 200) {
            showToast(context, 'Berhasil menambah akun!');
            final dataStorage = GetStorage();
            dataStorage.write('nama_cabang', nama_cabang);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => daftar_owner3()));
          }
        } else {
          showToast(context, 'data tidak ditemukan');
        }
      } else {
        showToast(context, 'Gagal menambah data ke server');
      }
    } else {
      showToast(context, 'Field tidak boleh kosong!');
    }
  } catch (e) {
    print('Error: $e');
  }
}

//tambah manager
void tambahmanager(String email, String pass, String fname, String lname,
    BuildContext context) async {
  final dataStorage = GetStorage();
  String nama_cabangpass = dataStorage.read('nama_cabang');
  try {
    final url2 = 'http://localhost:3000/cabang/caricabang/$nama_cabangpass';
    final response2 = await http.get(
      Uri.parse(url2),
      headers: {'Cache-Control': 'no-cache'},
    );
    final Map<String, dynamic> jsonDatacabang = json.decode(response2.body);
    String idcabang = jsonDatacabang["data"][0]["_id"].toString();
    if (response2.statusCode == 200) {
      final useradd = {
        'email': email,
        'password': pass,
        'fname': fname,
        'lname': lname,
        'role': "Manager",
      };
      final url = 'http://localhost:3000/user/addUser/$idcabang';
      if (email.isNotEmpty &&
          pass.isNotEmpty &&
          fname.isNotEmpty &&
          lname.isNotEmpty) {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(useradd),
        );
        if (response.statusCode == 200) {
          showToast(context, 'berhasil tambah data');
          nama_cabangpass = "";
          chkOwner = null;
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => loginscreen()));
        } else {
          showToast(context, 'Gagal menambah data ke server');
        }
      } else {
        showToast(context, 'Field tidak boleh kosong!');
      }
    } else {
      showToast(context, " Something Wrong, Error Occured!");
    }
  } catch (e) {
    print('Error: $e');
  }
}
