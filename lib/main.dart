import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
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
      home: MyGoogleMap(),
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
          elevation: 0,
          title: const Text("Google Map"),
          centerTitle: true,
          backgroundColor: Colors.green[300],
        ),
        body: GoogleMapWidget(),
      ),
    );
  }
}

// Add Google Maps api in android.manifest file (android\app\src\main\AndroidManifest.xml)
// flutter pub add google_maps_flutter
// Change sdk version to support GoogleMap
// In my case minsdkversion is 20
class GoogleMapWidget extends StatelessWidget {
  const GoogleMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var initialCameraPosition = const CameraPosition(
      target: LatLng(28.408913, 77.317787),
      tilt: 40,
      zoom: 16,
    );
    return GoogleMap(
      initialCameraPosition: initialCameraPosition,

      // This is to remove the compass which comes in default
      compassEnabled: false,
      // This is to remove the zoom buttons
      zoomControlsEnabled: false,
    );
  }
}
