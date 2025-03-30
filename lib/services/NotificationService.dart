import 'dart:async';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static StreamSubscription? _subscription;

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(initializationSettings);

    listenForNotifications();
  }

  static void listenForNotifications() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    _subscription?.cancel();

    _subscription = supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> notifications) {
          final unsentNotifications = notifications.where(
            (notification) =>
                notification['user_id'] == userId &&
                notification['is_sent'] == false,
          );

          for (final notification in unsentNotifications) {
            _showLocalNotification(
              notification['id'] as int,
              notification['message'] as String? ??
                  'Time to check your plants!',
            );

            supabase
                .from('notifications')
                .update({'is_sent': true})
                .eq('id', notification['id']);
          }
        });
  }

  static Future<void> _showLocalNotification(int id, String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'plant_care_channel',
          'Plant Care Notifications',
          channelDescription: 'Notifications about plant care',
          importance: Importance.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(id, 'Plant Care', message, details);
  }

  static void dispose() {
    _subscription?.cancel();
  }

  static Future<void> scheduleNotification({
    required int userId,
    required String message,
    DateTime? scheduledFor,
  }) async {
    final supabase = Supabase.instance.client;

    await supabase.from('notifications').insert({
      'user_id': userId,
      'message': message,
      'is_sent': false,
      'created_at': DateTime.now().toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
    });
  }
}
