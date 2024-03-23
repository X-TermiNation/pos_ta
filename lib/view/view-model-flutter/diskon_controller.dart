import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:get_storage/get_storage.dart';
//getdiskon
Future<List<Map<String,dynamic>>> getDiskon() async {
  final request = Uri.parse('http://localhost:3000/barang/diskonlist');
  final response = await http.get(request);
  if (response.body.isEmpty) {
    return [];
  }
  final Map<String, dynamic> jsonData = json.decode(response.body);
  List<dynamic> data = jsonData["data"];
  return data.cast<Map<String, dynamic>>();
}


//fetch data barang diskon
  Future<List<Map<String, dynamic>>> fetchDataDiskonItem(String id_gudangs) async {
    try {
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
    Future<List<Map<String,dynamic>>> getbarangdiskonlist(String id_gudang) async {
      try {
        final dataStorage = GetStorage();
        String id_cabangs = dataStorage.read('id_cabang');
        final request = Uri.parse('http://localhost:3000/barang/baranglist/$id_gudang/$id_cabangs');
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
    Future<void> tambahdiskon(String nama_diskon, String persentase_diskon,String DateStringStart, String DateStringEnd,List<bool> isCheckedList ,List<Map<String, dynamic>> databarang,BuildContext context  ) async{
      try {
        for (var i = 0; i < isCheckedList.length; i++) {
          print("ini isinya :${isCheckedList[i]}");
        }
        final diskonadd = {
          'nama_diskon': nama_diskon,
          'persentase_diskon': persentase_diskon,
          'start_date': DateStringStart,
          'end_date': DateStringEnd,
        };
        
        if (nama_diskon != "" && persentase_diskon != "") {
          final url = 'http://localhost:3000/barang/tambahdiskon';
          final response = await 
          http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json',},
            body: jsonEncode(diskonadd),
          );  
          if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 304) {
            showToast(context, "Berhasil tambah diskon");
            String nmdiskon = nama_diskon.toString();
            final request3 = Uri.parse('http://localhost:3000/barang/diskonlist/$nmdiskon');
            final response3 = await http.get(request3);
            if (response3.statusCode == 200 ||response.statusCode == 204 || response3.statusCode == 304 ) {
              final jsonDiskon = json.decode(response3.body);
              final datadiskon = jsonDiskon["data"];
              
              for (var i = 0; i < isCheckedList.length; i++) {
                print("ini ngulang ${isCheckedList[i]}");
                if (isCheckedList[i] == true) {
                  final diskonadd2 = {
                    'id_reference': databarang[i]['_id'],
                    'nama_barang': databarang[i]['nama_barang'],
                    'jenis_barang': databarang[i]['jenis_barang'],
                    'kategori_barang': databarang[i]['kategori_barang'],
                    'harga_barang': databarang[i]['harga_barang'],
                    'Qty': databarang[i]['Qty'],
                    'exp_date': databarang[i]['exp_date'],
                  };
                  final url2 = 'http://localhost:3000/barang/tambahdiskonbarang/${datadiskon['_id']}/${databarang[i]['_id']}';
                  final response2 = await 
                  http.post(
                    Uri.parse(url2),
                    headers: {'Content-Type': 'application/json',},
                    body: jsonEncode(diskonadd2),
                  );
                  if (response2.statusCode == 200) {
                    showToast(context,"berhasil tambah barang");
                  }else{
                    showToast(context,"gagal tambah barang");
                  }
                }                
              }
            }
            
          } else {
            CustomToast(message:'Gagal menambah data ke server');
          }
        }else{
          CustomToast(message:'Field tidak boleh kosong!') ;
        }
      } catch (e) {
        print('Error tambah diskon: $e');
      }
      
    } 

    //hapus diskon
    void deletediskon(String id) async {
      final url = 'http://localhost:3000/barang/deletediskon/$id';
      final response = await http.delete(Uri.parse(url)); 

        if (response.statusCode == 200) {
          // Data deleted successfully
          print('Data deleted successfully');
          
        } else {
          // Error occurred during data deletion
          print('Error deleting data. Status code: ${response.statusCode}');
        }
    } 

    