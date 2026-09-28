import 'package:flutter_test/flutter_test.dart';
import 'package:test_tugas_akhir/core/security/security_helper.dart';
import 'package:test_tugas_akhir/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityHelper Tests', () {
    test('Password Hashing & Verification', () {
      const password = 'mySecretPassword123!';
      final hash = SecurityHelper.hashPassword(password);
      
      expect(hash, isNotEmpty);
      expect(SecurityHelper.verifyPassword(password, hash), isTrue);
      expect(SecurityHelper.verifyPassword('wrongPassword', hash), isFalse);
    });

    test('AES Encryption & Decryption', () {
      const plainText = '{"user_id": 1, "role": "admin"}';
      final encrypted = SecurityHelper.encryptAES(plainText);
      
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plainText)));

      final decrypted = SecurityHelper.decryptAES(encrypted);
      expect(decrypted, equals(plainText));
    });
  });

  group('UserModel Tests', () {
    test('User serialization and deserialization', () {
      final user = UserModel(
        id: 1,
        username: 'testfarmer',
        email: 'farmer@agro.io',
        passwordHash: 'hashed123',
        fullName: 'Test Farmer',
        role: 'farmer',
        cryptoBalance: 250.5,
        biometricEnabled: true,
      );

      final map = user.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.username, equals('testfarmer'));
      expect(restored.email, equals('farmer@agro.io'));
      expect(restored.cryptoBalance, equals(250.5));
      expect(restored.biometricEnabled, isTrue);
    });
  });
}
