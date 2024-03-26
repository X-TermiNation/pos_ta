import 'package:flutter/material.dart';
import 'package:ta_pos/view/view-model-flutter/startup_controller.dart';

bool _isValidEmail = false;

class daftar_owner extends StatefulWidget {
  const daftar_owner({super.key});

  @override
  State<daftar_owner> createState() => _daftar_owner_State();
}

class _daftar_owner_State extends State<daftar_owner> {
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  TextEditingController Fname_owner = TextEditingController();
  TextEditingController Lname_owner = TextEditingController();

  bool _validateEmail(String email) {
    RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    email.addListener(() {
      setState(() {
        _isValidEmail = _validateEmail(email.text);
        if (!_isValidEmail) {
          print('format email salah');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Langkah 1/3"),
            SizedBox(
              height: 20,
            ),
            Text("Daftar Akun Owner"),
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
              controller: Fname_owner,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter First Name',
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: Lname_owner,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter Last Name',
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Text(
              'Pastikan Data yang diinput benar!',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
            TextButton(
              onPressed: _isValidEmail
                  ? () {
                      tambahOwner(
                          email.text.toString(),
                          pass.text.toString(),
                          Fname_owner.text.toString(),
                          Lname_owner.text.toString(),
                          context);
                      email.text = "";
                      pass.text = "";
                      Fname_owner.text = "";
                      Lname_owner.text = "";
                      setState(() {});
                    }
                  : null,
              child: Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}
