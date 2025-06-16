import 'package:flutter/material.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:ta_pos/view/owner/ownermenu.dart';
// import 'package:ta_pos/view/gudang/gudangmenu.dart';
// import 'package:ta_pos/view/manager/managermenu.dart';
// import 'dart:async';
//import 'package:ta_pos/view/startup/daftar_owner.dart';
// import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view-model-flutter/user_controller.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';

class login_owner extends StatefulWidget {
  const login_owner({super.key});

  @override
  State<login_owner> createState() => _login_owner_state();
}

class _login_owner_state extends State<login_owner> {
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  bool passvisibility = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: SingleChildScrollView(
        child: Container(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Login Owner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: email,
                  onChanged: (value) {
                    setState(() {
                      emailstr = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      showToast(context, 'Field email tidak boleh kosong!');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: pass,
                  obscureText: !passvisibility,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    labelText: 'Enter Password',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.grey[300]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passvisibility
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey[300],
                      ),
                      onPressed: () {
                        setState(() {
                          passvisibility = !passvisibility;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    int signcode = 0;
                    signcode = await loginOwner(email.text, pass.text);
                    if (email.text.isNotEmpty && pass.text.isNotEmpty) {
                      if (signcode == 1) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => OwnerMenu()));
                      } else {
                        showToast(context, "Username/Password Salah!");
                      }
                    } else {
                      showToast(context, "Field tidak boleh kosong!");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.blue[700],
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => loginscreen()));
                    },
                    child: Text(
                      'Login as Employee',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
