// lib/services/service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/warung.dart';
import '../models/produk.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/pesanan.dart';
import '../models/keranjang.dart'; // Import model Keranjang

const String _baseHost = 'flasksocket-production.up.railway.app';
const String baseUrl = 'https://$_baseHost/api';
const String uploadUrl = 'https://$_baseHost';

class ApiService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // --- Register ---
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // --- Login ---
  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return token;
    }
    return null;
  }
  
  // --- Logout ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // --- Get User Profile ---
   Future<User?> getProfile() async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user_data']);
      }
    } catch (e) {
      // Tangani kesalahan format atau parsing JSON
      print('Error parsing user profile: $e');
      return null;
    }
    return null;
  }

  // --- Fungsi untuk upload avatar user ---
  Future<String?> uploadAvatar(dynamic imageData, String filename) async {
    final url = Uri.parse('$uploadUrl/api/upload_avatar');
    final token = await _getToken();
    if (token == null) return null;

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });
    
    if (imageData is File) {
      request.files.add(await http.MultipartFile.fromPath(
        'avatar', 
        imageData.path,
        filename: filename,
      ));
    } else if (imageData is Uint8List) {
      request.files.add(http.MultipartFile.fromBytes(
        'avatar', 
        imageData,
        filename: filename,
      ));
    } else {
      return null;
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['avatar_url'];
      } else {
        print('Failed to upload image: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // --- Fungsi untuk update profil user ---
  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateData),
    );

    return response.statusCode == 200;
  }

  // --- Fungsi untuk update password user ---
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/update_password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    return response.statusCode == 200;
  }



  // Method baru untuk mengambil detail warung tertentu
  Future<Map<String, dynamic>> fetchWarungDetail(int warungId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Autentikasi gagal');

    final response = await http.get(
      Uri.parse('$baseUrl/warung/$warungId'), // Endpoint dengan ID warung
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat detail warung. Status Code: ${response.statusCode}');
    }
  }

  // Perbaikan: Metode ini sekarang memanggil endpoint '/api/mywarung'
  Future<List<Warung>> fetchAllWarungsForUser() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/mywarung'), // Endpoint yang baru
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is List) {
        return decodedBody.map((json) => Warung.fromJson(json)).toList();
      } else {
        return [];
      }
    } else {
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      throw Exception('Gagal memuat daftar warung. Status: ${response.statusCode}');
    }
  }

  // Metode untuk menambahkan warung (endpoint POST /api/warung tetap sama)
  Future<void> addWarung(String nama, String deskripsi, int userId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Autentikasi gagal');

    final response = await http.post(
      Uri.parse('$baseUrl/warung'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nama': nama,
        'deskripsi': deskripsi,
        // Backend akan mengambil pemilik_id dari token, jadi tidak perlu dikirim
      }),
    );
    
    if (response.statusCode != 201) {
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menambahkan warung');
    }
  }

  Future<bool> updateWarung(int warungId, Map<String, dynamic> updateData) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/warung/$warungId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal mengupdate warung');
    }
  }

  // Metode baru untuk menghapus warung
  Future<bool> deleteWarung(int warungId) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/warung/$warungId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menghapus warung');
    }
  }
  // --- Produk API Calls ---
  Future<List<Produk>> fetchProdukByWarungId(int warungId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/warung/$warungId/produk'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is List) {
        return decodedBody.map((json) => Produk.fromJson(json)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Gagal memuat produk. Status: ${response.statusCode}');
    }
  }

  // Metode baru untuk menambahkan produk
  Future<void> addProduk(int warungId, String nama, String deskripsi, double harga, int stok, File? selectedImage) async {
    final token = await _getToken();
    if (token == null) throw Exception('Autentikasi gagal');

    final response = await http.post(
      Uri.parse('$baseUrl/produk'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nama': nama,
        'deskripsi': deskripsi,
        'harga': harga,
        'stok': stok,
        'warung_id': warungId,
      }),
    );
    
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menambahkan produk');
    }
  }


Future<bool> updateProduk(int produkId, Map<String, dynamic> updateData) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/produk/$produkId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateData),
    );

    return response.statusCode == 200;
  }
 Future<List<Pesanan>> fetchUserTransactions() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/transaksi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is List) {
        return decodedBody.map((json) => Pesanan.fromJson(json)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Gagal memuat riwayat transaksi. Status: ${response.statusCode}');
    }
  }
  // Metode baru untuk menghapus produk
  Future<bool> deleteProduk(int produkId) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/produk/$produkId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

   Future<Map<String, List<Pesanan>>> fetchWarungOrders(int warungId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Autentikasi gagal');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/warung/$warungId/pesanan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
            print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      final responseData = jsonDecode(response.body);

       if (responseData is Map<String, dynamic>) {
        Map<String, List<Pesanan>> ordersByStatus = {};
        responseData.forEach((key, value) {
          if (value is List) {
            ordersByStatus[key] =
                value.map((orderJson) => Pesanan.fromJson(orderJson as Map<String, dynamic>)).toList();
          } else {
            ordersByStatus[key] = [];
          }
        });
        return ordersByStatus;
      } else {
        throw Exception('Format respons tidak valid dari server.');
      }
    } else {
      throw Exception('Gagal memuat pesanan warung. Status: ${response.statusCode}');
    }
  }
    Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    final token = await _getToken();
    if (token == null) throw Exception('Autentikasi gagal');

    final response = await http.put(
      Uri.parse('$baseUrl/pesanan/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': newStatus}),
    );
    
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Gagal mengupdate status pesanan. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
   Future<Map<String, dynamic>> fetchWarungDashboard() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Autentikasi gagal');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/warungs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Gagal memuat data dashboard. Status: ${response.statusCode}');
    }
  }
   Future<Map<String, dynamic>> fetchWalletSummary() async {
    final token = await _getToken();
    if (token == null) throw Exception('Autentikasi gagal');

    final response = await http.get(
      Uri.parse('$baseUrl/wallet/summary'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Gagal memuat data wallet. Status: ${response.statusCode}');
    }
  }
  
  // --- Metode baru untuk keranjang dan checkout ---

  /// Menambahkan produk ke keranjang belanja.
  Future<bool> addToCart(int produkId, int jumlah) async {
    final token = await _getToken();
    if (token == null) throw Exception('Autentikasi gagal');

    final response = await http.post(
      Uri.parse('$baseUrl/keranjang/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'produk_id': produkId,
        'jumlah': jumlah,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Gagal menambahkan produk ke keranjang.');
    }
  }

  /// Mengambil isi keranjang belanja pengguna.
  Future<List<KeranjangItem>> viewCart() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/keranjang'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data['keranjang'] is List) {
        return (data['keranjang'] as List).map((item) => KeranjangItem.fromJson(item)).toList();
      }
      return [];
    } else {
      throw Exception('Gagal memuat keranjang. Status: ${response.statusCode}');
    }
  }

  /// Melakukan checkout dari keranjang belanja.
 Future<String> checkout(String alamatPengiriman, {String initialStatus = 'Menunggu Pembayaran'}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Autentikasi gagal');

    // Tambahkan status ke dalam body request
    final response = await http.post(
      Uri.parse('$baseUrl/keranjang/checkout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'shipping_address': alamatPengiriman,
        'status': initialStatus, // Mengirim status awal
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['message'] as String;
    } else {
      throw Exception('Gagal melakukan checkout. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

}