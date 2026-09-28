import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../security/security_helper.dart';

class SessionManager {
  static final SessionManager instance = SessionManager._internal();
  factory SessionManager() => instance;
  SessionManager._internal();

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyEncryptedUserData = 'enc_user_data';
  static const String _keyAuthToken = 'auth_jwt_token';
  static const String _keyBiometricUsername = 'bio_username';
  static const String _keyThemeMode = 'theme_mode'; // 'light', 'dark', 'system'

  Future<void> saveUserSession(UserModel user, {String? token}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Encrypt JSON representation of user data for local tamper protection
    final userJson = jsonEncode(user.toMap());
    final encryptedData = SecurityHelper.encryptAES(userJson);

    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyUserId, user.id ?? 0);
    await prefs.setString(_keyEncryptedUserData, encryptedData);
    if (token != null) {
      await prefs.setString(_keyAuthToken, token);
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLogged) return null;

    final encryptedData = prefs.getString(_keyEncryptedUserData);
    if (encryptedData == null) return null;

    try {
      final decryptedJson = SecurityHelper.decryptAES(encryptedData);
      if (decryptedJson.isEmpty) return null;

      final map = jsonDecode(decryptedJson) as Map<String, dynamic>;
      return UserModel.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<void> saveBiometricUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBiometricUsername, username);
  }

  Future<String?> getBiometricUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBiometricUsername);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEncryptedUserData);
    await prefs.remove(_keyAuthToken);
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'system';
  }
}
