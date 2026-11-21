import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/chat/chat_screen.dart';

/// Top-level background message handler.
/// Must be a top-level function (not a class method) with @pragma('vm:entry-point')
/// for Firebase to invoke it when the app is terminated or in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized — required when the app is terminated
  // and the background isolate starts fresh.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Guard to prevent registering stream listeners multiple times.
  bool _listenersRegistered = false;

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
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
    // Avoid double notifications on Android: local notifications handle foreground display.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    // 5. Always save current FCM token for signed-in user
    await saveTokenToDatabase();

    // Guard stream listeners against multiple registrations
    if (_listenersRegistered) return;
    _listenersRegistered = true;

    // 6. Listen for auth changes to ensure FCM token is saved whenever user signs in
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await saveTokenToDatabase();
      }
    });

    // 7. Setup message listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      
      final notification = message.notification;
      final data = message.data;

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

    // 8. Check if app was opened from closed state via notification click
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from closed state notification click: ${initialMessage.messageId}');
      Future.delayed(const Duration(milliseconds: 800), () {
        _handleNavigation(initialMessage.data);
      });
    }

    // 9. Subscribe to token refreshes
    _messaging.onTokenRefresh.listen((token) async {
      print('FCM Token refreshed: $token');
      final currentUid = _getCurrentUid();
      if (currentUid != null) {
        await _ref.read(userRepositoryProvider).updateFcmToken(currentUid, token);
      } else {
        final currentUser = await _ref.read(currentUserProvider.future);
        if (currentUser != null) {
          await _ref.read(userRepositoryProvider).updateFcmToken(currentUser.uid, token);
        }
      }
    });
  }

  /// Helper to get current user's UID directly from FirebaseAuth without race condition.
  String? _getCurrentUid() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Fetches the current FCM token and writes it to Firestore.
  Future<void> saveTokenToDatabase() async {
    try {
      final token = await _messaging.getToken();
      print('FCM Token retrieved: $token');
      if (token != null) {
        final uid = _getCurrentUid();
        if (uid != null) {
          await _ref.read(userRepositoryProvider).updateFcmToken(uid, token);
          print('FCM Token successfully saved to Firestore for UID: $uid');
          return;
        }

        // Fallback to provider if auth instance hasn't updated
        final currentUser = await _ref.read(currentUserProvider.future);
        if (currentUser != null) {
          await _ref.read(userRepositoryProvider).updateFcmToken(currentUser.uid, token);
          print('FCM Token successfully saved to Firestore for UID: ${currentUser.uid}');
        }
      }
    } catch (e) {
      print('Error saving FCM token to database: $e');
    }
  }

  /// Removes FCM token from database (e.g. on logout).
  Future<void> deleteTokenFromDatabase() async {
    try {
      final uid = _getCurrentUid();
      if (uid != null) {
        await _ref.read(userRepositoryProvider).updateFcmToken(uid, null);
      } else {
        final currentUser = await _ref.read(currentUserProvider.future);
        if (currentUser != null) {
          await _ref.read(userRepositoryProvider).updateFcmToken(currentUser.uid, null);
        }
      }
      print('FCM Token cleared from database');
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

    final currentUid = _getCurrentUid();
    if (currentUid == null) return;

    try {
      // 1. Fetch other user model
      final otherUser = await _ref.read(userRepositoryProvider).getUserByUid(otherUserUid);
      if (otherUser == null) return;

      // 2. Fetch or create chat model
      final chat = await _ref.read(chatRepositoryProvider).getOrCreateChat(
            currentUid,
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
