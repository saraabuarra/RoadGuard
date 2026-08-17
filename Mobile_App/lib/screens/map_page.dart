import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatelessWidget {
  final double lat;
  final double lng;

  const MapPage({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Location")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lng),
          zoom: 15,
        ),
        markers: {
          Marker(markerId: MarkerId("location"), position: LatLng(lat, lng)),
        },
      ),
    );
  }
}
