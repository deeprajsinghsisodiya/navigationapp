// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:navigationapp/pages/home.dart';

import 'firebase_options.dart';
// import 'message.dart';
// import 'message_list.dart';
// import 'permissions.dart';
// import 'token_monitor.dart';

/// Working example of FirebaseMessaging.
/// Please use this in order to verify messages are working in foreground, background & terminated state.
/// Setup your app following this guide:
/// https://firebase.google.com/docs/cloud-messaging/flutter/client#platform-specific_setup_and_requirements):
///
/// Once you've completed platform specific requirements, follow these instructions:
/// 1. Install melos tool by running `flutter pub global activate melos`.
/// 2. Run `melos bootstrap` in FlutterFire project.
/// 3. In your terminal, root to ./packages/firebase_messaging/firebase_messaging/example directory.
/// 4. Run `flutterfire configure` in the example/ directory to setup your app with your Firebase project.
/// 5. Open `token_monitor.dart` and change `vapidKey` to yours.
/// 6. Run the app on an actual device for iOS, android is fine to run on an emulator.
/// 7. Use the following script to send a message to your device: scripts/send-message.js. To run this script,
///    you will need nodejs installed on your computer. Then the following:
///     a. Download a service account key (JSON file) from your Firebase console, rename it to "google-services.json" and add to the example/scripts directory.
///     b. Ensure your device/emulator is running, and run the FirebaseMessaging example app using `flutter run`.
///     c. Copy the token that is printed in the console and paste it here: https://github.com/firebase/flutterfire/blob/01b4d357e1/packages/firebase_messaging/firebase_messaging/example/lib/main.dart#L32
///     c. From your terminal, root to example/scripts directory & run `npm install`.
///     d. Run `npm run send-message` in the example/scripts directory and your app will receive messages in any state; foreground, background, terminated.
///  Note: Flutter API documentation for receiving messages: https://firebase.google.com/docs/cloud-messaging/flutter/receive
///  Note: If you find your messages have stopped arriving, it is extremely likely they are being throttled by the platform. iOS in particular
///  are aggressive with their throttling policy.
///
/// To verify that your messages are being received, you ought to see a notification appearon your device/emulator via the flutter_local_notifications plugin.
/// Define a top-level named handler which background/terminated messages will
/// call. Be sure to annotate the handler with `@pragma('vm:entry-point')` above the function declaration.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();
  showFlutterNotification(message);
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message ${message.messageId}');
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null && !kIsWeb) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          // TODO add a proper drawable resource to android, for now using
          //      one that already exists in example app.
          icon: 'launch_background',
        ),
      ),
    );
  }
  if (message != null) {

    // Navigator.push(context, MaterialPageRoute(builder: (context) => Home(),));

  }


}

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(name: 'navigationapp', options: DefaultFirebaseOptions.currentPlatform);
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    await setupFlutterNotifications();
  }

  runApp(MessagingExampleApp());
}

/// Entry point for the example application.
class MessagingExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messaging Example App',
      theme: ThemeData.dark(),
      routes: {
        '/': (context) => Application(),
        '/message': (context) => MessageView(),
      },
    );
  }
}



class NotificationDialog extends StatelessWidget {
  final String title;
  final String body;

  NotificationDialog({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: <Widget>[
        TextButton(
          onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => Home(),));
            // Perform the action you want when the user taps "See Notification"
            // For example, navigate to a specific screen.
            // Navigator.push(context, MaterialPageRoute(builder: (context) => YourScreen()));
          },
          child: Text('See Notification'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog when the "Close" button is tapped.
          },
          child: Text('Close'),
        ),
      ],
    );
  }
}


// Crude counter to make messages unique
int _messageCount = 0;

/// The API endpoint here accepts a raw FCM payload for demonstration purposes.
String constructFCMPayload(String? token) {
  _messageCount++;
  return jsonEncode({
    'token': token,
    'data': {
      'via': 'FlutterFire Cloud Messaging!!!',
      'count': _messageCount.toString(),
    },
    'notification': {
      'title': 'Hello FlutterFire!',
      'body': 'This notification (#$_messageCount) was created via FCM!',
    },
  });
}

/// Renders the example application.
class Application extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Application();
}

class _Application extends State<Application> {
  String? _token;
  String? initialMessage;
  bool _resolved = false;
  RemoteMessage? initialMessage1;

  @override

