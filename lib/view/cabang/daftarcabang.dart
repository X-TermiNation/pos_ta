import 'package:flutter/material.dart';
import 'package:ta_pos/view/cabang/managecabang.dart';
import 'package:ta_pos/view/loginpage/login_owner.dart';
import 'package:ta_pos/view-model-flutter/cabang_controller.dart';

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
      body: Center(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              width: 780,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    height: 320,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              columnSpacing: 40,
                              headingRowColor:
                                  MaterialStateProperty.resolveWith(
                                (states) => Colors.blueGrey.shade800,
                              ),
                              dataRowHeight: 48,
                              horizontalMargin: 24,
                              columns: const [
                                DataColumn(
                                  label: Text('Nama Cabang',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('Alamat',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('No Telp',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('Hapus Cabang',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                              rows: paginatedData.map<DataRow>((map) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(map['nama_cabang'],
                                        style: const TextStyle(
                                            color: Colors.white))),
                                    DataCell(Text(map['alamat'],
                                        style: const TextStyle(
                                            color: Colors.white70))),
                                    DataCell(Text(map['no_telp'],
                                        style: const TextStyle(
                                            color: Colors.white70))),
                                    DataCell(
                                      Visibility(
                                        visible: map['role'] != 'Manager' &&
                                            datacabang.length > 1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            try {
                                              setState(() {
                                                deletecabang(
                                                    map['_id'], context);
                                                fetchdatacabang();
                                              });
                                            } catch (e) {
                                              print("Gagal hapus: $e");
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Text(
                                            'Delete',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                }
                              : null,
                        ),
                        Text('Page ${_currentPage + 1}',
                            style: const TextStyle(color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward,
                              color: Colors.white),
                          onPressed: (_currentPage + 1) * _itemsPerPage <
                                  datacabang.length
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
            ),
          ],
        ),
      ),
    );
  }
}
