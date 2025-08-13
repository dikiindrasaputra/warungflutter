// lib/screen/warung/warung_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../models/warung.dart';
import '../../services/service.dart';

class WarungDetailScreen extends StatefulWidget {
  final Warung warung;
  final Function refreshList;

  WarungDetailScreen({required this.warung, required this.refreshList});

  @override
  _WarungDetailScreenState createState() => _WarungDetailScreenState();
}

class _WarungDetailScreenState extends State<WarungDetailScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  // Fungsi untuk memuat gambar dari penyimpanan lokal
  Future<void> _loadImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(directory.path, '${widget.warung.id}.jpg');
    final file = File(imagePath);
    if (await file.exists()) {
      setState(() {
        _imageFile = file;
      });
    }
  }

  // Fungsi untuk memilih dan menyimpan gambar
  Future<void> _pickAndSaveImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = path.join(appDir.path, '${widget.warung.id}.jpg');
      
      final newImage = File(pickedFile.path);
      await newImage.copy(localPath);

      setState(() {
        _imageFile = File(localPath);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gambar berhasil disimpan!')),
      );
    }
  }

  void _showEditModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final _namaController = TextEditingController(text: widget.warung.nama);
        final _deskripsiController = TextEditingController(text: widget.warung.deskripsi);

        return AlertDialog(
          title: Text('Edit Warung'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _namaController, decoration: InputDecoration(labelText: 'Nama Warung')),
                TextFormField(controller: _deskripsiController, decoration: InputDecoration(labelText: 'Deskripsi')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final success = await _apiService.updateWarung(widget.warung.id, {
                  'nama': _namaController.text,
                  'deskripsi': _deskripsiController.text,
                });

                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Warung berhasil diperbarui!')));
                  widget.refreshList();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui warung.')));
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Warung'),
          content: Text('Apakah Anda yakin ingin menghapus warung ${widget.warung.nama}?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final success = await _apiService.deleteWarung(widget.warung.id);

                if (success) {
                  Navigator.of(context).pop(); // Tutup pop-up konfirmasi
                  Navigator.of(context).pop(); // Kembali ke halaman daftar warung
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Warung berhasil dihapus!')));
                  widget.refreshList();
                } else {
                  Navigator.of(context).pop(); // Tutup pop-up konfirmasi
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus warung.')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Warung'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section dengan gambar atau inisial
            GestureDetector(
              onTap: _pickAndSaveImage,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        )
                      : Stack( // Menggunakan Stack untuk menumpuk inisial dan ikon
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                              child: Text(
                                _getInitials(widget.warung.nama),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54, // Latar belakang semi-transparan untuk ikon
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            
            // Warung Information Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.warung.nama,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 10),
                  
                  Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.warung.deskripsi,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  
                  SizedBox(height: 30),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showEditModal(context),
                          icon: Icon(Icons.edit),
                          label: Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeleteConfirmation(context),
                          icon: Icon(Icons.delete),
                          label: Text('Hapus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}