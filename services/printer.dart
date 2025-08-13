import 'package:flutter/services.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';

class BluetoothPrinterService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  BluetoothDevice? _connectedDevice;

  List<BluetoothDevice> _devices = [];

  // Mengambil daftar perangkat Bluetooth yang sudah dipasangkan
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      _devices = await _bluetooth.getBondedDevices();
      return _devices;
    } on PlatformException {
      print('Failed to get bonded devices');
      return [];
    }
  }

  // Menghubungkan ke printer yang dipilih
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (await _bluetooth.isConnected ?? false) {
      await _bluetooth.disconnect();
    }
    try {
      await _bluetooth.connect(device);
      _connectedDevice = device;
      return true;
    } on PlatformException catch (e) {
      print('Failed to connect: ${e.message}');
      return false;
    }
  }

  // Memutus koneksi dari printer
  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _connectedDevice = null;
  }

  // Fungsi untuk mencetak struk (BlueThermalPrinter murni)
  Future<void> printReceipt({
    required String warungName,
    required String pemesanName,
    required List<Map<String, dynamic>> items,
    required double totalHarga,
  }) async {
    if (_connectedDevice == null) {
      print('Printer tidak terhubung.');
      return;
    }

    try {
      // Header Struk
      await _bluetooth.printCustom(warungName, 3, 1); // 3 = size besar, 1 = center
      await _bluetooth.printCustom("Jl. Contoh No. 123", 1, 1);
      await _bluetooth.printCustom("Telp: 0812-3456-7890", 1, 1);
      await _bluetooth.printNewLine();

      // Detail Pemesan
      await _bluetooth.printCustom("Nama Pemesan: $pemesanName", 1, 0);
      await _bluetooth.printCustom(
        "Tanggal: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}",
        1,
        0,
      );
      await _bluetooth.printNewLine();

      // Daftar Item
      for (var item in items) {
        String line =
            "${item['produkNama']}  ${item['jumlah']}x  Rp${item['hargaSatuan']}";
        await _bluetooth.printCustom(line, 1, 0);
      }
      await _bluetooth.printNewLine();

      // Total
      await _bluetooth.printCustom("TOTAL: Rp$totalHarga", 2, 2); // 2 = bold besar, 2 = right
      await _bluetooth.printNewLine();

      // Footer
      await _bluetooth.printCustom("Terima kasih telah berbelanja!", 1, 1);
      await _bluetooth.printNewLine();
      await _bluetooth.printNewLine();
    } catch (e) {
      print('Gagal mencetak struk: $e');
    }
  }
}
