// lib/screens/profile.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart'; // Tambahkan ini untuk XFile
import '../helpers/upload_helper.dart' as helper; // PERBAIKI: Impor file yang benar

import '../models/user.dart';
import '../services/service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  final _usernameController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarUrlManualController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  Uint8List? _selectedImageData;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = await _apiService.getProfile();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
        if (_user != null) {
          _usernameController.text = _user!.username;
          _namaLengkapController.text = _user!.namaLengkap ?? '';
          _bioController.text = _user!.bio ?? '';
          _avatarUrlManualController.text = _user!.avatarUrl ?? '';
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await helper.pickImage();
      if (pickedFile != null) {
        if (kIsWeb) {
          // If on web, the pickedFile is already a Uint8List
          setState(() {
            _selectedImageData = pickedFile as Uint8List;
            _selectedImageName = 'web_image.jpg'; // Dummy name for web
          });
        } else {
          // If on mobile, the pickedFile is an XFile
          final xFile = pickedFile as XFile;
          final pickedFileBytes = await xFile.readAsBytes();
          setState(() {
            _selectedImageData = pickedFileBytes;
            _selectedImageName = xFile.name;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _updateUserData() async {
    setState(() {
      _isLoading = true;
    });

    String? newAvatarUrl;
    if (_selectedImageData != null && _selectedImageName != null) {
      newAvatarUrl = await _apiService.uploadAvatar(_selectedImageData!, _selectedImageName!);
    } else if (_avatarUrlManualController.text.isNotEmpty) {
      newAvatarUrl = _avatarUrlManualController.text;
    }

    Map<String, dynamic> updateData = {
      'username': _usernameController.text,
      'nama_lengkap': _namaLengkapController.text,
      'bio': _bioController.text,
    };

    if (newAvatarUrl != null) {
      updateData['avatar_url'] = newAvatarUrl;
    }

    final success = await _apiService.updateProfile(updateData);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
      _fetchProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New password and confirmation do not match.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _apiService.updatePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully!')),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password. Please check your current password.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showEditProfileModal() {
    if (_user != null) {
      _usernameController.text = _user!.username;
      _namaLengkapController.text = _user!.namaLengkap ?? '';
      _bioController.text = _user!.bio ?? '';
      _avatarUrlManualController.text = _user!.avatarUrl ?? '';
      _selectedImageData = null;
      _selectedImageName = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter modalSetState) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(40, 255, 255, 255),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Edit Data Profil',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: (_selectedImageData != null)
                                ? MemoryImage(_selectedImageData!) as ImageProvider
                                : (_user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(_user!.avatarUrl!)
                                    : null,
                            child: _selectedImageData == null && (_user!.avatarUrl == null || _user!.avatarUrl!.isEmpty)
                                ? Icon(Icons.person, size: 50)
                                : null,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _pickImage();
                            modalSetState(() {});
                          },
                          icon: Icon(Icons.photo_library, color: Colors.deepPurpleAccent,),
                          label: Text('Pilih Gambar dari File', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _avatarUrlManualController,
                          decoration: InputDecoration(
                            labelText: 'Atau Masukkan URL Gambar',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _namaLengkapController,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _bioController,
                          decoration: InputDecoration(
                            labelText: 'Bio',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _updateUserData,
                          child: Text('Simpan Perubahan', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showResetPasswordModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Password Saat Ini',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _confirmNewPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updatePassword,
                    child: Text('Simpan Password Baru', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),),
                  ),
                  SizedBox(height: 200),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Center(child: Text('Please login to view your profile.')),
      );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/main/bg_profile.png",
                  fit: BoxFit.cover,
                ),
              ),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Center(
                            child: CircleAvatar(
                              radius: 70,
                              backgroundImage: (_user!.avatarUrl != null &&
                                      _user!.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(_user!.avatarUrl!)
                                      as ImageProvider
                                  : null,
                              child: _user!.avatarUrl == null ||
                                      _user!.avatarUrl!.isEmpty
                                  ? Icon(Icons.person, size: 70)
                                  : null,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Data Diri Kamu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildProfileDetail('Username', _user!.username),
                          _buildProfileDetail('Email', _user!.email),
                          _buildProfileDetail(
                              'Nama Lengkap', _user!.namaLengkap ?? 'Tambahkan nama lengkap kamu'),
                          _buildProfileDetail(
                              'Bio', _user!.bio ?? 'Deskripsikan diri kamu'),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showEditProfileModal,
                                  icon: Icon(Icons.edit),
                                  label: Text('Edit Data'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showResetPasswordModal,
                                  icon: Icon(Icons.lock_reset),
                                  label: Text(
                                    'Reset Password',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 212, 214, 189),
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}