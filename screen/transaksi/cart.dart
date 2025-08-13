// lib/cart.dart
import 'package:flutter/material.dart';
import '../../services/service.dart';
import '../../models/keranjang.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
      ),
      body: FutureBuilder<List<KeranjangItem>>(
        future: ApiService().viewCart(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final cartItems = snapshot.data!;
            return ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return ListTile(
                  title: Text(item.namaProduk),
                  subtitle: Text('Jumlah: ${item.jumlah} - Subtotal: Rp${item.subtotal.toStringAsFixed(2)}'),
                  onTap: () {
                    // Kembali ke halaman transaksi
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('Keranjang Anda kosong.'));
          }
        },
      ),
    );
  }
}