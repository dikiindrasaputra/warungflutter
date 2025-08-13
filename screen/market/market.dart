import 'package:flutter/material.dart';
import '../../services/service.dart';
import '../../models/pesanan.dart';

// === Tambahan untuk Printer (58mm Bluetooth) ===
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
// ===============================================

class MarketDashboardScreen extends StatefulWidget {
  final int warungId;
  const MarketDashboardScreen({super.key, required this.warungId});

  @override
  State<MarketDashboardScreen> createState() => _MarketDashboardScreenState();
}

class _MarketDashboardScreenState extends State<MarketDashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Pesanan>> _unfinishedOrdersFuture;

  // Skala status yang disederhanakan untuk slider
  final List<String> _updatableStatuses = [
    'Menunggu Pembayaran',
    'Menunggu Konfirmasi',
    'Selesai',
  ];

  final Map<String, IconData> _statusIcons = {
    'Menunggu Pembayaran': Icons.payment,
    'Menunggu Konfirmasi': Icons.hourglass_top,
    'Selesai': Icons.check_circle_outline,
  };

  int _currentPesananIndex = 0;
  final PageController _pageController = PageController();

  // === State Printer ===
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _bonded = [];
  BluetoothDevice? _connected;
  bool _printerReady = false;
  // =====================

  @override
  void initState() {
    super.initState();
    _unfinishedOrdersFuture = _fetchUnfinishedOrders();
    _initPrinterAuto(); // siapkan printer otomatis (sesuai pola yang sudah kamu mau)
  }

  // =========================
  // PRINTER (58mm Bluetooth)
  // =========================
  Future<void> _initPrinterAuto() async {
    try {
      _bonded = await _bluetooth.getBondedDevices();
      if (_bonded.isEmpty) {
        _showCenteredSnackbar('Tidak ada printer Bluetooth terpasang.', Colors.orange);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastAddr = prefs.getString('last_printer_addr');

      BluetoothDevice? target;
      if (lastAddr != null) {
        try {
          target = _bonded.firstWhere((d) => d.address == lastAddr);
        } catch (_) {}
      }
      target ??= _bonded.first;

      final already = await _bluetooth.isConnected ?? false;
      if (already) await _bluetooth.disconnect();

      await _bluetooth.connect(target);
      _connected = target;
      _printerReady = true;

      await prefs.setString('last_printer_addr', target.address.toString());

      _showCenteredSnackbar('Printer siap: ${target.name ?? target.address}', Colors.green);
    } catch (e) {
      _printerReady = false;
      _showCenteredSnackbar('Gagal konek printer: $e', Colors.red);
    }
  }

  String _formatRupiah(num n) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(n);
  }

  Future<void> _printPesanan58mm(Pesanan pesanan) async {
    if (!_printerReady || _connected == null) {
      await _initPrinterAuto();
      if (!_printerReady) return;
    }

    try {
      _bluetooth.printCustom("=== STRUK PESANAN ===", 2, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom("Pesanan #${pesanan.id}", 1, 0);
      _bluetooth.printCustom("Status: ${pesanan.status}", 1, 0);
      _bluetooth.printNewLine();

      for (var detail in pesanan.detailPesanan) {
        _bluetooth.printCustom(
          "${detail.produkNama} (${detail.jumlah} x ${_formatRupiah(detail.hargaSatuan)})",
          0,
          0,
        );
        _bluetooth.printCustom(
          "Subtotal: ${_formatRupiah(detail.subtotal)}",
          0,
          0,
        );
      }

      _bluetooth.printNewLine();
      _bluetooth.printCustom("Total: ${_formatRupiah(pesanan.totalHarga)}", 2, 0);
      _bluetooth.printNewLine();
      _bluetooth.printCustom("Terima kasih!", 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.paperCut();
    } catch (e) {
      _showCenteredSnackbar('Gagal cetak: $e', Colors.red);
    }
  }
  // =========================

  Future<List<Pesanan>> _fetchUnfinishedOrders() async {
    try {
      final allOrders = await _apiService.fetchWarungOrders(widget.warungId);
      final List<Pesanan> unfinishedOrders = [];

      allOrders.forEach((status, orders) {
        if (status != 'Selesai' && status != 'Dibatalkan') {
          unfinishedOrders.addAll(orders);
        }
      });

      unfinishedOrders.sort((a, b) => a.id.compareTo(b.id));
      return unfinishedOrders;
    } catch (e) {
      if (!mounted) return [];
      _showCenteredSnackbar('Gagal memuat pesanan: $e', Colors.red);
      return [];
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    if (newStatus == 'Menunggu Pembayaran') {
      _showCenteredSnackbar(
        'Status tidak dapat diubah menjadi "Menunggu Pembayaran"',
        Colors.orange,
      );
      return;
    }

    try {
      await _apiService.updateOrderStatus(orderId, newStatus);
      if (!mounted) return;

      _showCenteredSnackbar(
        'Status pesanan #$orderId diperbarui menjadi $newStatus',
        Colors.green,
      );

      // Segarkan daftar (tetap memakai cara fetch yang sama persis)
      setState(() {
        _unfinishedOrdersFuture = _fetchUnfinishedOrders();
      });

      // === Cetak otomatis bila status "Selesai" ===
      if (newStatus == 'Selesai') {
        // Ambil ulang semua order (cara yang sama), cari pesanan yg barusan di-update
        final allOrders = await _apiService.fetchWarungOrders(widget.warungId);
        final List<Pesanan> all = [];
        allOrders.forEach((_, orders) => all.addAll(orders));

        Pesanan? pesananForPrint;
        try {
          pesananForPrint = all.firstWhere((p) => p.id == orderId);
        } catch (e) {
          pesananForPrint = null;
        }

        if (pesananForPrint != null) {
          await _printPesanan58mm(pesananForPrint);
        } else {
          _showCenteredSnackbar('Data pesanan #$orderId tidak ditemukan untuk dicetak.', Colors.orange);
        }
      }
      // ============================================
    } catch (e) {
      if (!mounted) return;
      _showCenteredSnackbar('Gagal memperbarui status: $e', Colors.red);
    }
  }

  void _showCenteredSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height / 2,
          right: 20,
          left: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/main/bg_market.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: FutureBuilder<List<Pesanan>>(
              future: _unfinishedOrdersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final unfinishedOrders = snapshot.data!;
                  return Column(
                    children: [
                      // Custom Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Pesanan Berlangsung',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      // ScrollView horizontal untuk nomor pesanan
                      SizedBox(
                        height: 50,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: unfinishedOrders.asMap().entries.map((entry) {
                              final index = entry.key;
                              final pesanan = entry.value;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _currentPesananIndex = index;
                                  });
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: index == _currentPesananIndex
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'pesanan #${pesanan.id}',
                                    style: TextStyle(
                                      color: index == _currentPesananIndex ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: unfinishedOrders.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPesananIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final pesanan = unfinishedOrders.elementAt(index);

                            int currentStatusIndex = 0;
                            if (pesanan.status == 'Menunggu Pembayaran') {
                              currentStatusIndex = 0;
                            } else if (pesanan.status == 'Menunggu Konfirmasi' ||
                                pesanan.status == 'Diproses' ||
                                pesanan.status == 'Dikirim') {
                              currentStatusIndex = 1;
                            } else if (pesanan.status == 'Selesai') {
                              currentStatusIndex = 2;
                            }

                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Card(
                                elevation: 4,
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pesanan #${pesanan.id}',
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Status: ${pesanan.status}',
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Detail Pesanan:',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        ...pesanan.detailPesanan.map((detail) {
                                          return ListTile(
                                            title: Text(detail.produkNama),
                                            subtitle: Text('Jumlah: ${detail.jumlah} x Rp${detail.hargaSatuan}'),
                                            trailing: Text('Subtotal: Rp${detail.subtotal}'),
                                          );
                                        }).toList(),
                                        const Divider(),
                                        Text(
                                          'Total Harga: Rp${pesanan.totalHarga}',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Ubah Status:',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        // Slider interaktif dengan tampilan yang lebih menarik
                                        SizedBox(
                                          height: 100,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final sliderWidth = constraints.maxWidth;
                                              const thumbWidth = 30.0;
                                              final thumbOffset = currentStatusIndex /
                                                  (_updatableStatuses.length - 1) *
                                                  (sliderWidth - thumbWidth);

                                              return Stack(
                                                alignment: Alignment.centerLeft,
                                                children: [
                                                  // Garis slider
                                                  Positioned.fill(
                                                    child: Center(
                                                      child: Container(
                                                        height: 4,
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[300],
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Ikon status
                                                  ..._updatableStatuses.asMap().entries.map((entry) {
                                                    final i = entry.key;
                                                    final status = entry.value;

                                                    double position;
                                                    if (i == 0) {
                                                      position = 0;
                                                    } else if (i == _updatableStatuses.length - 1) {
                                                      position = sliderWidth;
                                                    } else {
                                                      position = i / (_updatableStatuses.length - 1) * sliderWidth;
                                                    }

                                                    final isCurrent = i == currentStatusIndex;

                                                    return AnimatedPositioned(
                                                      duration: const Duration(milliseconds: 200),
                                                      top: 0,
                                                      bottom: 0,
                                                      left: position,
                                                      child: Transform.translate(
                                                        offset: Offset(
                                                          i == 0
                                                              ? 0
                                                              : (i == _updatableStatuses.length - 1 ? -60 : -40),
                                                          0,
                                                        ),
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            _updateOrderStatus(pesanan.id, status);
                                                          },
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(
                                                                _statusIcons[status],
                                                                color: isCurrent ? Colors.green : Colors.grey,
                                                                size: 24,
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                status,
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                                                ),
                                                                textAlign: TextAlign.center,
                                                                overflow: TextOverflow.visible,
                                                                softWrap: false,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                  // Thumb (penggeser)
                                                  AnimatedPositioned(
                                                    duration: const Duration(milliseconds: 200),
                                                    left: thumbOffset,
                                                    child: GestureDetector(
                                                      onHorizontalDragUpdate: (details) {
                                                        final localPosition = details.localPosition;
                                                        final newIndex = ((thumbOffset +
                                                                        localPosition.dx +
                                                                        thumbWidth / 2) /
                                                                    sliderWidth *
                                                                    (_updatableStatuses.length - 1))
                                                                .round()
                                                                .clamp(0, _updatableStatuses.length - 1);

                                                        if (newIndex != currentStatusIndex) {
                                                          _updateOrderStatus(pesanan.id, _updatableStatuses[newIndex]);
                                                        }
                                                      },
                                                      child: Container(
                                                        width: thumbWidth,
                                                        height: thumbWidth,
                                                        decoration: BoxDecoration(
                                                          color: Colors.green,
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withOpacity(0.2),
                                                              spreadRadius: 2,
                                                              blurRadius: 5,
                                                              offset: const Offset(0, 3),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(Icons.check, color: Colors.white, size: 24),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: Text('Tidak ada pesanan yang sedang berlangsung.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}