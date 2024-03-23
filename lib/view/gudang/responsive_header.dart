import 'package:flutter/material.dart';


class ResponsiveHeader extends StatefulWidget {
  final List<Widget> containers;
  final int initialIndex;

  const ResponsiveHeader({
    Key? key,
    required this.containers,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ResponsiveHeader> createState() => _ResponsiveHeaderState();
}

class _ResponsiveHeaderState extends State<ResponsiveHeader> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }
  String header="";
  int temp = 0;
  void _onHeaderItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  String generatetext(int index){
    if (index == 0) {
      header = "Daftar Barang";
    }else if(index == 1){
      header = "Tambah Barang";
    }else if(index == 2){
      header = "Tambah Kategori dan Jenis Barang";
    }else if(index == 3){
      header = "Tambah Satuan Barang";
    }else if(index == 4){
      header = "Mutasi Barang";
    }else{
       header = "Pengaturan";
    }
    return header;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 1.0,
            ),
          ),
          child:Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < widget.containers.length; i++)
                GestureDetector(
                  onTap: () => _onHeaderItemTapped(i),
                  child: Text(
                    generatetext(i),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: i == _currentIndex
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
        widget.containers[_currentIndex],
      ],
    );
  }

  
}