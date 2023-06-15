import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  // LocationData? currentLocation;
  final MapController _mapController = MapController();
  LatLng _currentLocation = LatLng(0.0, 0.0);

  // Future<void> getLocation() async {
  //   final locationService = Location();
  //   bool serviceEnabled;
  //   PermissionStatus permissionGranted;

  //   // Check if location services are enabled
  //   serviceEnabled = await locationService.serviceEnabled();
  //   if (!serviceEnabled) {
  //     serviceEnabled = await locationService.requestService();
  //     if (!serviceEnabled) {
  //       return;
  //     }
  //   }

  //   // Check if the app has location permission
  //   permissionGranted = await locationService.hasPermission();
  //   if (permissionGranted == PermissionStatus.denied) {
  //     permissionGranted = await locationService.requestPermission();
  //     if (permissionGranted != PermissionStatus.granted) {
  //       return;
  //     }
  //   }

  //   // Get the current location
  //   final locationData = await locationService.getLocation();
  //   setState(() {
  //     currentLocation = locationData;
  //   });
  // }

  void _getCurrentLocation() async {
    bool locationPermissionGranted = await Permission.location.isGranted;

    if (!locationPermissionGranted) {
      PermissionStatus status = await Permission.location.request();

      if (status != PermissionStatus.granted) {
        // Handle the case when the user denies the location permission
        return;
      }
    }
    final position = await geolocator.Geolocator.getCurrentPosition(
      desiredAccuracy: geolocator.LocationAccuracy.high,
    );
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  void initState() {
    super.initState();
    // getLocation();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    MapController mapController = MapController();

    return Scaffold(
        appBar: AppBar(),
        body: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: LatLng(14.440966, 121.003250),
            // center: _currentLocation,
            zoom: 11,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              tileProvider: NetworkTileProvider(),
              subdomains: const ['a', 'b', 'c'],
              keepBuffer: 20,
            ),
            PolylineLayer(
              polylineCulling: false,
              polylines: [
                Polyline(
                  points: [
                    LatLng(14.440966, 121.003250),
                    LatLng(14.499394, 121.006679),
                  ],
                  color: Colors.red,
                  strokeWidth: 3.0,
                ),
              ],
            ),
            MarkerLayer(
              rotateAlignment: Alignment.center,
              markers: [
                Marker(
                    point: LatLng(14.440966, 121.003250),
                    width: 80,
                    height: 80,
                    builder: (context) => Container(
                            child: const Column(
                          children: [
                            Text(
                              'Pick Up Point',
                              style: TextStyle(
                                backgroundColor: Colors.yellow,
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.location_on,
                              color: Colors.black,
                              size: 40,
                            ),
                          ],
                        ))),
                Marker(
                  point: LatLng(14.499394, 121.006679),
                  width: 80,
                  height: 80,
                  builder: (context) => Container(
                      child: const Column(
                    children: [
                      Text(
                        'Delivery Point',
                        style: TextStyle(
                          backgroundColor: Colors.yellow,
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.pin_drop,
                        color: Colors.red,
                        size: 40,
                      ),
                    ],
                  )),
                ),
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: _currentLocation,
                  builder: (ctx) => Container(
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.yellow,
                      size: 40.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}
