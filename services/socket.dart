// lib/utils/socket.dart

import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RealtimeAlertHandler {
  static final RealtimeAlertHandler _instance = RealtimeAlertHandler._internal();
  late IO.Socket socket;
  final _newOrderStreamController = StreamController<Map<String, dynamic>>.broadcast();

  factory RealtimeAlertHandler() {
    return _instance;
  }

  RealtimeAlertHandler._internal();

  Stream<Map<String, dynamic>> get newOrderStream => _newOrderStreamController.stream;

  void connectToServer() {
    try {
      // PENTING: Jika menggunakan emulator Android, ganti '127.0.0.1' dengan '10.0.2.2'
      // Jika menggunakan device fisik, ganti dengan IP lokal komputer Anda (misal: '192.168.1.10')
      socket = IO.io('wss://flasksocket-production.up.railway.app', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket.connect();

      socket.onConnect((_) {
        print('Connected to Socket.IO server!');
      });

      socket.on('new_order_alert', (data) {
        print('New Order Alert received: $data');
        if (data != null) {
          _newOrderStreamController.sink.add(data as Map<String, dynamic>);
        }
      });

      // --- TAMBAHAN: Handle event setelah berhasil join room ---
      socket.on('joined_room', (data) {
        print('Successfully joined room: $data');
      });

      socket.onDisconnect((_) {
        print('Disconnected from Socket.IO server!');
      });

      socket.onConnectError((err) {
        print('Socket.IO Connect Error: $err');
      });

    } catch (e) {
      print('Error connecting to Socket.IO: $e');
    }
  }

  // --- TAMBAHAN: Method untuk join ke room warung ---
  void joinWarungRooms(List<int> warungIds) {
    if (socket.connected) {
      print('Joining rooms for warung IDs: $warungIds');
      for (var id in warungIds) {
        socket.emit('join', {'warung_id': id});
      }
    } else {
      print('Cannot join rooms, socket is not connected.');
      // Coba lagi setelah terhubung
      socket.onConnect((_) {
         print('Re-attempting to join rooms for warung IDs: $warungIds');
         for (var id in warungIds) {
          socket.emit('join', {'warung_id': id});
        }
      });
    }
  }

  void dispose() {
    socket.disconnect();
    _newOrderStreamController.close();
  }
}