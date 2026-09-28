class UserModel {
  final int? id;
  final String username;
  final String email;
  final String passwordHash;
  final String fullName;
  final String? avatarUrl;
  final String role; // 'admin', 'farmer', 'investor'
  final String? walletAddress;
  final double cryptoBalance;
  final bool biometricEnabled;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.fullName,
    this.avatarUrl,
    this.role = 'farmer',
    this.walletAddress,
    this.cryptoBalance = 0.0,
    this.biometricEnabled = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'wallet_address': walletAddress,
      'crypto_balance': cryptoBalance,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String? ?? 'farmer',
      walletAddress: map['wallet_address'] as String?,
      cryptoBalance: (map['crypto_balance'] is num) ? (map['crypto_balance'] as num).toDouble() : 0.0,
      biometricEnabled: (map['biometric_enabled'] == 1 || map['biometric_enabled'] == true),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? passwordHash,
    String? fullName,
    String? avatarUrl,
    String? role,
    String? walletAddress,
    double? cryptoBalance,
    bool? biometricEnabled,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      walletAddress: walletAddress ?? this.walletAddress,
      cryptoBalance: cryptoBalance ?? this.cryptoBalance,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
