class Gudang {
    final String id;
    final String alamat;
    final String id_cabang;
    Gudang({
      required this.id,
      required this.alamat,
      required this.id_cabang,
    });

    factory Gudang.fromJson(Map<String, dynamic> json) {
      return Gudang(
        id: json['_id'],
        alamat: json['alamat'],
        id_cabang: json['id_cabang'],
      );
    }
  }