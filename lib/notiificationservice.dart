import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
 class NotificationServices{
   FirebaseMessaging messaging =FirebaseMessaging.instance;

   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =FlutterLocalNotificationsPlugin();

   void requestNotificationPermission()async{
     NotificationSettings settings = await messaging.requestPermission(
       alert: true,
       announcement: true,
       badge: true,
       carPlay: true,
       criticalAlert: true,
       provisional: true,
       sound: true,
     );
     if(settings.authorizationStatus==AuthorizationStatus.authorized){
       print('authorized');
     }else if(settings.authorizationStatus==AuthorizationStatus.provisional){
       print('provisoinal authorized');
     }else{
       print('unauthorized');
     }
   }

   void initLocalNotification(RemoteMessage message)async{
     var androidInitialization =const AndroidInitializationSettings('@mipmap/ic_launcher');
     var iosInitialization =const  DarwinInitializationSettings();
     var initializationSettings = InitializationSettings(android: androidInitialization,iOS: iosInitialization);
await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
  onDidReceiveNotificationResponse: (payload) {},
);

   }

   void firebaseInit(){
   FirebaseMessaging.onMessage.listen((message){
   initLocalNotification(message);

     showNotification(message );
// print(message.notification?.title.toString());
// print(message.notification?.body.toString());
// print(message.notification?.title.toString());
   });
   }

   Future<void> showNotification(RemoteMessage message)async {


     AndroidNotificationChannel channel = AndroidNotificationChannel(
         Random.secure().nextInt(2992).toString(),
         'High priority',
         importance: Importance.max
     );

     AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
   channel.id.toString(),
         channel.name.toString(),
      channelDescription: 'Your channel',
       importance: Importance.high,
       priority: Priority.high,
       ticker: 'ticker',
     );

     DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails (
       presentAlert: true,
       presentBadge: true,
       presentSound: true,
     );

     NotificationDetails  notificationDetails =NotificationDetails(android:androidNotificationDetails,iOS:darwinNotificationDetails  );

     Future.delayed(Duration.zero,() {
       _flutterLocalNotificationsPlugin.show(0, message.notification?.title.toString(), message.notification?.body.toString(), notificationDetails);
     });


   }

   void isrefreshtDeviceToken() async {
    messaging.onTokenRefresh.listen((event) {
      event.toString();
    });
   }

   Future<String> getDeviceToken() async {
     String? token = await messaging.getToken();
      return token!;
   }






 }



