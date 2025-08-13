// lib/models/detail_pesanan.dart

class DetailPesanan {
  final String produkNama;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal; // <-- PROPERTI BARU DITAMBAHKAN

  DetailPesanan({
    required this.produkNama,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal, // <-- PROPERTI BARU DITAMBAHKAN
  });

  factory DetailPesanan.fromJson(Map<String, dynamic> json) {
    return DetailPesanan(
      produkNama: json['produk_nama'] as String? ?? 'N/A',
      jumlah: json['jumlah'] as int? ?? 0,
      hargaSatuan: (json['harga_satuan'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0, // <-- PARSING BARU
    );
  }
}