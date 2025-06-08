import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/cabang/daftarcabang.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';
import 'package:ta_pos/view-model-flutter/startup_controller.dart';

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
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        width: 500,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with cancel
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Buat Akun Manager",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Manager form fields
                            ..._buildManagerForm(),

                            const SizedBox(height: 20),

                            // Warning message
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: const Text(
                                "Pastikan data manager lengkap dan valid sebelum menekan tombol Selesai.",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Submit button
                            Center(
                              child: FilledButton.icon(
                                onPressed: () {
                                  final emailPattern = RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                                  if (email.text.isEmpty ||
                                      pass.text.isEmpty ||
                                      fname.text.isEmpty ||
                                      lname.text.isEmpty ||
                                      alamat.text.isEmpty ||
                                      no_telp_manager.text.isEmpty) {
                                    showToast(
                                        context, "Pastikan semua data terisi!");
                                  } else if (!emailPattern
                                      .hasMatch(email.text)) {
                                    showToast(
                                        context, "Format email tidak valid!");
                                  } else {
                                    tambahmanager_Owner(
                                      email.text,
                                      pass.text,
                                      fname.text,
                                      lname.text,
                                      alamat.text,
                                      no_telp_manager.text,
                                      context,
                                    );
                                    final dataStorage = GetStorage();
                                    setState(() {
                                      email.text = "";
                                      pass.text = "";
                                      fname.text = "";
                                      lname.text = "";
                                      alamat.text = "";
                                      no_telp_manager.text = "";
                                      dataStorage.write('switchmode', false);
                                      switchmode =
                                          dataStorage.read('switchmode');
                                    });
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline,
                                    size: 26),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 24),
                                  child: Text(
                                    "Selesai",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blueAccent.shade700,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        width: 500,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Cancel
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Tambah Cabang Baru",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Tooltip(
                                  message: "Batalkan proses tambah",
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.redAccent),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                DaftarCabang()),
                                      );
                                    },
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Form fields
                            ..._buildBranchForm(),

                            const SizedBox(height: 20),

                            // Warning
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: const Text(
                                "Pastikan data benar karena saat menekan tombol, data akan langsung tersimpan!",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Submit button
                            Center(
                              child: FilledButton.icon(
                                onPressed: () {
                                  if (nama_cabang.text.isNotEmpty ||
                                      alamat_cabang.text.isNotEmpty ||
                                      no_telp.text.isNotEmpty ||
                                      alamat_gudang.text.isNotEmpty) {
                                    nambahcabangngudang_Owner(
                                      nama_cabang.text,
                                      alamat_cabang.text,
                                      no_telp.text,
                                      alamat_gudang.text,
                                      context,
                                    );
                                    final dataStorage = GetStorage();
                                    setState(() {
                                      nama_cabang.text = "";
                                      alamat_cabang.text = "";
                                      no_telp.text = "";
                                      alamat_gudang.text = "";
                                      dataStorage.write('switchmode', true);
                                      switchmode =
                                          dataStorage.read('switchmode');
                                    });
                                  } else {
                                    showToast(
                                        context, "Pastikan semua data terisi!");
                                  }
                                },
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 24),
                                  child: Text(
                                    "Simpan Cabang",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blueAccent.shade700,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
        ],
      ),
    );
  }

  List<Widget> _buildManagerForm() {
    return [
      _buildTextField(controller: email, label: 'Enter Email'),
      _buildTextField(
          controller: pass, label: 'Enter Password', obscureText: true),

      // First Name & Last Name in a Row
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: fname,
                label: 'First Name',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: lname,
                label: 'Last Name',
              ),
            ),
          ],
        ),
      ),

      _buildTextField(controller: alamat, label: 'Enter Address'),
      _buildTextField(
        controller: no_telp_manager,
        label: 'Enter Nomor Telepon Manager',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
