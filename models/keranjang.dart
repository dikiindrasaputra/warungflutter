class KeranjangItem {
  final int produkId;
  final String namaProduk;
  final double hargaSatuan;
  final int jumlah;
  final double subtotal;

  KeranjangItem({
    required this.produkId,
    required this.namaProduk,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotal,
  });

  factory KeranjangItem.fromJson(Map<String, dynamic> json) {
    return KeranjangItem(
      produkId: json['produk_id'] as int,
      namaProduk: json['nama_produk'] as String,
      hargaSatuan: json['harga_satuan'] as double,
      jumlah: json['jumlah'] as int,
      subtotal: json['subtotal'] as double,
    );
  }
}