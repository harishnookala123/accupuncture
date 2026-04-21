// services/notification_service.dart
import 'dart:io';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://acupuncturemapp.sssbi.com',
  ));

  // Initialize notifications
  Future<void> initialize() async {
    // Initialize Awesome Notifications WITHOUT any icon
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification', // ✅ MUST
      [
        NotificationChannel(
          channelKey: 'booking_channel',
          channelName: 'Booking Notifications',
          channelDescription: 'Notifications for booking updates',
          defaultColor: const Color(0xFF10B981),
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          // REMOVE the icon parameter completely
        ),
      ],
    );

    // Setup foreground message listener
    _setupForegroundListener();

    // Request permission and get token
    await requestPermissionAndSaveToken();
  }

  // Setup foreground listener
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground message received: ${message.notification?.title}');

      // Show notification when app is in foreground
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'booking_channel',
          title: message.notification?.title ?? 'New Notification',
          body: message.notification?.body ?? '',
          notificationLayout: NotificationLayout.Default,
          payload: message.data.map((key, value) => MapEntry(key, value.toString())),
          displayOnForeground: true,
          displayOnBackground: true,
          // REMOVE the icon parameter
        ),
      );
    });
  }

  // Request permission and save token
  Future<void> requestPermissionAndSaveToken() async {
    bool hasPermission = await AwesomeNotifications().isNotificationAllowed();

    if (!hasPermission) {
      bool result = await AwesomeNotifications().requestPermissionToSendNotifications();

      if (result) {
        print('✅ User granted notification permission');
        await saveTokenToServer();
      } else {
        print('❌ User denied notification permission');
      }
    } else {
      print('✅ Notifications already permitted');
      await saveTokenToServer();
    }
  }

  // Save FCM token to server
  Future<void> saveTokenToServer() async {
    try {
      String? token = await _firebaseMessaging.getToken();

      if (token == null) {
        print('❌ Failed to get FCM token');
        return;
      }

      print('📱 FCM Token: $token');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');

      if (userId == null || userId.isEmpty) {
        print('⚠️ User not logged in. Will save token after login.');
        return;
      }

      final response = await _dio.post('/save-fcm-token', data: {
        'user_id': userId,
        'fcm_token': token,
        'device_info': {
          'platform': Platform.operatingSystem,
          'app_version': '1.0.0',
        },
      });

      if (response.data['success'] == true) {
        print('✅ FCM token saved to server');
      } else {
        print('❌ Failed to save token');
      }
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  // Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'booking_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: payload ?? {},
        displayOnForeground: true,
        displayOnBackground: true,
        // REMOVE the icon parameter
      ),
    );
  }

  // Show booking confirmation
  static Future<void> showBookingConfirmation({
    required int sessionNumber,
    required String date,
    required String time,
    required String serviceName,
  }) async {
    await showLocalNotification(
      title: 'Booking Confirmed! ✅',
      body: 'Session $sessionNumber for $serviceName confirmed on $date at $time',
      payload: {
        'type': 'booking_confirmation',
        'session_number': sessionNumber.toString(),
      },
    );
  }

  // Show booking cancellation
  static Future<void> showBookingCancellation({
    required int sessionNumber,
    required String date,
    required String time,
  }) async {
    await showLocalNotification(
      title: 'Booking Cancelled ❌',
      body: 'Session $sessionNumber on $date at $time has been cancelled',
      payload: {
        'type': 'booking_cancellation',
        'session_number': sessionNumber.toString(),
      },
    );
  }

  // Show session completed
  static Future<void> showSessionCompleted({
    required int sessionNumber,
  }) async {
    await showLocalNotification(
      title: 'Session Completed 🎉',
      body: 'Session $sessionNumber has been marked as completed',
      payload: {
        'type': 'session_completed',
        'session_number': sessionNumber.toString(),
      },
    );
  }
  static Future<void> sendBookingConfirmationToUser({
    required String userId,
    required int sessionNumber,
    required String date,
    required String time,
    required String serviceName,
    String? adminName,
  }) async {
    try {
      final Dio dio = Dio(BaseOptions(
        baseUrl: 'http://192.168.29.190:3000',
      ));

      final response = await dio.post('/send-booking-confirmation-to-user', data: {
        'user_id': userId,
        'session_number': sessionNumber,
        'date': date,
        'time': time,
        'service_name': serviceName,
        'admin_name': adminName ?? 'Admin',
      });

      if (response.data['success'] == true) {
        print('✅ Booking confirmation sent to user');
      } else {
        print('❌ Failed to send notification: ${response.data['message']}');
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // Show appointment reminder
  static Future<void> showAppointmentReminder({
    required int sessionNumber,
    required String date,
    required String time,
  }) async {
    await showLocalNotification(
      title: 'Appointment Reminder ⏰',
      body: 'Reminder: Session $sessionNumber is scheduled for tomorrow at $time',
      payload: {
        'type': 'appointment_reminder',
        'session_number': sessionNumber.toString(),
      },
    );
  }
  static Future<void>rescheduleAppointment({
    required String date,
    required String time,})async{
    await showLocalNotification(
      title: "Appointment Reschedule",
      body: "Reminder $date and $time",
      payload: {
        'type' : "appointment_reminder",
        'time' : date
      }
    );
  }
}


// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background notification received');

  await AwesomeNotifications().initialize(
    'resource://drawable/ic_notification', // ✅ MUST
    [
      NotificationChannel(
        channelKey: 'booking_channel',
        channelName: 'Booking Notifications',
        importance: NotificationImportance.High,
        channelDescription: "Acupuncture_notification",
        // REMOVE the icon parameter
      ),
    ],
  );

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'booking_channel',
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      notificationLayout: NotificationLayout.Default,


      // REMOVE the icon parameter
    ),
  );
}