import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  // To make statusbar visible
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyGoogleMap(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyGoogleMap extends StatelessWidget {
  const MyGoogleMap({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 2,
          title: const Text("Google Map"),
          centerTitle: true,
          backgroundColor: Colors.green[300],
        ),
        body: const GoogleMapWidget(),
      ),
    );
  }
}

// Converting this widget to stateful so it can update marker position on Google Map
// For listening to locations we need a location package
// flutter pub add location
class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  var initialCameraPosition = const CameraPosition(
    target: LatLng(28.408913, 77.317787),
    zoom: 0,
  );

  // An instance of currentLocation
  Location currentLocation = Location();

  // Should be initialised later when streaming starts
  late StreamSubscription streamLocation;
  final Set<Marker> markers = {};
  GoogleMapController? googleMapController;

  // We need to listen for our coordinates before build
  @override
  void initState() {
    super.initState();
    streamMyLocation();
  }

  // Since we are streaming our coordinates continuously we also have to delete old coordinates
  @override
  void dispose() {
    googleMapController?.dispose();
    streamLocation.cancel();
    super.dispose();
  }

  // Function to keep track of my location
  void streamMyLocation() {
    streamLocation =
        currentLocation.onLocationChanged.listen((LocationData loc) {
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(loc.latitude ?? 0.0, loc.longitude ?? 0.0),
        ),
      );
      setState(() {
        initialCameraPosition = CameraPosition(
          target: LatLng(loc.latitude ?? 0.0, loc.longitude ?? 0.0),
          tilt: 40,
          zoom: 16,
        );
        var myloc = Marker(
            markerId: const MarkerId("Your Position"),
            position: LatLng(loc.latitude ?? 0.0, loc.longitude ?? 0.0));
        markers.add(myloc);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () {
        // Trigger to animate location
        googleMapController!.animateCamera(
          CameraUpdate.newCameraPosition(initialCameraPosition),
        );
      }),
      body: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        compassEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          googleMapController = controller;
        },
        // We defined a set of marker so we can have multiple markers
        markers: markers,
      ),
    );
  }
}
