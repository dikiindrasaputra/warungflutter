// lib/models/pesanan.dart

import 'detail_pesanan.dart';

class Pesanan {
  final int id;
  final String pemesan;
  final String? warungNama;
  final double totalHarga;
  final String tanggalPesanan;
  final String status;
  // Perbaikan: tambahkan properti ini
  final String? alamatPengiriman;
  final List<DetailPesanan> detailPesanan;

  Pesanan({
    required this.id,
    required this.pemesan,
    this.warungNama,
    required this.totalHarga,
    required this.tanggalPesanan,
    required this.status,
    // Perbaikan: tambahkan properti ini
    this.alamatPengiriman,
    required this.detailPesanan,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    var detailListJson = json['detail_pesanan'] as List?;
    List<DetailPesanan> details = [];
    if (detailListJson != null) {
      details = detailListJson
          .map((i) => DetailPesanan.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return Pesanan(
      id: json['pesanan_id'] as int? ?? 0,
      pemesan: json['pemesan'] as String? ?? 'N/A',
      warungNama: json['warung_nama'] as String?,
      totalHarga: (json['total_harga'] as num?)?.toDouble() ?? 0.0,
      tanggalPesanan: json['tanggal'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'N/A',
      // Perbaikan: ambil dari kunci "alamat_pengiriman"
      alamatPengiriman: json['alamat_pengiriman'] as String?,
      detailPesanan: details,
    );
  }
}