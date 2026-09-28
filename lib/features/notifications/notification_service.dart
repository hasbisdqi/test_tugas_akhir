import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handled on notification tap
        },
      );
      _isInitialized = true;
    } catch (e) {
      // Graceful degradation when running on non-supported platforms
      _isInitialized = true;
    }
  }

  Future<void> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      // Ignored safely
    }
  }

  /// Trigger instant Harvest / Irrigation Reminder Notification
  Future<void> showHarvestReminder({
    required String cropName,
    required String actionMessage,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'agro_harvest_channel',
      'Agro Harvest & Irrigation Reminders',
      channelDescription: 'Notifications for crop watering, harvesting schedules, and soil treatments',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    try {
      await _notificationsPlugin.show(
        101,
        '🌾 Agro Schedule: $cropName',
        actionMessage,
        notificationDetails,
      );
    } catch (e) {
      // Fallback
    }
  }

  /// Trigger Crypto / Commodity Price Alert Notification
  Future<void> showPriceAlert({
    required String commodityOrCrypto,
    required double currentPrice,
    required String currency,
    required String direction, // 'UP' or 'DOWN'
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'agro_market_channel',
      'Agro Market & Crypto Price Alerts',
      channelDescription: 'Real-time commodity surge/drop alerts and crypto trade triggers',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    final symbol = direction == 'UP' ? '📈 Surge Alert' : '📉 Drop Alert';
    final msg = '$commodityOrCrypto is now at $currency $currentPrice! Review market trends now.';

    try {
      await _notificationsPlugin.show(
        102,
        '$symbol: $commodityOrCrypto',
        msg,
        notificationDetails,
      );
    } catch (e) {
      // Fallback
    }
  }
}
