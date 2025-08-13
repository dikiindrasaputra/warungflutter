import 'package:flutter/material.dart';
import '../../models/pesanan.dart';
import '../../services/service.dart';

class PesananDetailScreen extends StatefulWidget {
  final Pesanan pesanan;
  final Function refreshList;

  PesananDetailScreen({required this.pesanan, required this.refreshList});

  @override
  _PesananDetailScreenState createState() => _PesananDetailScreenState();
}

class _PesananDetailScreenState extends State<PesananDetailScreen> {
  final ApiService _apiService = ApiService();
  late String _currentStatus;
  final List<String> _statusOptions = [
    'Menunggu Pembayaran',
    'Menunggu Konfirmasi',
    'Diproses',
    'Dikirim',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.pesanan.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      bool success = await _apiService.updateOrderStatus(widget.pesanan.id, newStatus);
      if (success) {
        setState(() {
          _currentStatus = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status berhasil diupdate menjadi $newStatus')),
        );
        widget.refreshList(); // Memanggil fungsi refresh dari halaman sebelumnya
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan #${widget.pesanan.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(
              title: 'Informasi Pemesan',
              content: [
                _buildInfoRow('Pemesan', widget.pesanan.pemesan),
                _buildInfoRow('Tanggal', widget.pesanan.tanggalPesanan.substring(0, 10)),
                _buildInfoRow('Alamat Pengiriman', widget.pesanan.alamatPengiriman ?? 'N/A'),
              ],
            ),
            SizedBox(height: 16),
            // Perbaikan: Pastikan list detailPesanan tidak kosong sebelum ditampilkan
            if (widget.pesanan.detailPesanan.isNotEmpty)
              _buildInfoCard(
                title: 'Produk yang Dipesan',
                content: [
                  for (var item in widget.pesanan.detailPesanan)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '• ${item.produkNama} (${item.jumlah}x) - Rp. ${item.hargaSatuan.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  SizedBox(height: 10),
                  Text(
                    'Total Harga: Rp. ${widget.pesanan.totalHarga.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              _buildInfoCard(
                title: 'Produk yang Dipesan',
                content: [Text('Tidak ada produk yang dipesan.')],
              ),
            SizedBox(height: 16),
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> content}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Pesanan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _currentStatus,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              items: _statusOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _updateStatus(newValue);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}