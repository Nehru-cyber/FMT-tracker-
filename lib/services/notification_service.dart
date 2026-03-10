import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  // Notification IDs
  static const int emiNotificationBaseId = 1000;
  static const int incomeNotificationId = 2000;
  static const int investmentNotificationBaseId = 3000;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    
    // Initialize timezone
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not get timezone: $e');
    }
    
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    _isInitialized = true;
  }
  
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }
  
  // Request permissions (for Android 13+)
  static Future<bool> requestPermissions() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission();
          return granted ?? false;
        }
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
    return true;
  }
  
  // Schedule EMI payment reminder
  static Future<void> scheduleEMIReminder({
    required String emiId,
    required String emiName,
    required double amount,
    required int paymentDay,
    required int reminderDaysBefore,
  }) async {
    if (kIsWeb) return;
    try {
      final notificationId = emiNotificationBaseId + emiId.hashCode.abs() % 1000;
      
      // Calculate next payment date
      final now = DateTime.now();
      var nextPaymentDate = DateTime(now.year, now.month, paymentDay);
      if (nextPaymentDate.isBefore(now) || nextPaymentDate.isAtSameMomentAs(now)) {
        nextPaymentDate = DateTime(now.year, now.month + 1, paymentDay);
      }
      
      // Calculate reminder date
      var reminderDate = nextPaymentDate.subtract(Duration(days: reminderDaysBefore));
      if (reminderDate.isBefore(now)) {
        nextPaymentDate = DateTime(now.year, now.month + 1, paymentDay);
        reminderDate = nextPaymentDate.subtract(Duration(days: reminderDaysBefore));
      }
      
      final scheduledDate = tz.TZDateTime.from(reminderDate, tz.local)
          .add(const Duration(hours: 9)); // 9 AM
      
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'emi_reminders',
          'EMI Reminders',
          channelDescription: 'Notifications for upcoming EMI payments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      await _notifications.zonedSchedule(
        notificationId,
        '💰 EMI Payment Due Soon',
        '$emiName - ₹${amount.toStringAsFixed(0)} due in $reminderDaysBefore days',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: 'emi:$emiId',
      );
    } catch (e) {
      debugPrint('Error scheduling EMI reminder: $e');
    }
  }
  
  // Cancel EMI reminder
  static Future<void> cancelEMIReminder(String emiId) async {
    if (kIsWeb) return;
    final notificationId = emiNotificationBaseId + emiId.hashCode.abs() % 1000;
    await _notifications.cancel(notificationId);
  }

  // Schedule Investment reminder
  static Future<void> scheduleInvestmentReminder({
    required String id,
    required String name,
    required double amount,
    required int investDay,
  }) async {
    if (kIsWeb) return;
    try {
      final notificationId = investmentNotificationBaseId + id.hashCode.abs() % 1000;
      
      final now = DateTime.now();
      var nextInvestDate = DateTime(now.year, now.month, investDay);
      if (nextInvestDate.isBefore(now) || nextInvestDate.isAtSameMomentAs(now)) {
        nextInvestDate = DateTime(now.year, now.month + 1, investDay);
      }
      
      var reminderDate = nextInvestDate.subtract(const Duration(days: 1)); // 1 day before
      if (reminderDate.isBefore(now)) {
        reminderDate = nextInvestDate.subtract(const Duration(days: 1));
      }
      
      final scheduledDate = tz.TZDateTime.from(reminderDate, tz.local)
          .add(const Duration(hours: 10)); // 10 AM reminder
          
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'investment_reminders',
          'SIP & Investment Reminders',
          channelDescription: 'Notifications for upcoming SIP and Investment dates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      await _notifications.zonedSchedule(
        notificationId,
        '📈 SIP/Investment Reminder',
        '$name - ₹${amount.toStringAsFixed(0)} due on ${nextInvestDate.day}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: 'investment:$id',
      );
    } catch (e) {
      debugPrint('Error scheduling investment reminder: $e');
    }
  }

  // Cancel Investment reminder
  static Future<void> cancelInvestmentReminder(String id) async {
    if (kIsWeb) return;
    final notificationId = investmentNotificationBaseId + id.hashCode.abs() % 1000;
    await _notifications.cancel(notificationId);
  }
  
  // Schedule income day reminder
  static Future<void> scheduleIncomeReminder({
    required int incomeDay,
    required double amount,
  }) async {
    if (kIsWeb) return;
    try {
      final now = DateTime.now();
      var nextIncomeDate = DateTime(now.year, now.month, incomeDay);
      if (nextIncomeDate.isBefore(now)) {
        nextIncomeDate = DateTime(now.year, now.month + 1, incomeDay);
      }
      
      var reminderDate = nextIncomeDate.subtract(const Duration(days: 1));
      if (reminderDate.isBefore(now)) {
        reminderDate = nextIncomeDate;
      }
      
      final scheduledDate = tz.TZDateTime.from(reminderDate, tz.local)
          .add(const Duration(hours: 9)); // 9 AM
      
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'income_reminders',
          'Income Reminders',
          channelDescription: 'Notifications for upcoming income/salary',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      await _notifications.zonedSchedule(
        incomeNotificationId,
        '🎉 Income Day Tomorrow!',
        'Your salary of ₹${amount.toStringAsFixed(0)} is expected tomorrow',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: 'income',
      );
    } catch (e) {
      debugPrint('Error scheduling income reminder: $e');
    }
  }
  
  // Cancel income reminder
  static Future<void> cancelIncomeReminder() async {
    if (kIsWeb) return;
    await _notifications.cancel(incomeNotificationId);
  }
  
  // Show immediate notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'general',
        'General Notifications',
        channelDescription: 'General app notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  // Get pending notifications count
  static Future<int> getPendingNotificationsCount() async {
    if (kIsWeb) return 0;
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }
  
  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }
}
