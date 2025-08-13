// lib/models/warung.dart
class Warung {
  final int id;
  final String nama;
  final String deskripsi;
  final int pemilikId;

  Warung({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.pemilikId,
  });

  factory Warung.fromJson(Map<String, dynamic> json) {
    // Perbaikan: Tambahkan penanganan null pada 'id' dan 'pemilik_id'
    final idValue = json['id'];
    final pemilikIdValue = json['pemilik_id'];

    if (idValue == null || pemilikIdValue == null) {
      throw FormatException('ID warung atau pemilik tidak boleh null.');
    }

    return Warung(
      id: idValue,
      nama: json['nama'],
      deskripsi: json['deskripsi'] ?? '',
      pemilikId: pemilikIdValue,
    );
  }
}