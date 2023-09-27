import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification service',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Notification service'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late centrifuge.Client _centrifuge;
  late centrifuge.Subscription _subscription;
  late ScrollController _controller;


  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


  Future onSelectNotification(NotificationResponse payload) async {
    if (payload != null) {
      debugPrint('Notification clicked with payload: $payload');
    }
  }

  Future<void> _showNotification(Notification noti) async {

    const androidNotificationDetails = AndroidNotificationDetails(
        'your other channel id',
        'your other channel name',
        channelDescription: 'your other channel description');

    DarwinNotificationDetails iosNotificationDetails = const DarwinNotificationDetails();

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    flutterLocalNotificationsPlugin.show(
      0,
      noti.title,
      noti.content,
      notificationDetails,
    );
  }


  @override
  void initState() {
    super.initState();

    _centrifuge = centrifuge.createClient('ws://192.168.0.224:8001/connection/websocket');

    var initializationSettingsAndroid =    const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = const DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );

    _subscribe();
    _connect();
  }

  @override
  void dispose() async {
    await _centrifuge.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
    );
  }

  void _connect() async {
    try {
      await _centrifuge.connect();
    } catch (exception) {
      _show(exception);
    }
  }

  void _subscribe() async {
    _subscription = _centrifuge.newSubscription('noti');

    // _subscription.subscribing.listen(_show);
    // _subscription.subscribed.listen(_show);
    // _subscription.unsubscribed.listen(_show);

    _subscription.join.listen((event) {
    });

    _subscription.leave.listen((event) {
    });

    _subscription.publication.listen((event) {
      final Map<String, dynamic> message = json.decode(utf8.decode(event.data));

      final noti = Notification(title: message['title'], content: message['content']);

      _showNotification(noti);
    });

    await _subscription.subscribe();
  }

  void _show(dynamic error) {
    showDialog<AlertDialog>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(
          error.toString(),
        ),
      ),
    );
  }
}

class Notification {
  Notification({required this.title, required this.content});

  final String title;
  final String content;
}
