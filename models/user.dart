// lib/models/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final String? bio;
  final String? avatarUrl;
  final String? namaLengkap;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.namaLengkap,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Perbaikan: Tambahkan penanganan null pada 'id'
    final idValue = json['id'];
    if (idValue == null) {
      throw FormatException('ID pengguna tidak boleh null.');
    }
    
    return User(
      id: idValue,
      username: json['username'],
      email: json['email'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      namaLengkap: json['nama_lengkap'],
    );
  }
}