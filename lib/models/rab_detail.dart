class RabDetail {
  final int id;
  final int rabId;
  final String? kategori;
  final String uraian;
  final double volume;
  final String satuan;
  final double hargaSatuan;
  final double jumlahTotal;
  final String prioritas;
  final String? keterangan;
  final double? hargaBeli;
  final String? fotoNota;
  final String? tanggalBelanja;
  final bool isTambahan;

  RabDetail({
    required this.id,
    required this.rabId,
    this.kategori,
    required this.uraian,
    required this.volume,
    required this.satuan,
    required this.hargaSatuan,
    required this.jumlahTotal,
    required this.prioritas,
    this.keterangan,
    this.hargaBeli,
    this.fotoNota,
    this.tanggalBelanja,
    this.isTambahan = false,
  });

  factory RabDetail.fromJson(Map<String, dynamic> json) {
    return RabDetail(
      id: json['id'],
      rabId: json['id_rab'],
      kategori: json['kategori'],
      uraian: json['nama_item'] ?? '',
      volume: json['volume'] is String
          ? double.tryParse(json['volume']) ?? 0.0
          : (json['volume'] ?? 0.0).toDouble(),
      satuan: json['satuan'] ?? '',
      hargaSatuan: json['harga_satuan'] is String
          ? double.tryParse(json['harga_satuan']) ?? 0.0
          : (json['harga_satuan'] ?? 0.0).toDouble(),
      jumlahTotal: json['jumlah_total'] is String
          ? double.tryParse(json['jumlah_total']) ?? 0.0
          : (json['jumlah_total'] ?? 0.0).toDouble(),
      prioritas: json['prioritas'] ?? 'Sedang',
      keterangan: json['keterangan'],
      hargaBeli: json['harga_beli'] != null
          ? (json['harga_beli'] is String
                ? double.tryParse(json['harga_beli'])
                : json['harga_beli'].toDouble())
          : null,
      fotoNota: json['nota_path'],
      tanggalBelanja: json['tanggal_belanja'],
      isTambahan: json['is_tambahan'] == 1 || json['is_tambahan'] == true,
    );
  }
}
