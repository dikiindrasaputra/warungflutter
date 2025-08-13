// lib/screen/produk/produk_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/warung.dart';
import '../../models/produk.dart';
import '../../services/service.dart';
import 'detail.dart';

class ProdukListScreen extends StatefulWidget {
  final Warung warung;

  ProdukListScreen({required this.warung});

  @override
  _ProdukListScreenState createState() => _ProdukListScreenState();
}

class _ProdukListScreenState extends State<ProdukListScreen> {
  final ApiService _apiService = ApiService();
  List<Produk> _produkList = [];
  List<Produk> _filteredProdukList = [];
  bool _isLoading = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isGridView = true;

  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProduk();
    _searchController.addListener(_filterProduk);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProduk);
    _searchController.dispose();
    _namaController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  Future<void> _fetchProduk() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      _produkList = await _apiService.fetchProdukByWarungId(widget.warung.id);
      _filteredProdukList = _produkList;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar produk: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addProduk() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _apiService.addProduk(
          widget.warung.id,
          _namaController.text,
          _deskripsiController.text,
          double.parse(_hargaController.text),
          int.parse(_stokController.text),
          _selectedImage,
        );
        _fetchProduk();
        // Clear text controllers and selected image after successful add
        _namaController.clear();
        _deskripsiController.clear();
        _hargaController.clear();
        _stokController.clear();
        setState(() {
          _selectedImage = null;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk berhasil ditambahkan!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan produk: ${e.toString()}')),
        );
      }
    }
  }

  void _filterProduk() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProdukList = _produkList.where((produk) {
        return produk.nama.toLowerCase().contains(query) ||
               produk.deskripsi!.toLowerCase().contains(query);
      }).toList();
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length > 1) {
      return words.map((word) => word[0].toUpperCase()).join('');
    }
    return name[0].toUpperCase();
  }

  // --- MODIFIKASI: Mengubah showDialog menjadi showModalBottomSheet ---
  void _showAddProductModal() {
    // Reset form field before opening modal
    _namaController.clear();
    _deskripsiController.clear();
    _hargaController.clear();
    _stokController.clear();
    setState(() {
      _selectedImage = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // agar modal dapat diskroll
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tambah Produk Baru',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _namaController,
                    decoration: InputDecoration(labelText: 'Nama Produk'),
                    validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: InputDecoration(labelText: 'Deskripsi'),
                    validator: (value) => value!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                  ),
                  TextFormField(
                    controller: _hargaController,
                    decoration: InputDecoration(labelText: 'Harga'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Harga tidak boleh kosong' : null,
                  ),
                  TextFormField(
                    controller: _stokController,
                    decoration: InputDecoration(labelText: 'Stok'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Stok tidak boleh kosong' : null,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.image),
                    label: Text('Pilih Gambar dari Galeri'),
                  ),
                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.file(
                        _selectedImage!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addProduk,
                    child: Text('Simpan'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Batal'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produk Warung: ${widget.warung.nama}'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_isGridView)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Cari produk...',
                        suffixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _filteredProdukList.isEmpty
                      ? Center(
                          child: Text('Warung ini belum memiliki produk.', style: TextStyle(fontSize: 16)),
                        )
                      : _isGridView
                          ? GridView.builder(
                              padding: EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: _filteredProdukList.length,
                              itemBuilder: (context, index) {
                                final produk = _filteredProdukList[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProdukDetailScreen(produk: produk, refreshList: _fetchProduk),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: produk.gambarUrl != null
                                              ? Image.network(
                                                  produk.gambarUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      Center(child: Text('Error')),
                                                )
                                              : Icon(Icons.image, size: 50),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            _getInitials(produk.nama),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                          child: Text(
                                            produk.nama,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: _filteredProdukList.length,
                              itemBuilder: (context, index) {
                                final produk = _filteredProdukList[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: produk.gambarUrl != null
                                          ? Image.network(produk.gambarUrl!, fit: BoxFit.cover)
                                          : Text(produk.nama[0]),
                                    ),
                                    title: Text(produk.nama),
                                    subtitle: Text('Harga: Rp. ${produk.harga.toStringAsFixed(0)}'),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProdukDetailScreen(produk: produk, refreshList: _fetchProduk),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductModal,
        child: Icon(Icons.add),
      ),
    );
  }
}