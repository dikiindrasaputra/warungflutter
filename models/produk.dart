// lib/models/produk.dart

class Produk {
  final int id;
  final String nama;
  final String? deskripsi; // Nullable, sesuai model backend
  final double harga;
  final int stok;
  final String? gambarUrl; // Nullable
  final int warungId;

  Produk({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.harga,
    required this.stok,
    this.gambarUrl,
    required this.warungId,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    // Gunakan operator '??' untuk memberikan nilai default jika data null
    return Produk(
      id: json['id'] as int? ?? 0,
      nama: json['nama'] as String? ?? '',
      deskripsi: json['deskripsi'] as String?,
      harga: (json['harga'] as num?)?.toDouble() ?? 0.0, // Gunakan num? untuk keamanan
      stok: json['stok'] as int? ?? 0,
      gambarUrl: json['gambar_url'] as String?,
      warungId: json['warung_id'] as int? ?? 0,
    );
  }
}