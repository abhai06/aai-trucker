import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const MapPage());

class MapPage extends StatelessWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MapController mapController = MapController();

    return Scaffold(
        appBar: AppBar(),
        body: FlutterMap(
          options: MapOptions(
            center: LatLng(14.440966, 121.003250),
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
              polylineCulling: true,
              polylines: [
                Polyline(
                  points: [
                    LatLng(14.440966, 121.003250),
                    LatLng(14.499394, 121.006679),
                  ],
                  color: Colors.blue,
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
                            child: Column(
                          children: const [
                            Text(
                              'Pick Up Point',
                              style: TextStyle(
                                backgroundColor: Colors.yellow,
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.mode_standby,
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
                      child: Column(
                    children: const [
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
              ],
            ),
          ],
        ));
  }
}
