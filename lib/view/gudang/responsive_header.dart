import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view-model-flutter/barang_controller.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:ta_pos/view-model-flutter/user_controller.dart';

class ResponsiveSideMenu extends StatefulWidget {
  final List<Widget> containers;
  final int initialIndex;

  const ResponsiveSideMenu({
    Key? key,
    required this.containers,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ResponsiveSideMenu> createState() => _ResponsiveSideMenuState();
}

class _ResponsiveSideMenuState extends State<ResponsiveSideMenu> {
  int _currentIndex = 0;
  bool log_out = false;
  //low stock alert
  int stockAlertCount = 0;
  int expAlertCount = 0;

  Future<void> loadStockAndExpAlertCounts() async {
    try {
      final lowStock = await getlowstocksatuan(context);
      final expiring = await fetchExpiringBatches();

      setState(() {
        stockAlertCount = lowStock.length;
        expAlertCount = expiring.length;
      });
    } catch (e) {
      print("Error loading alert counts: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    loadStockAndExpAlertCounts();
  }

  void _onMenuItemTapped(int index) async {
    await loadStockAndExpAlertCounts();
    if (index == 7) {
      log_out = true;
      showConfirmationDialog(context);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  IconData generateIcon(int index) {
    switch (index) {
      case 0:
        return Icons.list_alt; //Daftar Barang
      case 1:
        return Icons.add_box; //Tambah Barang
      case 2:
        return Icons.sync_alt_rounded; //konversi satuan
      case 3:
        return Icons.category; //Tambah Satuan Barang
      case 4:
        return Icons.warning; //Stock Alert
      case 5:
        return Icons.description_outlined; //supplier management
      case 6:
        return Icons.move_down; //Mutasi Barang
      default:
        return Icons.logout_outlined; //Lainnya
    }
  }

  String generateTooltip(int index) {
    switch (index) {
      case 0:
        return "Daftar Barang";
      case 1:
        return "Tambah Barang";
      case 2:
        return "Konversi Satuan";
      case 3:
        return "Tambah Satuan Barang";
      case 4:
        return "Stock Manager";
      case 5:
        return "Input informasi supplier";
      case 6:
        return "Mutasi Barang";
      default:
        return "Log Out";
    }
  }

  void showConfirmationDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Out'),
          content: Text('Anda Ingin Log Out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    flushCache();
                    GetStorage().erase();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => loginscreen()),
                    );
                  }
                });
              },
              child: Text('Ya'),
            ),
            TextButton(
              onPressed: () {
                log_out = false;
                Navigator.of(context).pop();
              },
              child: Text('Tidak'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 80,
          decoration: BoxDecoration(
            color: Colors.blueGrey[900],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (int i = 0; i < widget.containers.length; i++)
                GestureDetector(
                  onTap: () => _onMenuItemTapped(i),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? Colors.blueAccent
                          : Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Tooltip(
                      message: generateTooltip(i),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            generateIcon(i),
                            color:
                                i == _currentIndex ? Colors.white : Colors.grey,
                            size: 30,
                          ),
                          if (i == 4 && (stockAlertCount + expAlertCount) > 0)
                            Positioned(
                              top: 8,
                              right: 12,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    '${stockAlertCount + expAlertCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
            child: log_out
                ? widget.containers[0]
                : widget.containers[_currentIndex]),
      ],
    );
  }
}
