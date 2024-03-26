import 'package:flutter/material.dart';
import 'package:ta_pos/view/view-model-flutter/startup_controller.dart';
import 'package:flutter/services.dart';

class daftar_owner2 extends StatefulWidget {
  const daftar_owner2({super.key});

  @override
  State<daftar_owner2> createState() => _daftar_owner2_State();
}

class _daftar_owner2_State extends State<daftar_owner2> {
  //controller
  TextEditingController nama_cabang = TextEditingController();
  TextEditingController alamat_cabang = TextEditingController();
  TextEditingController no_telp = TextEditingController();
  TextEditingController alamat_gudang = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("Langkah 2/3"),
            SizedBox(
              height: 20,
            ),
            Text("Daftar Cabang Baru"),
            SizedBox(
              height: 10,
            ),
            TextFormField(
              controller: nama_cabang,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter Nama Cabang',
              ),
            ),
            SizedBox(
              height: 10,
            ),
            TextFormField(
              controller: alamat_cabang,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter alamat Cabang',
              ),
            ),
            TextFormField(
              controller: no_telp,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter Nomor Telepon Cabang',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            SizedBox(
              height: 50,
            ),
            Text("Daftar Gudang Baru"),
            SizedBox(
              height: 10,
            ),
            TextFormField(
              controller: alamat_gudang,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 25),
                border: UnderlineInputBorder(),
                labelText: 'Enter Alamat Gudang',
              ),
            ),
            SizedBox(
              height: 30,
            ),
            FilledButton(
                onPressed: () {
                  nambahcabangngudang(nama_cabang.text, alamat_cabang.text,
                      no_telp.text, alamat_gudang.text, context);
                  setState(() {
                    alamat_cabang.text = "";
                    no_telp.text = "";
                    alamat_gudang.text = "";
                    nama_cabang.text = "";
                  });
                },
                child: Icon(Icons.arrow_forward))
          ],
        ),
      ),
    );
  }
}
