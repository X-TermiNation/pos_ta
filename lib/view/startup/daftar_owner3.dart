import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ta_pos/view/view-model-flutter/startup_controller.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Langkah 3/3",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SizedBox(height: 20),
              Text(
                "Buat Akun Manager",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: email,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: 'Enter Email',
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: pass,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
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
              TextFormField(
                controller: fname,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: 'Enter First Name',
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: lname,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: 'Enter Last Name',
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: alamat,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: 'Enter Alamat',
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: no_telp,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
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
                    email.text = "";
                    pass.text = "";
                    fname.text = "";
                    lname.text = "";
                    alamat.text = "";
                    no_telp.text = "";
                  });
                },
                child: Text("Selesai"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
