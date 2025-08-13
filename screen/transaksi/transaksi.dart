// lib/transaksi.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../services/service.dart';
import '../../models/warung.dart';
import '../../models/produk.dart';
import 'cart.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final ApiService _apiService = ApiService();
  Warung? _selectedWarung;
  List<Produk> _produkList = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWarungSelectionDialog();
    });
  }

  // Pop-up untuk memilih warung
  Future<void> _showWarungSelectionDialog() async {
    try {
      final warungs = await _apiService.fetchAllWarungsForUser();
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pilih Warung untuk Transaksi'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: warungs.length,
                itemBuilder: (context, index) {
                  final warung = warungs[index];
                  return ListTile(
                    title: Text(warung.nama),
                    onTap: () {
                      setState(() {
                        _selectedWarung = warung;
                      });
                      _fetchProduk(warung.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat warung: $e')),
      );
    }
  }

  // Mengambil produk dari warung yang dipilih
  Future<void> _fetchProduk(int warungId) async {
    try {
      final produk = await _apiService.fetchProdukByWarungId(warungId);
      setState(() {
        _produkList = produk;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat produk: $e')),
      );
    }
  }

  // Modal untuk menambahkan produk ke keranjang
  void _showOrderModal(Produk produk) {
    int jumlah = 1;
    double totalHarga = produk.harga;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(produk.nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Harga: Rp${produk.harga.toStringAsFixed(2)}'),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah'),
                    onChanged: (value) {
                      setState(() {
                        jumlah = int.tryParse(value) ?? 1;
                        totalHarga = produk.harga * jumlah;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('Total: Rp${totalHarga.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await _apiService.addToCart(produk.id, jumlah);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Produk berhasil ditambahkan ke keranjang!')),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menambahkan ke keranjang: $e')),
                        );
                      }
                    },
                    child: const Text('Tambahkan ke Pesanan'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Melakukan proses checkout
  Future<void> _handleCheckout() async {
    try {
      final String alamatPengiriman = "Alamat Pengiriman Contoh";
      // Mengirim status 'Menunggu Konfirmasi' secara eksplisit.
      final response = await _apiService.checkout(
        alamatPengiriman,
        initialStatus: 'Menunggu Konfirmasi',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response)),
      );
      // Kembali ke tampilan utama atau halaman konfirmasi
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter produk berdasarkan query pencarian
    final filteredProduk = _produkList.where((produk) {
      return produk.nama.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedWarung?.nama ?? 'Pilih Warung'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
            child: const Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: _selectedWarung == null
          ? const Center(child: Text('Silakan pilih warung untuk memulai transaksi.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cari Produk...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredProduk.length,
                    itemBuilder: (context, index) {
                      final produk = filteredProduk[index];
                      return InkWell(
                        // Tindakan saat tap singkat: Tambah 1 ke keranjang
                        onTap: () async {
                          try {
                            await _apiService.addToCart(produk.id, 1);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${produk.nama} berhasil ditambahkan ke keranjang!')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menambahkan ke keranjang: $e')),
                            );
                          }
                        },
                        // Tindakan saat long-press: Tampilkan modal untuk memilih jumlah
                        onLongPress: () => _showOrderModal(produk),
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Anda bisa menambahkan gambar produk di sini
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(produk.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('Harga: Rp${produk.harga.toStringAsFixed(2)}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Stok: ${produk.stok}'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _selectedWarung == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _handleCheckout,
                child: const Text('Checkout'),
              ),
            ),
    );
  }
}