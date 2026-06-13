import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );

    // Request permissions on Android 13+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Schedule a notification for a due payment on [dueDate]
  Future<void> scheduleDueReminder({
    required int id,
    required String personName,
    required double amount,
    required DateTime dueDate,
    required String phone,
  }) async {
    await initialize();

    final scheduledDate = tz.TZDateTime.from(dueDate, tz.local);

    // Skip if due date is in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'due_reminders',
      'Due Payment Reminders',
      channelDescription: 'Reminders for pending due payments',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '💰 Payment Due: $personName',
      'Amount due: Rs. ${amount.toStringAsFixed(2)} — Tap to send WhatsApp reminder',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'whatsapp:$phone:$personName:$amount',
    );
  }

  /// Cancel a specific notification by id
  Future<void> cancelReminder(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Show an immediate notification (for testing)
  Future<void> showTestNotification({
    required String personName,
    required double amount,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'due_reminders',
      'Due Payment Reminders',
      channelDescription: 'Reminders for pending due payments',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      '💰 Payment Due: $personName',
      'Amount due: Rs. ${amount.toStringAsFixed(2)}',
      const NotificationDetails(android: androidDetails),
    );
  }
}

/// Open WhatsApp with a pre-filled message
Future<void> openWhatsApp({
  required String phone,
  required String personName,
  required double amount,
  String? customMessage,
}) async {
  // Clean phone number — remove spaces, dashes, +, etc.
  final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

  final body = customMessage ??
      'Hello $personName,\n\n'
          'This is a friendly reminder that you have a pending payment of '
          'Rs. ${amount.toStringAsFixed(2)} due.\n\n'
          'Please clear the amount at your earliest convenience.\n\n'
          'Thank you!';

  final message = Uri.encodeComponent(body);

  // Try WhatsApp deep link first
  final whatsappUrl =
      Uri.parse('whatsapp://send?phone=$cleanPhone&text=$message');
  final whatsappWebUrl =
      Uri.parse('https://wa.me/$cleanPhone?text=$message');

  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl);
  } else if (await canLaunchUrl(whatsappWebUrl)) {
    await launchUrl(whatsappWebUrl, mode: LaunchMode.externalApplication);
  }
}
