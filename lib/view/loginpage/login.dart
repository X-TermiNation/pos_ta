import 'package:flutter/material.dart';
import 'package:ta_pos/view/gudang/gudangmenu.dart';
import 'package:ta_pos/view/loginpage/login_owner.dart';
import 'package:ta_pos/view/manager/managermenu.dart';
import 'dart:async';
import 'package:ta_pos/view/startup/daftar_owner.dart';
import 'package:ta_pos/view/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view/view-model-flutter/user_controller.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';

String emailstr = "";
bool? chkOwner;

class loginscreen extends StatefulWidget {
  const loginscreen({super.key});

  @override
  State<loginscreen> createState() => _loginscreen_state();
}

class _loginscreen_state extends State<loginscreen> {
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();

  @override
  void initState() {
    super.initState();
    showgetstarted();
  }

  // show pop up owner
  Future<void> _showPopup() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Daftar Akun Owner'),
          content: Text('Tekan tombol dibawah untuk membuat akun...'),
          actions: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => daftar_owner()));
                  },
                  child: Icon(Icons.arrow_forward),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  bool _showLoading = true;

  void showgetstarted() async {
    _showLoading = true;
    setState(() {});

    while (chkOwner == null) {
      await getOwner();
      await Future.delayed(
          Duration(milliseconds: 1000)); // Short delay between checks
    }

    _showLoading = false;
    setState(() {});

    // show pop up
    if (chkOwner == false) {
      await Future.delayed(Duration(milliseconds: 100));
      await _showPopup();
    }
  }

  @override
  Widget build(BuildContext context) {
    print("owner status:$chkOwner");
    return Scaffold(
      body: Center(
        child: _showLoading
            ? CircularProgressIndicator()
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Login to Access Your POS',
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
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            showToast(
                                context, 'Field email tidak boleh kosong!');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: pass,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            showToast(
                                context, 'Field password tidak boleh kosong!');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () async {
                          int signcode = 0;
                          signcode = await loginbtn(emailstr, pass.text);
                          if (signcode == 1) {
                            setState(() {
                              logOwner = false;
                            });
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ManagerMenu()));
                          } else if (signcode == 2) {
                            edit_selectedvalueKategori =
                                await getFirstKategoriId();
                            setState(() {});
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GudangMenu()));
                          } else {
                            showToast(context, "Username/Password Salah!");
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
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => login_owner()));
                          },
                          child: Text(
                            'Login as Owner',
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
    );
  }
}
