// lib/widgets/alert_dialog_widget.dart
import 'package:flutter/material.dart';
import '../models/pesanan.dart'; // Pastikan path ini benar
import '../services/service.dart'; // Pastikan path ini benar

class NewOrderAlertDialog extends StatelessWidget {
  final Pesanan pesanan;
  final Function refreshList;
  final Function onClose;
  final ApiService _apiService = ApiService();

  NewOrderAlertDialog({
    Key? key,
    required this.pesanan,
    required this.refreshList,
    required this.onClose,
  }) : super(key: key);

  Future<void> _markOrderAsCompleted(BuildContext context) async {
    try {
      bool success = await _apiService.updateOrderStatus(pesanan.id, 'Selesai');
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status pesanan berhasil diupdate menjadi Selesai')),
        );
        refreshList();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengupdate status pesanan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String pemesan = pesanan.pemesan;
    final double totalHarga = pesanan.totalHarga;
    final String? warungNama = pesanan.warungNama;
    final String? alamatPengiriman = pesanan.alamatPengiriman;

    // --- Perbaikan RangeError pada tanggal pesanan ---
    String displayTanggalPesanan;
    if (pesanan.tanggalPesanan.length >= 10) {
      displayTanggalPesanan = pesanan.tanggalPesanan.substring(0, 10);
    } else {
      displayTanggalPesanan = pesanan.tanggalPesanan;
    }

    return AlertDialog(
      title: Text('Pesanan Baru Masuk!'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildInfoBox(
              title: 'Informasi Pesanan',
              children: [
                _buildInfoRow('Warung', warungNama ?? 'N/A'),
                _buildInfoRow('Pemesan', pemesan),
                _buildInfoRow('Tanggal', displayTanggalPesanan),
                _buildInfoRow('Alamat Pengiriman', alamatPengiriman ?? 'N/A'),
                _buildInfoRow('Total Harga', 'Rp. ${totalHarga.toStringAsFixed(0)}'),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoBox(
              title: 'Produk Dipesan',
              children: [
                if (pesanan.detailPesanan.isNotEmpty)
                  ...pesanan.detailPesanan.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '• ${item.produkNama} (${item.jumlah}x) - Rp. ${item.hargaSatuan.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ).toList()
                else
                  Text('Tidak ada produk yang dipesan.'),
                SizedBox(height: 10),
                Text(
                  'Total Harga: Rp. ${totalHarga.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('OK'),
          onPressed: () {
            onClose();
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Selesai'),
          onPressed: () {
            _markOrderAsCompleted(context);
          },
        ),
      ],
    );
  }

  Widget _buildInfoBox({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
