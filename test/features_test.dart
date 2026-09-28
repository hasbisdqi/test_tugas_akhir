import 'package:flutter_test/flutter_test.dart';
import 'package:test_tugas_akhir/features/conversion/currency_service.dart';
import 'package:test_tugas_akhir/features/conversion/timezone_service.dart';
import 'package:test_tugas_akhir/features/sensors/sensor_suite_service.dart';
import 'package:test_tugas_akhir/features/lbs/lbs_location_service.dart';
import 'package:test_tugas_akhir/features/ai_assistant/ai_assistant_service.dart';
import 'package:test_tugas_akhir/features/game/mini_game_service.dart';
import 'package:test_tugas_akhir/features/notifications/notification_service.dart';
import 'package:test_tugas_akhir/features/blockchain/blockchain_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Modules Test Suite', () {
    test('1. Currency Converter Logic', () {
      final usdToIdr = ConversionService.convert(
        amount: 10,
        fromCurrency: 'USD',
        toCurrency: 'IDR',
      );
      expect(usdToIdr, 162500.0);

      final solToUsd = ConversionService.convert(
        amount: 1,
        fromCurrency: 'SOL',
        toCurrency: 'USD',
      );
      expect(solToUsd > 100, true);

      // Edge cases
      expect(ConversionService.convert(amount: -5, fromCurrency: 'USD', toCurrency: 'IDR'), 0.0);
      expect(ConversionService.parseAmount('12,50'), 12.50);
    });

    test('2. Timezone Converter Logic', () {
      final utcNow = DateTime.utc(2026, 9, 28, 12, 0, 0); // 12:00 UTC
      final wibTime = TimezoneService.getTimeInOffset(utcNow, 7);
      expect(wibTime.hour, 19);

      final gmtTime = TimezoneService.getTimeInOffset(utcNow, 0);
      expect(gmtTime.hour, 12);

      final witaTime = TimezoneService.getTimeInOffset(utcNow, 8);
      expect(witaTime.hour, 20);

      final formatted = TimezoneService.formatClockTime(wibTime);
      expect(formatted.startsWith('19:00'), true);
    });

    test('3. Sensor Suite Fallback Simulator', () async {
      final sensorService = SensorSuiteService();
      expect(sensorService.accelerometerStream, isNotNull);
      expect(sensorService.gyroscopeStream, isNotNull);
    });

    test('4. LBS Distance and Bearing Calculation', () {
      // Jakarta to Lembang (~110-130 km)
      final dist = LbsLocationService.calculateDistanceKm(
        startLat: -6.175392,
        startLng: 106.827153,
        endLat: -6.818451,
        endLng: 107.618934,
      );
      expect(dist > 90 && dist < 160, true);

      final nearby = LbsLocationService().getSortedNearbyHubs(
        currentLat: -6.175392,
        currentLng: 106.827153,
      );
      expect(nearby.isNotEmpty, true);
      expect(nearby.first.distanceKm <= nearby.last.distanceKm, true);
    });

    test('5. AI Assistant Service', () async {
      final ai = AiAssistantService();
      final response = await ai.respondToPrompt('How to manage rice irrigation?');
      expect(response.text.contains('AWD') || response.text.contains('Irrigation'), true);
      expect(response.suggestedActions, isNotEmpty);
    });

    test('6. Mini Game Service', () {
      final game = MiniGameService();
      game.startGame();
      expect(game.isPlaying, true);
      expect(game.timeLeft, 30);
      game.endGame();
      expect(game.isPlaying, false);
    });

    test('7. Notification Service Initializer', () async {
      final notificationService = NotificationService();
      await notificationService.init();
      expect(notificationService, isNotNull);
    });

    test('8. Blockchain Mining and Tamper Verification', () async {
      final ledger = BlockchainLedgerService();
      expect(ledger.chain.isNotEmpty, true);

      final newBlock = await ledger.addRecord(
        action: 'HARVEST_BATCH',
        itemName: 'Organic Arabica Mandheling',
        batchNumber: 'BATCH-2026-MND',
        producerOrOwner: 'Pak Joko Subroto',
        location: 'Takengon, Aceh',
        quantity: 500,
        unit: 'KG',
      );

      expect(newBlock.hash.startsWith('00'), true);
      expect(ledger.verifyChainIntegrity(), true);

      // Verify search
      final searchRes = ledger.searchByBatchOrItem('Mandheling');
      expect(searchRes.isNotEmpty, true);

      // Tamper test
      ledger.tamperBlock(1, 'Fake Injected Data');
      expect(ledger.verifyChainIntegrity(), false);
    });
  });
}
