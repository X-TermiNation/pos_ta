import 'package:flutter/material.dart';
import 'package:ta_pos/view-model-flutter/startup_controller.dart';
import 'package:flutter/services.dart';

class daftar_owner2 extends StatefulWidget {
  const daftar_owner2({super.key});

  @override
  State<daftar_owner2> createState() => _daftar_owner2_State();
}

class _daftar_owner2_State extends State<daftar_owner2> {
  // Controller
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
        child: Container(
          padding: const EdgeInsets.all(20.0),
          margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  "Langkah 2/3",
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Daftar Cabang Baru",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nama_cabang,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.store),
                  contentPadding: EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: 'Enter Nama Cabang',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.background,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: alamat_cabang,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on),
                  contentPadding: EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: 'Enter Alamat Cabang',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.background,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: no_telp,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone),
                  contentPadding: EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: 'Enter Nomor Telepon Cabang',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.background,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              SizedBox(height: 40),
              Text(
                "Daftar Gudang Baru",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: alamat_gudang,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.warehouse),
                  contentPadding: EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: 'Enter Alamat Gudang',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.background,
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Pastikan Data yang diinput benar!',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Center(
                child: FilledButton(
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
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text("Next", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
