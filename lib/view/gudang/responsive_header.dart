import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onMenuItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  IconData generateIcon(int index) {
    switch (index) {
      case 0:
        return Icons.list_alt; // Daftar Barang
      case 1:
        return Icons.add_box; // Tambah Barang
      case 2:
        return Icons.category; // Tambah Kategori dan Jenis Barang
      case 3:
        return Icons.format_list_numbered; // Tambah Satuan Barang
      case 4:
        return Icons.warning; // Stock Alert
      case 5:
        return Icons.swap_horiz; // Mutasi Barang
      default:
        return Icons.more_horiz; // Lainnya
    }
  }

  String generateTooltip(int index) {
    switch (index) {
      case 0:
        return "Daftar Barang";
      case 1:
        return "Tambah Barang";
      case 2:
        return "Tambah Kategori dan Jenis Barang";
      case 3:
        return "Tambah Satuan Barang";
      case 4:
        return "Stock Alert";
      case 5:
        return "Mutasi Barang";
      default:
        return "Lainnya";
    }
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
          child: widget.containers[_currentIndex],
        ),
      ],
    );
  }
}
