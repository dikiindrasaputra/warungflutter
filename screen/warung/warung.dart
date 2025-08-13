// lib/screen/warung/warung.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/warung.dart';
import '../../services/service.dart';
import 'detail.dart';

class WarungScreen extends StatefulWidget {
  final int userId;

  WarungScreen({required this.userId});

  @override
  _WarungScreenState createState() => _WarungScreenState();
}

class _WarungScreenState extends State<WarungScreen> {
  final PageController _pageController = PageController();
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();

  List<Warung> _warungList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWarung();
  }

  Future<void> _fetchWarung() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      _warungList = await _apiService.fetchAllWarungsForUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar warung: $e')),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addWarung() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _apiService.addWarung(_namaController.text, _deskripsiController.text, widget.userId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Warung berhasil ditambahkan!')),
        );
        
        _fetchWarung();

        _namaController.clear();
        _deskripsiController.clear();
        _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.ease);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan warung: ${e.toString()}')),
        );
      }
    }
  }

  String _getInitials(String nama) {
    if (nama.isEmpty) {
      return '';
    }
    List<String> words = nama.split(' ');
    String initials = '';
    for (var word in words) {
      if (word.isNotEmpty) {
        initials += word[0].toUpperCase();
      }
    }
    return initials;
  }

  Widget _buildWarungGridView() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_warungList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Anda belum memiliki warung.', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Silakan tambahkan warung baru.', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Daftar Warung Anda', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.8,
            ),
            itemCount: _warungList.length,
            itemBuilder: (context, index) {
              final warung = _warungList[index];
              return FutureBuilder<File?>(
                future: _getWarungImageFile(warung.id),
                builder: (context, snapshot) {
                  final imageFile = snapshot.data;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WarungDetailScreen(warung: warung, refreshList: _fetchWarung)),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias, // Tambahkan ini agar gambar terpotong sesuai border radius
                      child: Container(
                        decoration: imageFile != null
                            ? BoxDecoration(
                                image: DecorationImage(
                                  image: FileImage(imageFile),
                                  fit: BoxFit.cover, // Memastikan gambar ter-cover tanpa terpotong
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.4),
                                    BlendMode.darken,
                                  ),
                                ),
                              )
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (imageFile == null) // Tampilkan inisial hanya jika tidak ada gambar
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  _getInitials(warung.nama),
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            if (imageFile == null) SizedBox(height: 10), // Tambahkan spasi hanya jika tidak ada gambar
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                warung.nama,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: imageFile != null ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                warung.deskripsi,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: imageFile != null ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Fungsi untuk mendapatkan file gambar lokal
  Future<File?> _getWarungImageFile(int warungId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = path.join(directory.path, '$warungId.jpg');
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      print('Gagal memuat gambar: $e');
    }
    return null;
  }

  Widget _buildAddWarungView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Tambah Warung Baru', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(labelText: 'Nama Warung', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _deskripsiController,
                decoration: InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addWarung,
                child: Text('Simpan Warung'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Warung Anda'),
      ),
      body: PageView(
        controller: _pageController,
        children: [
          _buildWarungGridView(),
          _buildAddWarungView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _pageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.ease);
        },
      ),
    );
  }
}