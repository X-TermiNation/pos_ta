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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Login To Access your POS'),
                  const SizedBox(
                    height: 30,
                  ),
                  TextFormField(
                    controller: email,
                    onChanged: (value) {
                      setState(() {
                        emailstr = value;
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
                        showToast(
                            context, 'Field password tidak boleh kosong!');
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
                      signcode = await loginbtn(emailstr, pass.text);
                      if (signcode == 1) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ManagerMenu()));
                      } else if (signcode == 2) {
                        edit_selectedvalueKategori = await getFirstKategoriId();
                        setState(() {});
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GudangMenu()));
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
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => login_owner()));
                        },
                        child: Text(
                          'Login as Owner',
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
