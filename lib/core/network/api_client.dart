import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://api.smartagro.io/v1';

  static Future<Map<String, dynamic>> syncSensorData({
    required List<Map<String, dynamic>> logs,
  }) async {
    try {
      // Prepared for online REST sync
      final body = jsonEncode({'logs': logs});
      if (body.isNotEmpty && baseUrl.startsWith('http')) {
        // Mock acknowledgment or ready for client.post
      }
      await Future.delayed(const Duration(milliseconds: 200));
      return {
        'status': 'success',
        'synced_count': logs.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> fetchAgroTokenMarketData({http.Client? client}) async {
    try {
      // Return live/mocked market rates
      return {
        'token': 'AGRO',
        'price_usd': 2.48,
        'change_24h': '+5.82%',
        'market_cap': '12.4M',
        'total_volume': '1.2M',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
