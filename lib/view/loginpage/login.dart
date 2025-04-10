import 'package:flutter/material.dart';
import 'package:ta_pos/view/gudang/gudangmenu.dart';
import 'package:ta_pos/view/loginpage/login_owner.dart';
import 'package:ta_pos/view/manager/managermenu.dart';
import 'dart:async';
import 'package:ta_pos/view/startup/daftar_owner.dart';
import 'package:ta_pos/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view-model-flutter/user_controller.dart';
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
  bool passvisibility = false;
  @override
  void initState() {
    super.initState();
    showgetstarted();
  }

  // show pop up owner
  Future<Object?> _showPopup() async {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "OwnerDialog",
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(5), // Sharp edges
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "Daftar Akun Owner",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tekan tombol di bawah untuk membuat akun...",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 45), // Full width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0), // Sharp edges
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => daftar_owner()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Buat Akun",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.black),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
            opacity: anim1, child: child); // Fade-in animation
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
              child: Container(
                width: 400,
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
                      const SizedBox(height: 32),
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
                            showToast(
                                context, 'Field email tidak boleh kosong!');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16), // Consistent spacing
                      TextFormField(
                        controller: pass,
                        obscureText: !passvisibility,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
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
                      const SizedBox(height: 32),
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
                      const SizedBox(height: 30),
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
    ));
  }
}
