import 'dart:typed_data';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  void Function(String?)? _onNotificationTap;

  Future<void> initialize() async {
    // 1. Cấu hình Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. Cấu hình iOS (như mặc định)
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 3. Khởi tạo
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationTap?.call(response.payload);
      },
    );

    // 4. Xin quyền thông báo (Quan trọng cho Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required BuildContext context,
  }) async {
    // 1. Kiểm tra quyền Exact Alarm

    await requestPermissions();

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'events_channel_id',
      'Events Reminders',
      channelDescription: 'Nhắc nhở các sự kiện lịch trình',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      // Đảm bảo icon đúng ở drawable như đã nói trước đó
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      vibrationPattern: Int64List(4),
      playSound: true,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // --- GIẢI PHÁP GIAO ĐIỆP MÙI GIỜ TỐI TỐT ---

    // Bước 1: Lấy Location Việt Nam thủ công (UTC+7)
    final location = tz.getLocation('Asia/Ho_Chi_Minh');

    // Bước 2: Tạo thời gian dựa trên Location này
    // Dù máy bạn ở bất kỳ đâu, ta ép nó hiểu theo giờ Việt Nam
    final scheduledTZDateTime = tz.TZDateTime(
      location,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // ---------------------------------------

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDateTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'realtime_channel_id',
      'Realtime Alerts',
      channelDescription: 'Realtime notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, platformDetails,
        payload: payload);
  }

  void setOnNotificationTap(void Function(String? payload) handler) {
    _onNotificationTap = handler;
  }
}
