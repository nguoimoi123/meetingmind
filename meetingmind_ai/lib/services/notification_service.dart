import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  void Function(String?)? _onNotificationTap;

  // ID kênh thông báo
  static const String _channelId = 'meetingmind_channel';
  static const String _channelName = 'MeetingMind Reminders';
  static const String _channelDescription =
      'Thông báo nhắc nhở cho các cuộc họp và công việc';

  Future<void> initialize() async {
    // 1. Khởi tạo dữ liệu múi giờ (QUAN TRỌNG)
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // 2. Cấu hình Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. Cấu hình iOS
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. Khởi tạo plugin
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

    // 5. Xin quyền (Android 13+)
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Xin quyền thông báo cơ bản
    await androidPlugin?.requestNotificationsPermission();

    // Xin quyền Exact Alarms (Android 12+) để nhắc nhở chính xác ngay cả khi app tắt
    // Tránh crash nếu thiết bị không hỗ trợ (ví dụ: Android < 12)
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      print("Exact alarms permission not supported or error: $e");
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    // Giữ nguyên context để tương thích với code cũ
    required BuildContext context,
  }) async {
    await requestPermissions();

    // --- CẤU HÌNH CHI TIẾT THÔNG BÁO ANDROID ---

    // Mẫu rung: Rung nhẹ - nghỉ 0.2s - Rung mạnh - nghỉ 0.5s
    final vibrationPattern = Int64List.fromList([0, 200, 200, 500]);

    // Mẫu thông báo lớn (Big Text) - Hiển thị toàn bộ nội dung
    final bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: 'MeetingMind AI', // Phụ đề nhỏ dưới title
      htmlFormatSummaryText: true,
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',

      // Cấu hình style hiển thị
      styleInformation: bigTextStyleInformation,

      // Cấu hình âm thanh & rung
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,

      // Hiệu ứng LED (nếu máy có)
      ledColor: const Color.fromARGB(255, 0, 100, 255), // Màu xanh
      ledOnMs: 1000,
      ledOffMs: 500,

      // Hiển thị trên màn hình khóa
      fullScreenIntent: false,
      category: AndroidNotificationCategory.reminder,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // --- XỬ LÝ MÙI GIỜ ---
    // Lấy location đã set ở initialize (Asia/Ho_Chi_Minh)
    final location = tz.local;

    final scheduledTZDateTime = tz.TZDateTime(
      location,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      0, // Giây
    );

    // --- LÊN LỊCH ---
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDateTime,
        platformChannelSpecifics,

        // Đảm bảo thông báo bắn chính xác
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

        // Ngăn việc thay đổi múi giờ thiết bị làm sai lệch thông báo
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,

        // Cho phép lặp lại (nếu cần, hiện tại là 1 lần)
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }
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
