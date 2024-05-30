import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:ta_pos/view/view-model-flutter/user_controller.dart';

void main() async {
  await GetStorage.init();
  await getOwner().then((value) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyPOS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const loginscreen(),
    );
  }
}