  void showFlutterNotification1(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            // TODO add a proper drawable resource to android, for now using
            //      one that already exists in example app.
            icon: 'launch_background',
          ),
        ),
      );
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return NotificationDialog(title: 'asvav', body: 'dsvasd');
          });
      // NotificationDialog(body: 'ss',title: 'wefw',);

    }



  }
  // It is assumed that all messages contain a data field with the key 'type'
  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    // await FirebaseMessaging.instance.g
    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    // FirebaseMessaging.onMessage

  }

  void _handleMessage(RemoteMessage message) {

    Navigator.push(context, MaterialPageRoute(builder: (context) => Home(),));
    // if (message.data['type'] == 'chat') {
    //   Navigator.pushNamed(context, '/chat',
    //     arguments: ChatArguments(message),
    //   );
    // }
  }

  void initState()  {
    super.initState();
    FirebaseMessaging.onMessage.listen(showFlutterNotification1 );


    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print('Got a message whilst in the foreground!');
    //   print('Message data: ${message.data}');
    //
    //   if (message.notification != null) {
    //     print('Message also contained a notification: ${message.notification}');
    //   }
    // });
    setupInteractedMessage();
    // getremotemessage();
    // FirebaseMessaging.instance.getInitialMessage().then(
    //       (value) => setState(
    //         () {
    //       _resolved = true;
    //       initialMessage = value?.data.toString();
    //
    //     },
    //   ),
    // );
    // // getremotemessage();
    // // RemoteMessage? initialMessage1 = await FirebaseMessaging.instance.getInitialMessage();
    // if (initialMessage1 != null) {
    // //   if (initialMessage1?.data['type'] == 'chat') {
    //     Navigator.push(context, MaterialPageRoute(builder: (context) => Home(),));
    //     // Navigator.pushNamed(
    //     //   context,
    //     //   '/',
    //     //   arguments: MessageArguments(initialMessage1!, true),
    //     // );
    //   }
    //   // else{
    //   //
    //   //   Navigator.pushNamed(
    //   //     context,
    //   //     '/',
    //   //     arguments: MessageArguments(initialMessage1!, true),
    //   //   );
    //   // }
    // // }
    // void _handleMessage(RemoteMessage message) {
    //   if (message.data['type'] == 'chat') {
    //     Navigator.pushNamed(
    //       context,
    //       '/message',
    //       arguments: MessageArguments(message, true),
    //     );
    //   }
    // }
    //
    // FirebaseMessaging.onMessage.listen(showFlutterNotification);
    //
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print('A new onMessageOpenedApp event was published!');
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => Home(),));
    //   // Navigator.pushNamed(
    //   //   context,
    //   //   '/message',
    //   //   arguments: MessageArguments(message, true),
    //   // );
    // });
  }

  void getremotemessage()   async {
  initialMessage1 = await FirebaseMessaging.instance.getInitialMessage();
}

  Future<void> sendPushMessage() async {
    if (_token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }

    try {
      await http.post(
        Uri.parse('https://api.rnfirebase.io/messaging/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: constructFCMPayload(_token),
      );
      print('FCM request for device sent!');
    } catch (e) {
      print(e);
    }
  }

  Future<void> onActionSelected(String value) async {
    switch (value) {
      case 'subscribe':
        {
          print(
            'FlutterFire Messaging Example: Subscribing to topic "fcm_test".',
          );
          await FirebaseMessaging.instance.subscribeToTopic('fcm_test');
          print(
            'FlutterFire Messaging Example: Subscribing to topic "fcm_test" successful.',
          );
        }
        break;
      case 'unsubscribe':
        {
          print(
            'FlutterFire Messaging Example: Unsubscribing from topic "fcm_test".',
          );
          await FirebaseMessaging.instance.unsubscribeFromTopic('fcm_test');
          print(
            'FlutterFire Messaging Example: Unsubscribing from topic "fcm_test" successful.',
          );
        }
        break;
      case 'get_apns_token':
        {
          if (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS) {
            print('FlutterFire Messaging Example: Getting APNs token...');
            String? token = await FirebaseMessaging.instance.getAPNSToken();
            print('FlutterFire Messaging Example: Got APNs token: $token');
          } else {
            print(
              'FlutterFire Messaging Example: Getting an APNs token is only supported on iOS and macOS platforms.',
            );
          }
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Messaging'),
        actions: <Widget>[
          PopupMenuButton(
            onSelected: onActionSelected,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'subscribe',
                  child: Text('Subscribe to topic'),
                ),
                const PopupMenuItem(
                  value: 'unsubscribe',
                  child: Text('Unsubscribe to topic'),
                ),
                const PopupMenuItem(
                  value: 'get_apns_token',
                  child: Text('Get APNs token (Apple only)'),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: sendPushMessage,
          backgroundColor: Colors.white,
          child: const Icon(Icons.send),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            MetaCard('Permissions', Permissions()),
            MetaCard(
              'Initial Message',
              Column(
                children: [
                  Text(_resolved ? 'Resolved' : 'Resolving'),
                  Text(initialMessage ?? 'None'),
                ],
              ),
            ),
            MetaCard(
              'FCM Token',
              TokenMonitor((token) {
                _token = token;
                return token == null
                    ? const CircularProgressIndicator()
                    : SelectableText(
                  token,
                  style: const TextStyle(fontSize: 12),
                );
              }),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseMessaging.instance
                    .getInitialMessage()
                    .then((RemoteMessage? message) {
                  if (message != null) {
                    Navigator.pushNamed(
                      context,
                      '/message',
                      arguments: MessageArguments(message, true),
                    );
                  }
                });
              },
              child: const Text('getInitialMessage()'),
            ),
            MetaCard('Message Stream', MessageList()),
          ],
        ),
      ),
    );
  }
}

