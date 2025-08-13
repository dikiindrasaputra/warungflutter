// lib/screen/pesanan/warung_selection_screen.dart

import 'package:flutter/material.dart';
import '../../services/service.dart';
import '../../models/warung.dart';
import 'kategori.dart'; // Impor halaman kategori

class WarungSelectionScreen extends StatefulWidget {
  @override
  _WarungSelectionScreenState createState() => _WarungSelectionScreenState();
}

class _WarungSelectionScreenState extends State<WarungSelectionScreen> {
  final ApiService _apiService = ApiService();
  List<Warung> _warungList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWarungs();
  }

  Future<void> _fetchWarungs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _apiService.getProfile();
      if (user != null) {
        _warungList = await _apiService.fetchAllWarungsForUser();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar warung: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Warung untuk Pesanan'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _warungList.isEmpty
              ? Center(child: Text('Anda belum memiliki warung.'))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Menampilkan 2 kolom
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.8, // Mengatur rasio tinggi/lebar item
                    ),
                    itemCount: _warungList.length,
                    itemBuilder: (context, index) {
                      final warung = _warungList[index];
                      String initial = warung.nama.isNotEmpty ? warung.nama[0].toUpperCase() : '';
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryScreen(warung: warung),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  warung.nama,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  warung.deskripsi,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
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
    );
  }
}