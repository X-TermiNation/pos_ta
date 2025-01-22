import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/cabang/daftarcabang.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view/view-model-flutter/startup_controller.dart';
import 'package:ta_pos/view/view-model-flutter/cabang_controller.dart';

bool switchmode = false;

class managecabang extends StatefulWidget {
  const managecabang({super.key});

  @override
  State<managecabang> createState() => _managecabangState();
}

class _managecabangState extends State<managecabang> {
  TextEditingController nama_cabang = new TextEditingController();
  TextEditingController alamat_cabang = new TextEditingController();
  TextEditingController no_telp = new TextEditingController();
  TextEditingController alamat_gudang = new TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  TextEditingController fname = TextEditingController();
  TextEditingController lname = TextEditingController();
  TextEditingController alamat = TextEditingController();
  TextEditingController no_telp_manager = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Insert Section
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: switchmode
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20, bottom: 10),
                        child: Text("Buat Akun Manager",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                      ..._buildManagerForm(),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20, bottom: 10),
                        child: Text("Tambah Cabang Baru",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                      ..._buildBranchForm(),
                      SizedBox(height: 30),
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                            "Pastikan data benar karena saat menekan tombol, data akan langsung tersimpan!",
                            style: TextStyle(color: Colors.red)),
                      ),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: Tooltip(
                            message: "Cancel Insert",
                            child: FilledButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => DaftarCabang()));
                              },
                              child: Icon(Icons.arrow_back,
                                  color: Colors.black, size: 25),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(10),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildManagerForm() {
    return [
      _buildTextField(controller: email, label: 'Enter Email'),
      _buildTextField(
          controller: pass, label: 'Enter Password', obscureText: true),
      _buildTextField(controller: fname, label: 'Enter First Name'),
      _buildTextField(controller: lname, label: 'Enter Last Name'),
      _buildTextField(controller: alamat, label: 'Enter Address'),
      _buildTextField(
        controller: no_telp_manager,
        label: 'Enter Nomor Telepon Manager',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      SizedBox(height: 10.0),
      Padding(
        padding: EdgeInsets.only(left: 20),
        child: FilledButton(
          onPressed: () {
            if (email.text.isNotEmpty ||
                pass.text.isNotEmpty ||
                fname.text.isNotEmpty ||
                lname.text.isNotEmpty ||
                alamat.text.isNotEmpty ||
                no_telp_manager.text.isNotEmpty) {
              tambahmanager_Owner(email.text, pass.text, fname.text, lname.text,
                  alamat.text, no_telp_manager.text, context);
              final dataStorage = GetStorage();
              setState(() {
                email.text = "";
                pass.text = "";
                fname.text = "";
                lname.text = "";
                alamat.text = "";
                no_telp_manager.text = "";
                dataStorage.write('switchmode', false);
                switchmode = dataStorage.read('switchmode');
              });
            } else {
              showToast(context, "Pastikan semua data terisi!");
            }
          },
          child: Text("Selesai"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[400],
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildBranchForm() {
    return [
      _buildTextField(controller: nama_cabang, label: 'Enter Nama Cabang'),
      _buildTextField(controller: alamat_cabang, label: 'Enter Alamat Cabang'),
      _buildTextField(
        controller: no_telp,
        label: 'Enter Nomor Telepon Cabang',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      SizedBox(height: 30),
      Padding(
        padding: EdgeInsets.only(left: 20),
        child: Text("Input Informasi Gudang",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      SizedBox(height: 10),
      _buildTextField(controller: alamat_gudang, label: 'Enter Alamat Gudang'),
      SizedBox(height: 10),
      Padding(
        padding: EdgeInsets.only(left: 20),
        child: FilledButton(
          onPressed: () {
            if (nama_cabang.text.isNotEmpty ||
                alamat_cabang.text.isNotEmpty ||
                no_telp.text.isNotEmpty ||
                alamat_gudang.text.isNotEmpty) {
              nambahcabangngudang_Owner(nama_cabang.text, alamat_cabang.text,
                  no_telp.text, alamat_gudang.text, context);
              final dataStorage = GetStorage();
              setState(() {
                nama_cabang.text = "";
                alamat_cabang.text = "";
                no_telp.text = "";
                alamat_gudang.text = "";
                dataStorage.write('switchmode', true);
                switchmode = dataStorage.read('switchmode');
              });
            } else {
              showToast(context, "Pastikan semua data terisi!");
            }
          },
          child: Text("Submit"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[400],
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[300]),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
