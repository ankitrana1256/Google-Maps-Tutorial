import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
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

  // Changing Marker icon with our icon
  BitmapDescriptor myPos = BitmapDescriptor.defaultMarker;

  // We need to listen for our coordinates before build
  @override
  void initState() {
    // Loading marker before the build
    LoadMarker();
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

// ------------------------------------------------------------------------------------------------------------------------------------

  // We shouldn't use future in initState
  Future<void> LoadMarker() async {
    myPos = await getMapIcon("assets/markers/AvatarM.png");
  }

  // This functions will take the uint and convert it to bitmap
  Future<BitmapDescriptor> getMapIcon(String iconPath) async {
    final Uint8List endMarker = await getBytesFromAsset(iconPath, 120);
    final icon = BitmapDescriptor.fromBytes(endMarker);
    return icon;
  }

  // This functions will take the image from asset and convert it to uint
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    var codec = await instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
// ------------------------------------------------------------------------------------------------------------------------------------

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

            // Specifying marker
            icon: myPos,
            position: LatLng(loc.latitude ?? 0.0, loc.longitude ?? 0.0));
        markers.add(myloc);
      });
    });
  }

//-------------------------------------------------------------------------------------------------------------------------------------

  // To place a destination marker
  void putDestination(coords) {
    var destination = Marker(
      markerId: const MarkerId("Destination"),
      // Changing color of the marker
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      position: LatLng(coords.latitude, coords.longitude),
    );
    markers.add(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.navigation),
          backgroundColor: Colors.green,
          onPressed: () {
            // Trigger to animate location
            googleMapController!.animateCamera(
              CameraUpdate.newCameraPosition(initialCameraPosition),
            );
          }),
      body: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        compassEnabled: false,
        zoomControlsEnabled: false,

        // Triggering destination marker on long press
        onLongPress: (coords) => putDestination(coords),

        onMapCreated: (controller) {
          googleMapController = controller;
        },
        // We defined a set of marker so we can have multiple markers
        markers: markers,
      ),
    );
  }
}
