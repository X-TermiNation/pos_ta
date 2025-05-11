import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ta_pos/view-model-flutter/startup_controller.dart';

class daftar_owner3 extends StatefulWidget {
  const daftar_owner3({super.key});

  @override
  State<daftar_owner3> createState() => _daftar_owner3_State();
}

class _daftar_owner3_State extends State<daftar_owner3> {
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  TextEditingController fname = TextEditingController();
  TextEditingController lname = TextEditingController();
  TextEditingController alamat = TextEditingController();
  TextEditingController no_telp = TextEditingController();

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              constraints: BoxConstraints(maxWidth: 1200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Langkah 3/3",
                      style: Theme.of(context).textTheme.labelLarge),
                  SizedBox(height: 20),
                  Text("Buat Akun Manager",
                      style: Theme.of(context).textTheme.labelLarge),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: email,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      labelText: 'Enter Email',
                      hintText: 'example@domain.com',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: pass,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      labelText: 'Enter Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fname,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            labelText: 'Enter First Name',
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: lname,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            labelText: 'Enter Last Name',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: alamat,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      labelText: 'Enter Alamat',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: no_telp,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      labelText: 'Enter Nomor Telepon',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  SizedBox(height: 30),
                  FilledButton(
                    onPressed: () {
                      if (email.text.isNotEmpty &&
                          pass.text.isNotEmpty &&
                          fname.text.isNotEmpty &&
                          lname.text.isNotEmpty &&
                          alamat.text.isNotEmpty &&
                          no_telp.text.isNotEmpty) {
                        tambahmanager(
                          email.text,
                          pass.text,
                          fname.text,
                          lname.text,
                          alamat.text,
                          no_telp.text,
                          context,
                        );
                        setState(() {
                          email.clear();
                          pass.clear();
                          fname.clear();
                          lname.clear();
                          alamat.clear();
                          no_telp.clear();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Field tidak boleh kosong!'),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18), // Bigger button
                      minimumSize: Size(150,
                          50), // Optional: ensures button is at least this size
                      textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold), // Bigger text
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Selesai",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
