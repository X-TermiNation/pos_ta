import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/manager/managermenu.dart';
import 'package:ta_pos/view/cabang/dashboardOwner.dart';
import 'package:ta_pos/view-model-flutter/gudang_controller.dart';
import 'package:ta_pos/view-model-flutter/cabang_controller.dart';

class OwnerMenu extends StatefulWidget {
  const OwnerMenu({super.key});

  @override
  State<OwnerMenu> createState() => _OwnerMenuState();
}

class _OwnerMenuState extends State<OwnerMenu> {
  List<Map<String, dynamic>> datacabang = [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    fetchDataCabang();
  }

  Future<void> fetchDataCabang() async {
    try {
      List<Map<String, dynamic>> fetchedData = await getallcabang();
      setState(() {
        datacabang = fetchedData;
      });
    } catch (e) {
      print('Fetch cabang error: $e');
    }
  }

  void handleCabangSelected(int? index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> masukCabang() async {
    if (_selectedIndex == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: const Text('Wajib pilih satu cabang terlebih dahulu!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }

    final dataStorage = GetStorage();
    dataStorage.write('id_cabang', datacabang[_selectedIndex!]['_id']);
    await getdatagudang();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerMenu()),
    );
  }

  void masukSebagaiOwner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerDashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Cabang Usaha'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Silakan pilih salah satu cabang untuk dikelola:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: datacabang.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cabang = datacabang[index];
                    return RadioListTile<int>(
                      value: index,
                      groupValue: _selectedIndex,
                      title: Text(cabang['nama_cabang'] ?? ''),
                      onChanged: handleCabangSelected,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.store),
                    onPressed: masukCabang,
                    label: const Text("Masuk Cabang"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.dashboard_customize),
                    onPressed: masukSebagaiOwner,
                    label: const Text("Dashboard Owner"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
