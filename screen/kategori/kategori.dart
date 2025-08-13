// lib/screen/category.dart

import 'package:flutter/material.dart';
import '../../services/service.dart';
import '../../models/pesanan.dart';
import '../../models/warung.dart';
import 'detail.dart';

// Page ini menerima objek Warung untuk mengambil pesanan yang terkait
class CategoryScreen extends StatefulWidget {
  final Warung warung;

  CategoryScreen({required this.warung});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ApiService _apiService = ApiService();
  Map<String, List<Pesanan>> _ordersByStatus = {};
  bool _isLoading = true;
  String _selectedStatus = 'Semua'; // Status awal yang dipilih adalah "Semua"

  final List<String> _orderedStatus = [
    'Semua',
    'Menunggu Pembayaran',
    'Menunggu Konfirmasi',
    'Diproses',
    'Dikirim',
    'Selesai',
    'Dibatalkan'
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _apiService.fetchWarungOrders(widget.warung.id);
      setState(() {
        _ordersByStatus = data;
        // Pastikan status yang dipilih ada di dalam data yang dimuat jika bukan "Semua"
        if (_selectedStatus != 'Semua' && !_ordersByStatus.containsKey(_selectedStatus) && _ordersByStatus.isNotEmpty) {
          _selectedStatus = _ordersByStatus.keys.first;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat pesanan: ${e.toString()}')),
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
        title: Text('Pesanan Warung: ${widget.warung.nama}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: _ordersByStatus.isEmpty
                  ? Center(
                      child: Text('Tidak ada pesanan untuk warung ini.'),
                    )
                  : Column(
                      children: [
                        // Horizontal scroll untuk pilihan status
                        _buildStatusFilter(),
                        // Tampilan berdasarkan status yang dipilih
                        Expanded(
                          child: _selectedStatus == 'Semua'
                              ? ListView(
                                  children: _buildAllStatusSections(),
                                )
                              : _buildFilteredOrders(),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 60,
      color: Colors.grey[100],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _orderedStatus.length,
        itemBuilder: (context, index) {
          final status = _orderedStatus[index];
          final isSelected = status == _selectedStatus;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStatus = status;
                  });
                }
              },
              selectedColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.grey[300],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  // Tampilan untuk _selectedStatus != 'Semua'
  Widget _buildFilteredOrders() {
    final selectedOrders = _ordersByStatus[_selectedStatus] ?? [];
    return selectedOrders.isEmpty
        ? Center(child: Text('Tidak ada pesanan dengan status $_selectedStatus.'))
        : ListView.builder(
            itemCount: selectedOrders.length,
            itemBuilder: (context, index) {
              final order = selectedOrders[index];
              return _buildOrderCard(order);
            },
          );
  }

  // Tampilan untuk _selectedStatus == 'Semua' (menggabungkan logika dari kode sebelumnya)
  List<Widget> _buildAllStatusSections() {
    final List<Widget> sections = [];
    final statusList = _ordersByStatus.keys.toList();
    statusList.sort((a, b) => _orderedStatus.indexOf(a).compareTo(_orderedStatus.indexOf(b)));

    for (var status in statusList) {
      final orders = _ordersByStatus[status] ?? [];
      
      if (orders.isNotEmpty) {
        sections.add(_buildStatusHeader(status));
        sections.add(_buildHorizontalOrderList(orders));
      }
    }
    return sections;
  }
  
  Widget _buildStatusHeader(String status) {
    return Container(
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildHorizontalOrderList(List<Pesanan> orders) {
    return Container(
      height: 150, // Sesuaikan tinggi container
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }
  
  Widget _buildOrderCard(Pesanan order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PesananDetailScreen(
              pesanan: order,
              refreshList: _fetchOrders,
            ),
          ),
        );
      },
      child: Container(
        width: 200, // Lebar untuk setiap box pesanan
        child: Card(
          margin: EdgeInsets.all(8),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pesanan #${order.id}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(
                  'Pemesan: ${order.pemesan}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(
                  'Total: Rp. ${order.totalHarga.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Tanggal: ${order.tanggalPesanan.substring(0, 10)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}