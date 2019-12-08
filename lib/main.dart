import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geofence_demo/placeholder_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: LocationStreamWidget(),
    );
  }
}

class LocationStreamWidget extends StatefulWidget {
  @override
  State<LocationStreamWidget> createState() => LocationStreamState();
}

class LocationStreamState extends State<LocationStreamWidget> {

  StreamSubscription<Position> _positionStreamSubscription;
  final List<Position> _positions = <Position>[];
  double distance=0.0;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  new FlutterLocalNotificationsPlugin();

  void _toggleListening() {
    if (_positionStreamSubscription == null) {
      const LocationOptions locationOptions =
      LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 10);
      final Stream<Position> positionStream =
      Geolocator().getPositionStream(locationOptions);
      _positionStreamSubscription = positionStream.listen(
              (Position position) => setState(() {
            _positions.add(position);

            getDistance(position);

            Scaffold.of(context).showSnackBar(SnackBar(
              backgroundColor: Theme.of(context).primaryColorDark,
              content: Text('The distance is: $distance'),
            ));
          }));
      _positionStreamSubscription.pause();
    }

    setState(() {
      if (_positionStreamSubscription.isPaused) {
        _positionStreamSubscription.resume();
        print("Resumed");
      } else {
        _positionStreamSubscription.pause();
        print("Paused");

      }
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var android =
    AndroidInitializationSettings('mipmap/ic_launcher');
    var ios = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        android, ios);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }
  Future<void> onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }

//    await Navigator.push(
//      context,
//      MaterialPageRoute(builder: (context) => PlaceOnMap()),
//    );
  }
  Future<void> onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    await showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
//              await Navigator.push(
//                context,
//                MaterialPageRoute(
//                  builder: (context) => PlaceOnMap(),
//                ),
//              );
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription.cancel();
      _positionStreamSubscription = null;
    }

    super.dispose();
  }
  Future<void> _showNotification(double dist) async {

    // final formatter = new NumberFormat("#,##");
    // Convert Distance in meter/km to miles
    // print(formatter.format(dist));

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'Location Alert', 'You are '+dist.toString() +" meter away from  device location", platformChannelSpecifics,
        payload: 'item x');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: FutureBuilder<GeolocationStatus>(
          future: Geolocator().checkGeolocationPermissionStatus(),
          builder:
              (BuildContext context, AsyncSnapshot<GeolocationStatus> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data == GeolocationStatus.denied) {
              return const PlaceholderWidget('Location services disabled',
                  'Enable location services for this App using the device settings.');
            }

            return _buildListView();
          }),
    );
  }

  Widget _buildListView() {
    final List<Widget> listItems = <Widget>[
      ListTile(
        title: RaisedButton(
          child: _buildButtonText(),
          color: _determineButtonColor(),
          padding: const EdgeInsets.all(8.0),
          onPressed: _toggleListening,
        ),
      ),
    ];

    print(_positions.toString());
    listItems.addAll(_positions
        .map((Position position) => PositionListItem(position))
        .toList());

    return ListView(
      children: listItems,
    );
  }

  bool _isListening() => !(_positionStreamSubscription == null ||
      _positionStreamSubscription.isPaused);

  Widget _buildButtonText() {
    return Text(_isListening() ? 'Stop listening' : 'Start listening');
  }

  Color _determineButtonColor() {
    return _isListening() ? Colors.red : Colors.green;
  }

  Future getDistance(Position position) async {

    distance = await Geolocator().distanceBetween(
        12.941829, 77.627666, position.latitude, position.longitude);
    _showNotification(distance);

    Scaffold.of(context).showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).primaryColorDark,
      content: Text('The distance is: $distance'),
    ));
  }
}

class PositionListItem extends StatefulWidget {
  const PositionListItem(this._position);

  final Position _position;

  @override
  State<PositionListItem> createState() => PositionListItemState(_position);
}

class PositionListItemState extends State<PositionListItem> {
  PositionListItemState(this._position);

  final Position _position;
  String _address = '';

  @override
  Widget build(BuildContext context) {
    final Row row = Row(
      children: <Widget>[
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                'Lat: ${_position.latitude}',
                style: const TextStyle(fontSize: 16.0, color: Colors.black),
              ),
              Text(
                'Lon: ${_position.longitude}',
                style: const TextStyle(fontSize: 16.0, color: Colors.black),
              ),
            ]),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  _position.timestamp.toLocal().toString(),
                  style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                )
              ]),
        ),
      ],
    );

    return ListTile(
      onTap: _onTap,
      title: row,
      subtitle: Text(_address),
    );
  }

  Future<void> _onTap() async {
    String address = 'unknown';
    final List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(_position.latitude, _position.longitude);

    if (placemarks != null && placemarks.isNotEmpty) {
      address = _buildAddressString(placemarks.first);
    }

    setState(() {
      _address = '$address';
    });
  }


  static String _buildAddressString(Placemark placemark) {
    final String name = placemark.name ?? '';
    final String city = placemark.locality ?? '';
    final String state = placemark.administrativeArea ?? '';
    final String country = placemark.country ?? '';
    final Position position = placemark.position;

    return '$name, $city, $state, $country\n$position';
  }
}
