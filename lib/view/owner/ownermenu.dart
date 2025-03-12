import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/manager/managermenu.dart';
import 'package:ta_pos/view-model-flutter/gudang_controller.dart';
import 'package:ta_pos/view-model-flutter/cabang_controller.dart';

class ownermenu extends StatefulWidget {
  const ownermenu({super.key});

  @override
  State<ownermenu> createState() => _owner_menu_state();
}

class _owner_menu_state extends State<ownermenu> {
  List<Map<String, dynamic>> datacabang = [];
  int _selectedCheckboxIndex = -1;

  @override
  void initState() {
    super.initState();
    fetchdatacabang();
  }

  Future<void> fetchdatacabang() async {
    try {
      List<Map<String, dynamic>> fetchedData = await getallcabang();
      setState(() {
        datacabang = fetchedData;
      });
    } catch (e) {
      print('fetch cabang error:$e');
    }
  }

  void _onCheckboxChanged(int index, bool? value) {
    setState(() {
      _selectedCheckboxIndex = value! ? index : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
        height: 500,
        width: 500,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Pilih Cabang Yang Tersedia:"),
            Expanded(
              child: ListView.builder(
                itemCount: datacabang.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Checkbox(
                      value: _selectedCheckboxIndex == index,
                      onChanged: (bool? value) {
                        _onCheckboxChanged(index, value);
                      },
                    ),
                    title: Text(datacabang[index]['nama_cabang'] ?? ''),
                    onTap: () {
                      _onCheckboxChanged(
                          index, !(_selectedCheckboxIndex == index));
                    },
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (_selectedCheckboxIndex != -1) {
                  final dataStorage = GetStorage();
                  dataStorage.write(
                      'id_cabang', datacabang[_selectedCheckboxIndex]['_id']);
                  await getdatagudang();
                  setState(() {
                    logOwner = true;
                  });
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ManagerMenu()));
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: Text('Wajib pilih satu cabang!'),
                      );
                    },
                  );
                }
              },
              child: Text("Pilih Cabang"),
            ),
          ],
        ),
      )),
    );
  }
}
