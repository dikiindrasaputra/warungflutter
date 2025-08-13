import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/produk.dart';
import '../../services/service.dart';

class ProdukDetailScreen extends StatefulWidget {
  final Produk produk;
  final Function refreshList;

  ProdukDetailScreen({required this.produk, required this.refreshList});

  @override
  _ProdukDetailScreenState createState() => _ProdukDetailScreenState();
}

class _ProdukDetailScreenState extends State<ProdukDetailScreen> {
  final ApiService _apiService = ApiService();

  File? _selectedImage;

  void _showEditModal(BuildContext context) {
    final _namaController = TextEditingController(text: widget.produk.nama);
    final _deskripsiController = TextEditingController(text: widget.produk.deskripsi);
    final _hargaController = TextEditingController(text: widget.produk.harga.toString());
    final _stokController = TextEditingController(text: widget.produk.stok.toString());
    final ImagePicker _picker = ImagePicker();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Edit Produk'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: _namaController, decoration: InputDecoration(labelText: 'Nama Produk')),
                    TextFormField(controller: _deskripsiController, decoration: InputDecoration(labelText: 'Deskripsi')),
                    TextFormField(
                      controller: _hargaController,
                      decoration: InputDecoration(labelText: 'Harga'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _stokController,
                      decoration: InputDecoration(labelText: 'Stok'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setModalState(() {
                            _selectedImage = File(image.path);
                          });
                        }
                      },
                      child: Text('Pilih Gambar Baru'),
                    ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.file(
                          _selectedImage!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final updateData = {
                        'nama': _namaController.text,
                        'deskripsi': _deskripsiController.text,
                        'harga': double.parse(_hargaController.text),
                        'stok': int.parse(_stokController.text),
                      };

                      if (_selectedImage != null) {
                        // await _apiService.updateProduk(widget.produk.id, updateData, _selectedImage!);
                      } else {
                        await _apiService.updateProduk(widget.produk.id, updateData);
                      }

                      Navigator.of(context).pop();
                      widget.refreshList();
                      setState(() {
                        // Reset setelah update
                        _selectedImage = null;
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal mengedit produk: ${e.toString()}')),
                      );
                    }
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Produk'),
          content: Text('Apakah Anda yakin ingin menghapus produk ini?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.deleteProduk(widget.produk.id);
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Tutup halaman detail
                  widget.refreshList();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus produk: ${e.toString()}')),
                  );
                }
              },
              child: Text('Hapus'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: widget.produk.gambarUrl != null
                    ? Image.network(widget.produk.gambarUrl!, fit: BoxFit.cover)
                    : Text('Tidak ada gambar', style: TextStyle(color: Colors.grey)),
              ),
            ),
            SizedBox(height: 16),
            Text('Nama: ${widget.produk.nama}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Deskripsi: ${widget.produk.deskripsi}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Harga: Rp. ${widget.produk.harga.toStringAsFixed(0)}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Stok: ${widget.produk.stok}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showEditModal(context),
                  icon: Icon(Icons.edit),
                  label: Text('Edit'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: Icon(Icons.delete),
                  label: Text('Hapus'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
