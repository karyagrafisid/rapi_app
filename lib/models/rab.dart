import 'package:rapi_app/models/rab_detail.dart';

class Rab {
  final int id;
  final String namaRab;
  final String periode;
  final String status;
  final String ttdNama1;
  final String ttdJabatan1;
  final String ttdNama2;
  final String ttdJabatan2;
  final String ttdNama3;
  final String ttdJabatan3;
  final String bank;
  final String rekening;
  final double total;
  final List<RabDetail> details;

  Rab({
    required this.id,
    required this.namaRab,
    required this.periode,
    this.status = 'Pending',
    required this.ttdNama1,
    required this.ttdJabatan1,
    required this.ttdNama2,
    required this.ttdJabatan2,
    required this.ttdNama3,
    required this.ttdJabatan3,
    required this.bank,
    required this.rekening,
    this.total = 0.0,
    this.details = const [],
  });

  factory Rab.fromJson(Map<String, dynamic> json) {
    return Rab(
      id: json['id'],
      namaRab: json['nama_rab'] ?? '',
      periode: json['periode']?.toString() ?? '',
      status: json['status'] ?? 'Pending',
      ttdNama1: json['ttd_nama_1'] ?? '',
      ttdJabatan1: json['ttd_jabatan_1'] ?? '',
      ttdNama2: json['ttd_nama_2'] ?? '',
      ttdJabatan2: json['ttd_jabatan_2'] ?? '',
      ttdNama3: json['ttd_nama_3'] ?? '',
      ttdJabatan3: json['ttd_jabatan_3'] ?? '',
      bank: json['bank'] ?? '',
      rekening: json['rekening'] ?? '',
      total: (json['total_anggaran'] != null)
          ? double.parse(json['total_anggaran'].toString())
          : 0.0,
      details: (json['details'] != null && json['details'] is List)
          ? (json['details'] as List)
                .map((item) => RabDetail.fromJson(item))
                .toList()
          : [],
    );
  }
}

// Mock data
final List<Rab> mockRabs = [
  Rab(
    id: 1,
    namaRab: 'Pengadaan Laptop Staff',
    periode: '2026',
    status: 'Pending',
    ttdNama1: 'Haryo Kusumo, S.T.',
    ttdJabatan1: 'Ketua Panitia',
    ttdNama2: 'Siti Aminah, M.Ak.',
    ttdJabatan2: 'Bendahara',
    ttdNama3: 'Dr. Ahmad Fauzi',
    ttdJabatan3: 'Dekan',
    bank: 'BSI',
    rekening: '7123456789',
    total: 25000000.0,
  ),
  Rab(
    id: 2,
    namaRab: 'Seminar Nasional Teknologi',
    periode: '2026',
    status: 'Pending',
    ttdNama1: 'Budi Santoso, M.Kom.',
    ttdJabatan1: 'Ketua Panitia',
    ttdNama2: 'Lina Marlina, S.E.',
    ttdJabatan2: 'Bendahara',
    ttdNama3: 'Prof. Bambang',
    ttdJabatan3: 'Rektor',
    bank: 'Mandiri',
    rekening: '1230009876543',
    total: 15000000.0,
  ),
];
