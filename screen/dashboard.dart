// lib/screen/dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async'; // Import untuk Timer

import '../models/user.dart';
import '../models/pesanan.dart';
import '../models/warung.dart';
import '../services/service.dart';
import '../services/socket.dart';
import '../widget/bottomnavbar.dart';
import '../widget/alert.dart';
import 'profile.dart';
import 'login.dart';
import 'dashboard_content.dart';

Pesanan _parsePesananJson(Map<String, dynamic> orderMap) {
  // This heavy parsing work will run on a separate isolate.
  return Pesanan.fromJson(orderMap);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;
  final _audioPlayer = AudioPlayer();
  late Future<User?> _userFuture;

  bool _isLoading = true; // State untuk mengontrol tampilan loading
  bool _isDataLoaded = false; // State untuk menandai apakah data sudah diambil

  @override
  void initState() {
    super.initState();
    RealtimeAlertHandler().connectToServer();
    _fetchAndShowLoading(); // Menggunakan metode baru
    
    RealtimeAlertHandler().newOrderStream.listen((orderMap) async { 
      if (mounted) {
        final Pesanan newOrder = await compute(_parsePesananJson, orderMap);

        _playAlarm();
        _showNewOrderAlert(newOrder);
      }
    });
  }

  @override
  void dispose() {
    RealtimeAlertHandler().dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Metode untuk menggabungkan loading timer dan fetching data
  void _fetchAndShowLoading() async {
    setState(() {
      _isLoading = true;
      _isDataLoaded = false;
    });

    // Mulai timer 2 detik
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // Ambil data
    _userFuture = _fetchInitialData().then((user) {
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
      }
      return user;
    });
  }

  Future<User?> _fetchInitialData() async {
    try {
      final user = await _apiService.getProfile();
      if (user != null) {
        final List<Warung> warungs = await _apiService.fetchAllWarungsForUser();
        final List<int> warungIds = warungs.map((w) => w.id).toList();
        if (warungIds.isNotEmpty) {
          RealtimeAlertHandler().joinWarungRooms(warungIds);
        }
        return user;
      } else {
        _logout();
        return null;
      }
    } catch (e) {
      print("Failed to fetch profile or warungs: $e");
      _logout();
      return null;
    }
  }

  void _playAlarm() async {
    await _audioPlayer.stop();
    await _audioPlayer.setAsset('assets/sounds/souundpesanan.mp3');
    await _audioPlayer.setLoopMode(LoopMode.one);
    _audioPlayer.play();
  }
  
  void _stopAlarm() {
    _audioPlayer.stop();
  }

  void _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  void _showNewOrderAlert(Pesanan newOrder) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NewOrderAlertDialog(
          pesanan: newOrder,
          onClose: _stopAlarm,
          refreshList: _stopAlarm,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          // Kondisi untuk menampilkan loading
          if (_isLoading || (!_isDataLoaded && snapshot.connectionState == ConnectionState.waiting)) {
            return Center(
              child: Image.asset(
                "assets/main/loading.gif",
                width: 200,
              ),
            );
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load data. Please try again.'),
                  ElevatedButton(
                    onPressed: () {
                      _fetchAndShowLoading(); // Memuat ulang dengan timer
                    },
                    child: const Text('Reload'),
                  ),
                ],
              ),
            );
          } else {
            return DashboardContent(user: snapshot.data!);
          }
        },
      ),
      ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          _widgetOptions.elementAt(_selectedIndex),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}