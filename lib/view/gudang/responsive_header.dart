import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/loginpage/login.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onMenuItemTapped(int index) {
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
        return Icons.list_alt; // Daftar Barang
      case 1:
        return Icons.add_box; // Tambah Barang
      case 2:
        return Icons.sync_alt_rounded; //konversi satuan
      case 3:
        return Icons.category; // Tambah Satuan Barang
      case 4:
        return Icons.warning; // Stock Alert
      case 5:
        return Icons.description_outlined; //supplier management
      case 6:
        return Icons.move_down; // Mutasi Barang
      default:
        return Icons.logout_outlined; // Lainnya
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
              onPressed: () {
                Navigator.of(context).pop();
                GetStorage().erase();
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => loginscreen()));
                // Close the dialog
              },
              child: Text('Ya'),
            ),
            TextButton(
              onPressed: () {
                log_out = false;
                Navigator.of(context).pop(); // Close the dialog
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
                      child: Icon(
                        generateIcon(i),
                        color: i == _currentIndex ? Colors.white : Colors.grey,
                        size: 30,
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
