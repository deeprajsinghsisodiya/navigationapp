import 'package:flutter/material.dart';

import 'notiificationservice.dart';


class homescreen extends StatefulWidget {
  const homescreen({Key? key}) : super(key: key);

  @override
  State<homescreen> createState() => _homescreenState();
}

class _homescreenState extends State<homescreen> {

  NotificationServices notificationServices = NotificationServices();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.firebaseInit();

    notificationServices.getDeviceToken().then((value) {
      print(value);
    });
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold();
  }
}
