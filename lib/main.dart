import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'getroutesdata.dart';

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
      home: GoogleMapWidget(),
      debugShowCheckedModeBanner: false,
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
  late BitmapDescriptor myDesMarker;

// --------------------------------------------------------------------------------------------------------------------------

  // A list for containing all points and a set of polylines to pass to GoogleMap
  List<LatLng> polyPoints = [];
  Set<Polyline> polyLines = {};

  // Make four variables for storing longitude and latitude for polylines
  late LatLng startPos;
  late LatLng endPos;

// -----------------------------------------------------------------------------------------------------------------------------

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

//------------------------------------------------------------------------------------------------------------------------------------

  void getDirections() async {
    // Lets say starting position is our initialCameraPosition
    startPos = initialCameraPosition.target;

    // For Clearing polylines each time
    setState(() {
      polyPoints = [];
    });

    // Getting Value from JSON
    NetworkHelper network = NetworkHelper(
      startLat: startPos.latitude,
      startLng: startPos.longitude,
      endLat: endPos.latitude,
      endLng: endPos.longitude,
    );
    try {
      var data = await network.getData();
      LineString ls =
          LineString(data['features'][0]['geometry']['coordinates']);

      for (int i = 0; i < ls.lineString.length; i++) {
        polyPoints.add(LatLng(ls.lineString[i][1], ls.lineString[i][0]));
      }

      if (polyPoints.length == ls.lineString.length) {
        setPolyLines();
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Response error please check your connection');
    }
  }

  // Putting Value in polylines
  void setPolyLines() {
    Polyline polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.red,
      points: polyPoints,
    );
    polyLines.add(polyline);
    setState(() {});
  }

// ------------------------------------------------------------------------------------------------------------------------------------

  // We shouldn't use future in initState
  Future<void> LoadMarker() async {
    myPos = await getMapIcon("assets/markers/AvatarM.png");
    myDesMarker = await getMapIcon("assets/markers/AvatarF.png");
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
      icon: myDesMarker,

      // Setting value to endPos
      onTap: () {
        endPos = LatLng(coords.latitude, coords.longitude);
      },
      infoWindow: InfoWindow(
        title: "Navigate",

        // Click on marker then click on navigate
        onTap: () => getDirections(),
      ),
      position: LatLng(coords.latitude, coords.longitude),
    );
    markers.add(destination);
  }

//-----------------------------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: const Text("Google Map"),
        centerTitle: true,
        backgroundColor: Colors.green[300],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.navigation),
          backgroundColor: Colors.green[300],
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
        mapToolbarEnabled: false,

        // Triggering destination marker on long press
        onLongPress: (coords) => putDestination(coords),

        onMapCreated: (controller) {
          googleMapController = controller;
        },

        // We defined a set of marker so we can have multiple markers
        markers: markers,
        polylines: polyLines,
      ),
    );
  }
}

// -----------------------------------------------------------------------------------------------------------------------------------
class LineString {
  LineString(this.lineString);
  List<dynamic> lineString;
}
// ------------------------------------------------------------------------------------------------------------------------------------