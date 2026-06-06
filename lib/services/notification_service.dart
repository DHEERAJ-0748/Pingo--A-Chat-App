import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/chat/chat_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  /// Initializes messaging configurations and registers handlers.
  Future<void> initialize() async {
    // 1. Request FCM permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permission for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 2. Configure background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Configure local notifications for foreground display
    const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initIOS = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIOS,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNavigation(data);
          } catch (e) {
            print('Error parsing local notification payload: $e');
          }
        }
      },
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important chat notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Set FCM foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Setup message listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      
      final notification = message.notification;
      final data = message.data;

      // Don't show notification if the user is already viewing this chat screen
      // (We can check the currently active route or let local notifications handle it)
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: jsonEncode(data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background notification click: ${message.messageId}');
      _handleNavigation(message.data);
    });

    // 6. Check if app was opened from closed state via notification click
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from closed state notification click: ${initialMessage.messageId}');
      // Delayed slightly to allow navigatorKey to be ready and attached
      Future.delayed(const Duration(milliseconds: 800), () {
        _handleNavigation(initialMessage.data);
      });
    }

    // 7. Save initial token and subscribe to token refreshes
    await saveTokenToDatabase();
    _messaging.onTokenRefresh.listen((token) async {
      print('FCM Token refreshed: $token');
      final currentUser = await _ref.read(currentUserProvider.future);
      if (currentUser != null) {
        await _ref.read(userRepositoryProvider).updateFcmToken(currentUser.uid, token);
      }
    });
  }

  /// Fetches the current FCM token and writes it to Firestore.
  Future<void> saveTokenToDatabase() async {
    try {
      final token = await _messaging.getToken();
      print('FCM Token retrieved: $token');
      if (token != null) {
        final currentUser = await _ref.read(currentUserProvider.future);
        if (currentUser != null) {
          await _ref.read(userRepositoryProvider).updateFcmToken(currentUser.uid, token);
        }
      }
    } catch (e) {
      print('Error saving FCM token to database: $e');
    }
  }

  /// Removes FCM token from database (e.g. on logout).
  Future<void> deleteTokenFromDatabase() async {
    try {
      final currentUser = await _ref.read(currentUserProvider.future);
      if (currentUser != null) {
        await _ref.read(userRepositoryProvider).updateFcmToken(currentUser.uid, null);
      }
    } catch (e) {
      print('Error clearing FCM token from database: $e');
    }
  }

  /// Handles routing the app to the chat screen from notification data.
  Future<void> _handleNavigation(Map<String, dynamic> data) async {
    final chatId = data['chatId'] as String?;
    final otherUserUid = data['otherUserUid'] as String?;

    if (chatId == null || otherUserUid == null) {
      print('Notification data missing chatId or otherUserUid, navigation aborted.');
      return;
    }

    // We need to retrieve the current user
    final currentUser = await _ref.read(currentUserProvider.future);
    if (currentUser == null) return;

    try {
      // 1. Fetch other user model
      final otherUser = await _ref.read(userRepositoryProvider).getUserByUid(otherUserUid);
      if (otherUser == null) return;

      // 2. Fetch or create chat model
      final chat = await _ref.read(chatRepositoryProvider).getOrCreateChat(
            currentUser.uid,
            otherUser.uid,
          );

      // 3. Navigate to chat screen using global navigatorKey
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(chat: chat, otherUser: otherUser),
        ),
      );
    } catch (e) {
      print('Error navigating from notification click: $e');
    }
  }
}
