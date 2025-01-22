import 'package:flutter/material.dart';
import 'package:ta_pos/view/cabang/managecabang.dart';
import 'package:ta_pos/view/loginpage/login_owner.dart';
import 'package:ta_pos/view/view-model-flutter/cabang_controller.dart';

class DaftarCabang extends StatefulWidget {
  const DaftarCabang({super.key});

  @override
  State<DaftarCabang> createState() => _DaftarCabangState();
}

class _DaftarCabangState extends State<DaftarCabang> {
  List<Map<String, dynamic>> datacabang = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;

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
      print('Fetch cabang error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < datacabang.length)
        ? startIndex + _itemsPerPage
        : datacabang.length;
    final paginatedData = datacabang.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Daftar Cabang'),
        actions: [
          IconButton(
            tooltip: 'Tambah Cabang',
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => managecabang()));
              print("Tambah Cabang pressed");
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => login_owner()));
              print("Logout pressed");
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.resolveWith(
                    (states) => Colors.blue,
                  ),
                  columns: const <DataColumn>[
                    DataColumn(
                      label: Text(
                        'Nama Cabang',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Alamat',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'No Telp',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Hapus Cabang',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  rows: paginatedData.map<DataRow>((map) {
                    return DataRow(
                      cells: [
                        DataCell(Text(map['nama_cabang'])),
                        DataCell(Text(map['alamat'])),
                        DataCell(Text(map['no_telp'])),
                        DataCell(
                          Visibility(
                            visible: map['role'] != 'Manager',
                            child: ElevatedButton(
                              onPressed: () {
                                print("Hapus cabang ID: ${map['_id']}");
                                try {
                                  setState(() {
                                    deletecabang(map['_id'], context);
                                    fetchdatacabang();
                                  });
                                } catch (e) {
                                  print("Gagal hapus: $e");
                                }
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                ),
                Text('Page ${_currentPage + 1}'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed:
                      (_currentPage + 1) * _itemsPerPage < datacabang.length
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                            }
                          : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
