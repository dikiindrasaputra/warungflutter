// lib/screen/wallet_screen.dart
import 'package:flutter/material.dart';
import '../../services/service.dart';
import '../../models/pesanan.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Pesanan>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _apiService.fetchUserTransactions();
  }

  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
      ),
      body: FutureBuilder<List<Pesanan>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final pesanan = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Text('Pesanan #${pesanan.id} - ${pesanan.status}'),
                    subtitle: Text('Total: Rp${pesanan.totalHarga.toStringAsFixed(2)}'),
                    children: pesanan.detailPesanan.map((detail) {
                      return ListTile(
                        leading: const Icon(Icons.shopping_bag),
                        title: Text(detail.produkNama),
                        subtitle: Text('${detail.jumlah} x Rp${detail.hargaSatuan.toStringAsFixed(2)}'),
                        trailing: Text('Rp${detail.subtotal.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Belum ada transaksi.'));
          }
        },
      ),
    );
  }
}