import 'package:flutter/material.dart';
import 'package:ta_pos/view/view-model-flutter/startup_controller.dart';

class daftar_owner3 extends StatefulWidget {
  const daftar_owner3({super.key});
  @override
  State<daftar_owner3> createState() => _daftar_owner3_State();
}

class _daftar_owner3_State extends State<daftar_owner3> {
  @override
  void initState() {
    super.initState();
  }

  //controller
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  TextEditingController fname = TextEditingController();
  TextEditingController lname = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Langkah 3/3"),
            SizedBox(
              height: 20,
            ),
            Text("Buat Akun Manager"),
            SizedBox(
              height: 10,
            ),
            TextFormField(
              controller: email,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter Email',
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter Password',
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: fname,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter First Name',
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: lname,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter Last Name',
              ),
            ),
            SizedBox(height: 16.0),
            FilledButton(
              onPressed: () {
                tambahmanager(
                    email.text, pass.text, fname.text, lname.text, context);
                setState(() {
                  email.text = "";
                  pass.text = "";
                  fname.text = "";
                  lname.text = "";
                });
              },
              child: Text("Selesai"),
            )
          ],
        ),
      ),
    );
  }
}
