import 'package:flutter/material.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:ta_pos/view/owner/ownermenu.dart';
// import 'package:ta_pos/view/gudang/gudangmenu.dart';
// import 'package:ta_pos/view/manager/managermenu.dart';
// import 'dart:async';
//import 'package:ta_pos/view/startup/daftar_owner.dart';
// import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view/view-model-flutter/user_controller.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';

String emailowner = "";

class login_owner extends StatefulWidget {
  const login_owner({super.key});

  @override
  State<login_owner> createState() => _login_owner_state();
}

class _login_owner_state extends State<login_owner> {
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Login Owner'),
            const SizedBox(
              height: 30,
            ),
            TextFormField(
              controller: email,
              onChanged: (value) {
                setState(() {
                  emailowner = value;
                });
              },
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Enter your Email',
              ),
              validator: (value) {
                if (value == null) {
                  showToast(context, 'Field email tidak boleh kosong!');
                }
                return null;
              },
            ),
            const SizedBox(
              height: 30,
            ),
            TextFormField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Enter your Password',
              ),
              validator: (value) {
                if (value == null) {
                  showToast(context, 'Field password tidak boleh kosong!');
                }
                return null;
              },
            ),
            const SizedBox(
              height: 30,
            ),
            FilledButton(
              onPressed: () async {
                int signcode = 0;
                signcode = await loginOwner(emailowner, pass.text);
                if (signcode == 1) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ownermenu()));
                } else {
                  showToast(context, "Username/Password Salah!");
                }
              },
              child: Text('Login'),
            ),
            SizedBox(
              height: 100,
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 100), // Optional: Add padding if needed
                child: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => loginscreen()));
                  },
                  child: Text(
                    'Login as Employee',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.purple,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
