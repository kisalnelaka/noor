import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class InsightMapView extends StatelessWidget {
  final double lat;
  final double lng;
  final String title;

  const InsightMapView({
    Key? key, 
    required this.lat, 
    required this.lng,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.hardEdge,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lng),
          zoom: 15.0,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('property'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: title),
          )
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }
}
