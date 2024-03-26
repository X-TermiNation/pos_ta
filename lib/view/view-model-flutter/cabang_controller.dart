import 'package:ta_pos/view/view-model-flutter/models_flutter/user_model.dart';
import 'package:ta_pos/view/view-model-flutter/user_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

Future<String> getdatacabang(String email) async {
  final url = 'http://localhost:3000/user/cariUserbyEmail/$email';
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