/// UI Widget for displaying metadata.
class MetaCard extends StatelessWidget {
  final String _title;
  final Widget _children;

  // ignore: public_member_api_docs
  MetaCard(this._title, this._children);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Text(_title, style: const TextStyle(fontSize: 18)),
              ),
              _children,
            ],
          ),
        ),
      ),
    );
  }
}


/// Manages & returns the users FCM token.
///
/// Also monitors token refreshes and updates state.
class TokenMonitor extends StatefulWidget {
  // ignore: public_member_api_docs
  TokenMonitor(this._builder);

  final Widget Function(String? token) _builder;

  @override
  State<StatefulWidget> createState() => _TokenMonitor();
}

class _TokenMonitor extends State<TokenMonitor> {
  String? _token;
  late Stream<String> _tokenStream;

  void setToken(String? token) {
    print('FCM Token: $token');
    setState(() {
      _token = token;
    });
  }

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance
        .getToken(
        vapidKey:
        'BNKkaUWxyP_yC_lki1kYazgca0TNhuzt2drsOrL6WrgGbqnMnr8ZMLzg_rSPDm6HKphABS0KzjPfSqCXHXEd06Y')
        .then(setToken);
    _tokenStream = FirebaseMessaging.instance.onTokenRefresh;
    _tokenStream.listen(setToken);
  }

  @override
  Widget build(BuildContext context) {
    return widget._builder(_token);
  }
}


class MessageList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MessageList();
}

class _MessageList extends State<MessageList> {
  List<RemoteMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _messages = [..._messages, message];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) {
      return const Text('No messages received');
    }

    return ListView.builder(
        shrinkWrap: true,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          RemoteMessage message = _messages[index];

          return ListTile(
            title: Text(
                message.messageId ?? 'no RemoteMessage.messageId available'),
            subtitle:
            Text(message.sentTime?.toString() ?? DateTime.now().toString()),
            onTap: () => Navigator.pushNamed(context, '/message',
                arguments: MessageArguments(message, false)),
          );
        });
  }
}




/// Message route arguments.
class MessageArguments {
  /// The RemoteMessage
  final RemoteMessage message;

  /// Whether this message caused the application to open.
  final bool openedApplication;

  // ignore: public_member_api_docs
  MessageArguments(this.message, this.openedApplication);
}

