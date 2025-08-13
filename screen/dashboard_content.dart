// lib/widget/dashboard_content.dart

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:omahwajajanwatir/screen/transaksi/transaksi.dart';
import '../models/user.dart';
import '../screen/produk/produk.dart';
import '../screen/warung/warung.dart';
import '../screen/kategori/daftarwarung.dart';
import '../screen/market/market.dart';
import '../screen/wallet/wallet.dart';

class DashboardContent extends StatelessWidget {
  final User user;

  const DashboardContent({Key? key, required this.user}) : super(key: key);

  final List<Map<String, dynamic>> menuItems = const [
    {'icon': Icons.shopping_bag, 'label': 'Produk', 'target_page': 'Produk'},
    {'icon': Icons.store, 'label': 'Warung', 'target_page': 'Warung'},
    {'icon': Icons.category, 'label': 'Category', 'target_page': 'DaftarWarung'},
    {'icon': Icons.local_mall, 'label': 'Market', 'target_page': 'Market'},
    {'icon': Icons.wallet, 'label': 'Wallet', 'target_page': 'Wallet'},
    {'icon': Icons.notifications, 'label': 'Transaksi', 'target_page': 'Transaksi'},
    {'icon': Icons.people, 'label': 'Customers', 'target_page': ''},
    {'icon': Icons.inventory, 'label': 'Inventory', 'target_page': ''},
  ];

  final List<String> imageAssets = const [
    "assets/main/produknasgor.jpg",
    "assets/main/produkmiegoreng.jpeg",
    "assets/main/produkmierebus.jpg",
    "assets/main/produkpadang.jpg"
  ];

  void _navigateToPage(BuildContext context, String page) {
    Widget targetPage;
    switch (page) {
      case 'Produk':
        targetPage = ProdukScreen();
        break;
      case 'Warung':
        targetPage = WarungScreen(userId: user.id);
        break;
      case 'DaftarWarung':
        targetPage = WarungSelectionScreen();
        break;
      case 'Market':
        targetPage =  MarketDashboardScreen(warungId: user.id,);
        break;
      case 'Wallet':
        targetPage =  WalletScreen();
        break;
      case 'Transaksi':
        targetPage =  TransaksiPage();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/main/bg_dashboard.jpg",
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: user.avatarUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user.avatarUrl!),
                      )
                    : const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  // Aksi untuk membuka halaman profil
                },
              ),
              const SizedBox(width: 10),
              Text(
                '${user.username}!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 100,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.3),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Saldo kamu',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.3),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Pendapatan hari ini',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 350,
          left: 0,
          right: 0,
          bottom: 0,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 150,
                    autoPlay: true,
                    enlargeCenterPage: true,
                  ),
                  items: imageAssets.map((assetPath) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              assetPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Menu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    padding: const EdgeInsets.all(16),
                    children: menuItems.map((item) {
                      return GestureDetector(
                        onTap: () => _navigateToPage(context, item['target_page']),
                        child: Card(
                          color: Colors.transparent,
                          elevation: 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item['icon'] as IconData, size: 30, color: Colors.white),
                              const SizedBox(height: 5),
                              Text(
                                item['label'] as String,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLandscapeLayout() {
    return const Center(child: Text("Layout landscape"));
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(context);
  }
}