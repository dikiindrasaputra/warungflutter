import 'package:flutter/material.dart';
import '/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/dashboard.dart';
import '/services/service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omah Watir',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: _checkTokenAndProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            // Jika snapshot.data adalah true, token dan profil valid
            if (snapshot.hasData && snapshot.data == true) {
              return DashboardScreen();
            } else {
              return LoginScreen();
            }
          }
        },
      ),
    );
  }

  Future<bool> _checkTokenAndProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return false;
    }

    try {
      // Coba ambil profil pengguna untuk memverifikasi token
      final user = await ApiService().getProfile();
      if (user != null) {
        return true; // Token valid dan profil berhasil dimuat
      }
    } catch (e) {
      // Tangani error jika token tidak valid, kadaluarsa, dll.
      print("Token verification failed: $e");
    }
    
    // Hapus token yang tidak valid
    await prefs.remove('token');
    return false;
  }
}