/// Displays information about a [RemoteMessage].
class MessageView extends StatelessWidget {
  /// A single data row.
  Widget row(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: '),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MessageArguments args =
    ModalRoute.of(context)!.settings.arguments! as MessageArguments;
    RemoteMessage message = args.message;
    RemoteNotification? notification = message.notification;

    return Scaffold(
      appBar: AppBar(
        title: Text(message.messageId ?? 'N/A'),
      ),
      body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                row('Triggered application open',
                    args.openedApplication.toString()),
                row('Message ID', message.messageId),
                row('Sender ID', message.senderId),
                row('Category', message.category),
                row('Collapse Key', message.collapseKey),
                row('Content Available', message.contentAvailable.toString()),
                row('Data', message.data.toString()),
                row('From', message.from),
                row('Message ID', message.messageId),
                row('Sent Time', message.sentTime?.toString()),
                row('Thread ID', message.threadId),
                row('Time to Live (TTL)', message.ttl?.toString()),
                if (notification != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remote Notification',
                          style: TextStyle(fontSize: 18),
                        ),
                        row(
                          'Title',
                          notification.title,
                        ),
                        row(
                          'Body',
                          notification.body,
                        ),
                        if (notification.android != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Android Properties',
                            style: TextStyle(fontSize: 18),
                          ),
                          row(
                            'Channel ID',
                            notification.android!.channelId,
                          ),
                          row(
                            'Click Action',
                            notification.android!.clickAction,
                          ),
                          row(
                            'Color',
                            notification.android!.color,
                          ),
                          row(
                            'Count',
                            notification.android!.count?.toString(),
                          ),
                          row(
                            'Image URL',
                            notification.android!.imageUrl,
                          ),
                          row(
                            'Link',
                            notification.android!.link,
                          ),
                          row(
                            'Priority',
                            notification.android!.priority.toString(),
                          ),
                          row(
                            'Small Icon',
                            notification.android!.smallIcon,
                          ),
                          row(
                            'Sound',
                            notification.android!.sound,
                          ),
                          row(
                            'Ticker',
                            notification.android!.ticker,
                          ),
                          row(
                            'Visibility',
                            notification.android!.visibility.toString(),
                          ),
                        ],
                        if (notification.apple != null) ...[
                          const Text(
                            'Apple Properties',
                            style: TextStyle(fontSize: 18),
                          ),
                          row(
                            'Subtitle',
                            notification.apple!.subtitle,
                          ),
                          row(
                            'Badge',
                            notification.apple!.badge,
                          ),
                          row(
                            'Sound',
                            notification.apple!.sound?.name,
                          ),
                        ]
                      ],
                    ),
                  )
                ]
              ],
            ),
          )),
    );
  }
}




class Permissions extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Permissions();
}

class _Permissions extends State<Permissions> {
  bool _requested = false;
  bool _fetching = false;
  late NotificationSettings _settings;

  Future<void> requestPermissions() async {
    setState(() {
      _fetching = true;
    });

    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      announcement: true,
      carPlay: true,
      criticalAlert: true,
    );

    setState(() {
      _requested = true;
      _fetching = false;
      _settings = settings;
    });
  }

  Future<void> checkPermissions() async {
    setState(() {
      _fetching = true;
    });

    NotificationSettings settings =
    await FirebaseMessaging.instance.getNotificationSettings();

    setState(() {
      _requested = true;
      _fetching = false;
      _settings = settings;
    });
  }

  Widget row(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) {
      return const CircularProgressIndicator();
    }

    if (!_requested) {
      return ElevatedButton(
          onPressed: requestPermissions,
          child: const Text('Request Permissions'));
    }

    return Column(children: [
      row('Authorization Status', statusMap[_settings.authorizationStatus]!),
      if (defaultTargetPlatform == TargetPlatform.iOS) ...[
        row('Alert', settingsMap[_settings.alert]!),
        row('Announcement', settingsMap[_settings.announcement]!),
        row('Badge', settingsMap[_settings.badge]!),
        row('Car Play', settingsMap[_settings.carPlay]!),
        row('Lock Screen', settingsMap[_settings.lockScreen]!),
        row('Notification Center', settingsMap[_settings.notificationCenter]!),
        row('Show Previews', previewMap[_settings.showPreviews]!),
        row('Sound', settingsMap[_settings.sound]!),
      ],
      ElevatedButton(
          onPressed: checkPermissions, child: const Text('Reload Permissions')),
      ElevatedButton(
          onPressed: ()=> Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => Home(),)) ,child: const Text('Reload Permissions')),
    ]);


  }
}

/// Maps a [AuthorizationStatus] to a string value.
const statusMap = {
  AuthorizationStatus.authorized: 'Authorized',
  AuthorizationStatus.denied: 'Denied',
  AuthorizationStatus.notDetermined: 'Not Determined',
  AuthorizationStatus.provisional: 'Provisional',
};

/// Maps a [AppleNotificationSetting] to a string value.
const settingsMap = {
  AppleNotificationSetting.disabled: 'Disabled',
  AppleNotificationSetting.enabled: 'Enabled',
  AppleNotificationSetting.notSupported: 'Not Supported',
};

