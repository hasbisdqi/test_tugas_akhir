import '../database/database_helper.dart';
import '../security/security_helper.dart';
import '../session/session_manager.dart';
import '../../models/user_model.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SessionManager _sessionManager = SessionManager.instance;

  /// Register a new user with encrypted password hash (SHA-256)
  Future<UserModel> register({
    required String username,
    required String email,
    required String plainPassword,
    required String fullName,
    String role = 'farmer',
    String? walletAddress,
  }) async {
    final db = await _dbHelper.database;

    // Check if user exists
    final existing = await db.query(
      'users',
      where: 'username = ? OR email = ?',
      whereArgs: [username.trim(), email.trim()],
    );

    if (existing.isNotEmpty) {
      throw Exception('Username or email already exists');
    }

    final passwordHash = SecurityHelper.hashPassword(plainPassword);
    final userMap = {
      'username': username.trim(),
      'email': email.trim(),
      'password_hash': passwordHash,
      'full_name': fullName.trim(),
      'role': role,
      'wallet_address': walletAddress ?? '0x${username.hashCode.toRadixString(16).padLeft(10, '0')}AGRO',
      'crypto_balance': 100.0, // Registration welcome bonus
      'biometric_enabled': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    final id = await db.insert('users', userMap);
    final newUser = UserModel.fromMap({...userMap, 'id': id});

    await _sessionManager.saveUserSession(newUser);
    return newUser;
  }

  /// Login with username/email and password
  Future<UserModel> login({
    required String identifier,
    required String plainPassword,
  }) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'users',
      where: 'username = ? OR email = ?',
      whereArgs: [identifier.trim(), identifier.trim()],
      limit: 1,
    );

    if (results.isEmpty) {
      throw Exception('Account not found');
    }

    final userMap = results.first;
    final storedHash = userMap['password_hash'] as String;

    if (!SecurityHelper.verifyPassword(plainPassword, storedHash)) {
      throw Exception('Invalid password');
    }

    final user = UserModel.fromMap(userMap);
    await _sessionManager.saveUserSession(user);
    return user;
  }

  /// Biometric Login
  Future<UserModel> loginWithBiometric({required String username}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );

    if (results.isEmpty) {
      throw Exception('Biometric user record not found');
    }

    final user = UserModel.fromMap(results.first);
    await _sessionManager.saveUserSession(user);
    return user;
  }

  /// Toggle Biometric for user
  Future<void> setBiometricEnabled(int userId, bool enabled, String username) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'biometric_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (enabled) {
      await _sessionManager.saveBiometricUser(username);
    }

    // Refresh current session
    final current = await _sessionManager.getCurrentUser();
    if (current != null && current.id == userId) {
      await _sessionManager.saveUserSession(current.copyWith(biometricEnabled: enabled));
    }
  }

  /// Logout
  Future<void> logout() async {
    await _sessionManager.clearSession();
  }
}
