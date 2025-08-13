// lib/screen/produk/produk_screen.dart
import 'package:flutter/material.dart';
import '../../models/warung.dart';
import '../../services/service.dart';
// Ganti import ini sesuai dengan nama file yang benar
import 'listproduk.dart';
import '../../models/user.dart';

class ProdukScreen extends StatefulWidget {
  @override
  _ProdukScreenState createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  final ApiService _apiService = ApiService();
  List<Warung> _warungList = [];
  bool _isLoading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndWarung();
  }

  Future<void> _fetchUserDataAndWarung() async {
    setState(() {
      _isLoading = true;
    });

    final startTime = DateTime.now(); // Catat waktu mulai

    try {
      _user = await _apiService.getProfile();
      if (_user != null) {
        _warungList = await _apiService.fetchAllWarungsForUser();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data pengguna atau daftar warung.')),
      );
    }

    // Hitung durasi yang telah berlalu
    final elapsed = DateTime.now().difference(startTime);

    // Jika kurang dari 1 detik, tunggu sisanya
    if (elapsed.inMilliseconds < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - elapsed.inMilliseconds));
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Helper function to get initials from a string
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length > 1) {
      return words.map((word) => word[0].toUpperCase()).join('');
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Warung untuk Produk'),
      ),
      body: _isLoading
          ? Center(child:
              Image.asset("assets/main/loading.gif",
              width: 200,)
          )
          : _warungList.isEmpty
              ? Center(child: Text('warung masih kosong'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Silakan pilih warung dulu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Jumlah kolom dalam grid
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1, // Atur rasio aspek item grid
                          ),
                          itemCount: _warungList.length,
                          itemBuilder: (context, index) {
                            final warung = _warungList[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProdukListScreen(warung: warung),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Theme.of(context).primaryColor,
                                      child: Text(
                                        _getInitials(warung.nama),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        warung.nama,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                ),
    );
  }
}