/// Maps a [AppleShowPreviewSetting] to a string value.
const previewMap = {
  AppleShowPreviewSetting.always: 'Always',
  AppleShowPreviewSetting.never: 'Never',
  AppleShowPreviewSetting.notSupported: 'Not Supported',
  AppleShowPreviewSetting.whenAuthenticated: 'Only When Authenticated',
};
// // ignore_for_file: require_trailing_commas
// // Copyright 2019 The Chromium Authors. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.
//
// import 'dart:async';
// import 'dart:convert';
//
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
//
//
//
// /// Define a top-level named handler which background/terminated messages will
// /// call.
// ///
// /// To verify things are working, check out the native platform logs.
//
//
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // If you're going to use other Firebase services in the background, such as Firestore,
//   // make sure you call `initializeApp` before using other Firebase services.
//   await Firebase.initializeApp();
//   print('Handling a background message ${message.messageId}');
// }
//
// /// Create a [AndroidNotificationChannel] for heads up notifications
// late AndroidNotificationChannel channel;
//
// /// Initialize the [FlutterLocalNotificationsPlugin] package.
// late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//
//   // Set the background messaging handler early on, as a named top-level function
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//   if (!kIsWeb) {
//     channel = const AndroidNotificationChannel(
//       'high_importance_channel', // id
//       'High Importance Notifications', // title
//       // 'This channel is used for important notifications.', // description
//       importance: Importance.high,
//
//     );
//
//     flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//     /// Create an Android Notification Channel.
//     ///
//     /// We use this channel in the `AndroidManifest.xml` file to override the
//     /// default FCM channel to enable heads up notifications.
//     await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//
//     /// Update the iOS foreground notification presentation options to allow
//     /// heads up notifications.
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//
//     );
//   }
//
//   runApp(MessagingExampleApp());
// }
//
// /// Entry point for the example application.
// class MessagingExampleApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Messaging Example App',
//       theme: ThemeData.dark(),
//       routes: {
//         '/': (context) => Application(),
//         '/message': (context) => MessageView(),
//       },
//     );
//   }
// }
//
// // Crude counter to make messages unique
// int _messageCount = 0;
//
// /// The API endpoint here accepts a raw FCM payload for demonstration purposes.
// String constructFCMPayload(String? token) {
//   _messageCount++;
//   return jsonEncode({
//     'token': token,
//     'data': {
//       'via': 'FlutterFire Cloud Messaging!!!',
//       'count': _messageCount.toString(),
//     },
//     'notification': {
//       'title': 'Hello FlutterFire!',
//       'body': 'This notification (#$_messageCount) was created via FCM!',
//     },
//   });
// }
//
// /// Renders the example application.
// class Application extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() => _Application();
// }
//
// class _Application extends State<Application> {
//   String? _token;
//
//   @override
//   void initState() {
//     super.initState();
//     FirebaseMessaging.instance
//         .getInitialMessage()
//         .then((RemoteMessage? message) {
//       if (message != null) {
//         Navigator.pushNamed(context, '/message',
//             arguments: MessageArguments(message, true));
//       }
//     });
//
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       RemoteNotification? notification = message.notification;
//       AndroidNotification? android = message.notification?.android;
//       if (notification != null && android != null && !kIsWeb) {
//         flutterLocalNotificationsPlugin.show(
//             notification.hashCode,
//             notification.title,
//             notification.body,
//             NotificationDetails(
//               android: AndroidNotificationDetails(
//                 channel.id,
//                 channel.name,
//                 // channel.description,
//                 // TODO add a proper drawable resource to android, for now using
//                 //      one that already exists in example app.
//                 icon: 'launch_background',
//               ),
//             ));
//       }
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('A new onMessageOpenedApp event was published!');
//       Navigator.pushNamed(context, '/message',
//           arguments: MessageArguments(message, true));
//     });
//   }
//
//   Future<void> sendPushMessage() async {
//     if (_token == null) {
//       print('Unable to send FCM message, no token exists.');
//       return;
//     }
//
//     try {
//       await http.post(
//         Uri.parse('https://api.rnfirebase.io/messaging/send'),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: constructFCMPayload(_token),
//       );
//       print('FCM request for device sent!');
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   Future<void> onActionSelected(String value) async {
//     switch (value) {
//       case 'subscribe':
//         {
//           print(
//               'FlutterFire Messaging Example: Subscribing to topic "fcm_test".');
//           await FirebaseMessaging.instance.subscribeToTopic('fcm_test');
//           print(
//               'FlutterFire Messaging Example: Subscribing to topic "fcm_test" successful.');
//         }
//         break;
//       case 'unsubscribe':
//         {
//           print(
//               'FlutterFire Messaging Example: Unsubscribing from topic "fcm_test".');
//           await FirebaseMessaging.instance.unsubscribeFromTopic('fcm_test');
//           print(
//               'FlutterFire Messaging Example: Unsubscribing from topic "fcm_test" successful.');
//         }
//         break;
//       case 'get_apns_token':
//         {
//           if (defaultTargetPlatform == TargetPlatform.iOS ||
//               defaultTargetPlatform == TargetPlatform.macOS) {
//             print('FlutterFire Messaging Example: Getting APNs token...');
//             String? token = await FirebaseMessaging.instance.getAPNSToken();
//             print('FlutterFire Messaging Example: Got APNs token: $token');
//           } else {
//             print(
//                 'FlutterFire Messaging Example: Getting an APNs token is only supported on iOS and macOS platforms.');
//           }
//         }
//         break;
//       default:
//         break;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Cloud Messaging'),
//         actions: <Widget>[
//           PopupMenuButton(
//             onSelected: onActionSelected,
//             itemBuilder: (BuildContext context) {
//               return [
//                 const PopupMenuItem(
//                   value: 'subscribe',
//                   child: Text('Subscribe to topic'),
//                 ),
//                 const PopupMenuItem(
//                   value: 'unsubscribe',
//                   child: Text('Unsubscribe to topic'),
//                 ),
//                 const PopupMenuItem(
//                   value: 'get_apns_token',
//                   child: Text('Get APNs token (Apple only)'),
//                 ),
//               ];
//             },
//           ),
//         ],
//       ),
//       floatingActionButton: Builder(
//         builder: (context) => FloatingActionButton(
//           onPressed: sendPushMessage,
//           backgroundColor: Colors.white,
//           child: const Icon(Icons.send),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(children: [
//           MetaCard('Permissions', Permissions()),
//           MetaCard('FCM Token', TokenMonitor((token) {
//             _token = token;
//             return token == null
//                 ? const CircularProgressIndicator()
//                 : Text(token, style: const TextStyle(fontSize: 12));
//           })),
//           MetaCard('Message Stream', MessageList()),
//         ]),
//       ),
//     );
//   }
// }
//
// /// UI Widget for displaying metadata.
// class MetaCard extends StatelessWidget {
//   final String _title;
//   final Widget _children;
//
//   // ignore: public_member_api_docs
//   MetaCard(this._title, this._children);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
//         child: Card(
//             child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(children: [
//                   Container(
//                       margin: const EdgeInsets.only(bottom: 16),
//                       child:
//                       Text(_title, style: const TextStyle(fontSize: 18))),
//                   _children,
//                 ]))));
//   }
// }
//
//
//
//
// /// Message route arguments.
// class MessageArguments {
//   /// The RemoteMessage
//   final RemoteMessage message;
//
//   /// Whether this message caused the application to open.
//   final bool openedApplication;
//
//   // ignore: public_member_api_docs
//   MessageArguments(this.message, this.openedApplication);
// }
//
// /// Displays information about a [RemoteMessage].
// class MessageView extends StatelessWidget {
//   /// A single data row.
//   Widget row(String title, String? value) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('$title: '),
//           Expanded(child: Text(value ?? 'N/A')),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final MessageArguments args =
//     ModalRoute.of(context)!.settings.arguments! as MessageArguments;
//     RemoteMessage message = args.message;
//     RemoteNotification? notification = message.notification;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(message.messageId ?? 'N/A'),
//       ),
//       body: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(8),
//             child: Column(
//               children: [
//                 row('Triggered application open',
//                     args.openedApplication.toString()),
//                 row('Message ID', message.messageId),
//                 row('Sender ID', message.senderId),
//                 row('Category', message.category),
//                 row('Collapse Key', message.collapseKey),
//                 row('Content Available', message.contentAvailable.toString()),
//                 row('Data', message.data.toString()),
//                 row('From', message.from),
//                 row('Message ID', message.messageId),
//                 row('Sent Time', message.sentTime?.toString()),
//                 row('Thread ID', message.threadId),
//                 row('Time to Live (TTL)', message.ttl?.toString()),
//                 if (notification != null) ...[
//                   Padding(
//                     padding: const EdgeInsets.only(top: 16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Remote Notification',
//                           style: TextStyle(fontSize: 18),
//                         ),
//                         row(
//                           'Title',
//                           notification.title,
//                         ),
//                         row(
//                           'Body',
//                           notification.body,
//                         ),
//                         if (notification.android != null) ...[
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Android Properties',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                           row(
//                             'Channel ID',
//                             notification.android!.channelId,
//                           ),
//                           row(
//                             'Click Action',
//                             notification.android!.clickAction,
//                           ),
//                           row(
//                             'Color',
//                             notification.android!.color,
//                           ),
//                           row(
//                             'Count',
//                             notification.android!.count?.toString(),
//                           ),
//                           row(
//                             'Image URL',
//                             notification.android!.imageUrl,
//                           ),
//                           row(
//                             'Link',
//                             notification.android!.link,
//                           ),
//                           row(
//                             'Priority',
//                             notification.android!.priority.toString(),
//                           ),
//                           row(
//                             'Small Icon',
//                             notification.android!.smallIcon,
//                           ),
//                           row(
//                             'Sound',
//                             notification.android!.sound,
//                           ),
//                           row(
//                             'Ticker',
//                             notification.android!.ticker,
//                           ),
//                           row(
//                             'Visibility',
//                             notification.android!.visibility.toString(),
//                           ),
//                         ],
//                         if (notification.apple != null) ...[
//                           const Text(
//                             'Apple Properties',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                           row(
//                             'Subtitle',
//                             notification.apple!.subtitle,
//                           ),
//                           row(
//                             'Badge',
//                             notification.apple!.badge,
//                           ),
//                           row(
//                             'Sound',
//                             notification.apple!.sound?.name,
//                           ),
//                         ]
//                       ],
//                     ),
//                   )
//                 ]
//               ],
//             ),
//           )),
//     );
//   }
// }
//
// // Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
// //
// // ignore_for_file: require_trailing_commas
//
//
//
// /// Listens for incoming foreground messages and displays them in a list.
// class MessageList extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() => _MessageList();
// }
//
// class _MessageList extends State<MessageList> {
//   List<RemoteMessage> _messages = [];
//
//   @override
//   void initState() {
//     super.initState();
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       setState(() {
//         _messages = [..._messages, message];
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_messages.isEmpty) {
//       return const Text('No messages received');
//     }
//
//     return ListView.builder(
//         shrinkWrap: true,
//         itemCount: _messages.length,
//         itemBuilder: (context, index) {
//           RemoteMessage message = _messages[index];
//
//           return ListTile(
//             title: Text(
//                 message.messageId ?? 'no RemoteMessage.messageId available'),
//             subtitle:
//             Text(message.sentTime?.toString() ?? DateTime.now().toString()),
//             onTap: () => Navigator.pushNamed(context, '/message',
//                 arguments: MessageArguments(message, false)),
//           );
//         });
//   }
// }
//
// // Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
//
// // ignore_for_file: require_trailing_commas
//
//
//
// /// Requests & displays the current user permissions for this device.
// class Permissions extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() => _Permissions();
// }
//
// class _Permissions extends State<Permissions> {
//   bool _requested = false;
//   bool _fetching = false;
//   late NotificationSettings _settings;
//
//   Future<void> requestPermissions() async {
//     setState(() {
//       _fetching = true;
//     });
//
//     NotificationSettings settings =
//     await FirebaseMessaging.instance.requestPermission(
//       announcement: true,
//       carPlay: true,
//       criticalAlert: true,
//       sound: true,
//     );
//
//     setState(() {
//       _requested = true;
//       _fetching = false;
//       _settings = settings;
//     });
//   }
//
//   Future<void> checkPermissions() async {
//     setState(() {
//       _fetching = true;
//     });
//
//     NotificationSettings settings =
//     await FirebaseMessaging.instance.getNotificationSettings();
//
//     setState(() {
//       _requested = true;
//       _fetching = false;
//       _settings = settings;
//     });
//   }
//
//   Widget row(String title, String value) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text('$title:', style: const TextStyle(fontWeight: FontWeight.bold)),
//           Text(value),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_fetching) {
//       return const CircularProgressIndicator();
//     }
//
//     if (!_requested) {
//       return ElevatedButton(
//           onPressed: requestPermissions,
//           child: const Text('Request Permissions'));
//     }
//
//     return Column(children: [
//       row('Authorization Status', statusMap[_settings.authorizationStatus]!),
//       if (defaultTargetPlatform == TargetPlatform.iOS) ...[
//         row('Alert', settingsMap[_settings.alert]!),
//         row('Announcement', settingsMap[_settings.announcement]!),
//         row('Badge', settingsMap[_settings.badge]!),
//         row('Car Play', settingsMap[_settings.carPlay]!),
//         row('Lock Screen', settingsMap[_settings.lockScreen]!),
//         row('Notification Center', settingsMap[_settings.notificationCenter]!),
//         row('Show Previews', previewMap[_settings.showPreviews]!),
//         row('Sound', settingsMap[_settings.sound]!),
//       ],
//       ElevatedButton(
//           onPressed: checkPermissions, child: const Text('Reload Permissions')),
//     ]);
//   }
// }
//
// /// Maps a [AuthorizationStatus] to a string value.
// const statusMap = {
//   AuthorizationStatus.authorized: 'Authorized',
//   AuthorizationStatus.denied: 'Denied',
//   AuthorizationStatus.notDetermined: 'Not Determined',
//   AuthorizationStatus.provisional: 'Provisional',
// };
//
// /// Maps a [AppleNotificationSetting] to a string value.
// const settingsMap = {
//   AppleNotificationSetting.disabled: 'Disabled',
//   AppleNotificationSetting.enabled: 'Enabled',
//   AppleNotificationSetting.notSupported: 'Not Supported',
// };
//
// /// Maps a [AppleShowPreviewSetting] to a string value.
// const previewMap = {
//   AppleShowPreviewSetting.always: 'Always',
//   AppleShowPreviewSetting.never: 'Never',
//   AppleShowPreviewSetting.notSupported: 'Not Supported',
//   AppleShowPreviewSetting.whenAuthenticated: 'Only When Authenticated',
// };
//
// // Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
//
// // ignore_for_file: require_trailing_commas
//
//
//
// /// Manages & returns the users FCM token.
// ///
// /// Also monitors token refreshes and updates state.
// class TokenMonitor extends StatefulWidget {
//   // ignore: public_member_api_docs
//   TokenMonitor(this._builder);
//
//   final Widget Function(String? token) _builder;
//
//   @override
//   State<StatefulWidget> createState() => _TokenMonitor();
// }
//
// class _TokenMonitor extends State<TokenMonitor> {
//   String? _token;
//   late Stream<String> _tokenStream;
//
//   void setToken(String? token) {
//     print('FCM Token: $token');
//     setState(() {
//       _token = token;
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     FirebaseMessaging.instance
//         .getToken(
//         vapidKey:
//         'BNKkaUWxyP_yC_lki1kYazgca0TNhuzt2drsOrL6WrgGbqnMnr8ZMLzg_rSPDm6HKphABS0KzjPfSqCXHXEd06Y')
//         .then(setToken);
//     _tokenStream = FirebaseMessaging.instance.onTokenRefresh;
//     _tokenStream.listen(setToken);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return widget._builder(_token);
//   }
// }
//
// //
// //
// // import 'dart:math';
// //
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import 'package:navigationapp/homescreen.dart';
// // import 'package:navigationapp/notiificationservice.dart';
// //
// //
// //
// // @pragma('vm:entry-point')
// // Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// //
// //   await Firebase.initializeApp( );
// //   // showNotification(message);
// //   AndroidNotificationChannel channel = AndroidNotificationChannel(
// //       Random.secure().nextInt(100000).toString(),
// //       'High priority',
// //       importance: Importance.max
// //
// //   );
// //   print(message.notification!.title.toString());
// //   AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
// //     channel.id.toString(),
// //     channel.name.toString(),
// //     channelDescription: 'Your channel',
// //     importance: Importance.high,
// //     priority: Priority.high,
// //     ticker: 'ticker',
// //   );
// //
// //   DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails (
// //     presentAlert: true,
// //     presentBadge: true,
// //     presentSound: true,
// //   );
// //
// //   NotificationDetails  notificationDetails =NotificationDetails(android:androidNotificationDetails,iOS:darwinNotificationDetails  );
// //
// //   // Future.delayed(Duration.zero,() {
// //   //   _flutterLocalNotificationsPlugin.show(0, message.notification?.title.toString(), message.notification?.body.toString(), notificationDetails);
// //   // });
// //
// //
// // }
// //
// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await Firebase.initializeApp();
// //   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler); // if we do activity inside by using (messages) we can null check issue so we need to make a funtion and di it outside main.
// //   runApp(const MyApp());
// // }
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   // This widget is the root of your application.
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Flutter Demo',
// //       theme: ThemeData(
// //         primarySwatch: Colors.blue,
// //       ),
// //       home: homescreen(),
// //     );
// //   }
// // }
// // Future<void> showNotification(RemoteMessage message)async {
// //
// //
// //   AndroidNotificationChannel channel = AndroidNotificationChannel(
// //       Random.secure().nextInt(100000).toString(),
// //       'High priority',
// //       importance: Importance.max
// //
// //   );
// //
// //   AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
// //     channel.id.toString(),
// //     channel.name.toString(),
// //     channelDescription: 'Your channel',
// //     importance: Importance.high,
// //     priority: Priority.high,
// //     ticker: 'ticker',
// //   );
// //
// //   DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails (
// //     presentAlert: true,
// //     presentBadge: true,
// //     presentSound: true,
// //   );
// //
// //   NotificationDetails  notificationDetails =NotificationDetails(android:androidNotificationDetails,iOS:darwinNotificationDetails  );
// //
// //   Future.delayed(Duration.zero,() {
// //     _flutterLocalNotificationsPlugin.show(0, message.notification?.title.toString(), message.notification?.body.toString(), notificationDetails);
// //   });
// //
// //
// // }
// //
// // final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =FlutterLocalNotificationsPlugin();