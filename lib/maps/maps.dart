import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_webservice/directions.dart' as direct;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drive/connectivity_service.dart';

class MapScreen extends StatefulWidget {
  final info;
  const MapScreen(this.info, {Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  ConnectivityService connectivity = ConnectivityService();
  final directions = direct.GoogleMapsDirections(apiKey: dotenv.env['API_KEY']);
  late LatLng _pickupLocation;
  late LatLng _deliveryLocation;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;

  double distanceInMeters = 0;
  String duration = "";

  late LatLng _center = const LatLng(14.440966, 121.003250);

  late BitmapDescriptor _pickUpIcon;
  late BitmapDescriptor _deliveryIcon;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _getEstimatedTime() async {
    final response = await directions.directionsWithAddress(
      widget.info['pickup_other_address'],
      widget.info['delivery_other_address'],
    );

    if (response.isOkay) {
      final route = response.routes.first;
      final leg = route.legs.first;
      final duration = leg.duration.text;
      print('Estimated time: $duration');
    } else {
      print('Error: ${response.errorMessage}');
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  double _calculateDistance() {
    final distanceInMeters = geolocator.Geolocator.distanceBetween(
      _pickupLocation.latitude,
      _pickupLocation.longitude,
      _deliveryLocation.latitude,
      _deliveryLocation.longitude,
    );

    return distanceInMeters;
  }

  void getAddressCoordinates() async {
    final pickupOtherAddress = widget.info['pickup_other_address'];
    final pickup = await getCoordinatesFromAddress(pickupOtherAddress);

    final deliveryOtherAddress = widget.info['delivery_other_address'];
    final delivery = await getCoordinatesFromAddress(deliveryOtherAddress);

    _pickupLocation =
        LatLng(pickup['latitude'] as double, pickup['longitude'] as double);
    _deliveryLocation =
        LatLng(delivery['latitude'] as double, delivery['longitude'] as double);
    setState(() {
      _getDirections();
      _calculateDistance();
      _getEstimatedTime();
      calculateCenter();
    });
  }

  void calculateCenter() {
    double lat1 = _pickupLocation.latitude;
    double lon1 = _pickupLocation.longitude;
    double lat2 = _deliveryLocation.latitude;
    double lon2 = _deliveryLocation.longitude;

    double centerLat = (lat1 + lat2) / 2;
    double centerLon = (lon1 + lon2) / 2;

    _center = LatLng(centerLat, centerLon);
  }

  Future<Map<String, double>> getCoordinatesFromAddress(String address) async {
    final apiKey = dotenv.env['API_KEY'];
    final encodedAddress = Uri.encodeComponent(address);
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);

      if (decodedData['status'] == 'OK') {
        final location = decodedData['results'][0]['geometry']['location'];

        final latitude = location['lat'] as double;
        final longitude = location['lng'] as double;

        return {'latitude': latitude, 'longitude': longitude};
      } else {
        throw Exception('Geocoding API request failed');
      }
    } else {
      throw Exception('Failed to load data from Geocoding API');
    }
  }

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _getCurrentLocation();
    getAddressCoordinates();
    _resizeMarkerIcon();
  }

  void _initConnectivity() async {
    bool isConnected = await connectivity.isConnected();
    if (!isConnected) {
      ConnectivityService.noInternetDialog(context);
    }
  }

  Future<void> _resizeMarkerIcon() async {
    final Uint8List pickup = await _loadAssetImage(
      'assets/images/location.png',
      width: 80,
      height: 80,
    );

    final Uint8List delivery = await _loadAssetImage(
      'assets/images/warehouse.png',
      width: 80,
      height: 80,
    );

    setState(() {
      _pickUpIcon = BitmapDescriptor.fromBytes(pickup);
      _deliveryIcon = BitmapDescriptor.fromBytes(delivery);
    });
  }

  Future<Uint8List> _loadAssetImage(String assetPath,
      {int? width, int? height}) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final Uint8List imageData = data.buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(imageData,
        targetWidth: width, targetHeight: height);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image resizedImage = frameInfo.image;

    final ByteData? resizedByteData =
        await resizedImage.toByteData(format: ui.ImageByteFormat.png);

    return resizedByteData!.buffer.asUint8List();
  }

  void showTooltip() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
              constraints: const BoxConstraints(maxHeight: 100.0),
              child: Column(children: [
                Text(
                    'Estimated Distance: ${(_calculateDistance() / 1000).toStringAsFixed(2)} km'),
                const SizedBox(height: 5.0),
                Text('Estimated Time: $duration'),
              ])),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _getDirections() async {
    try {
      String route = await Directions.getDirections(
          _pickupLocation.latitude,
          _pickupLocation.longitude,
          _deliveryLocation.latitude,
          _deliveryLocation.longitude);

      setState(() {
        _polylines.add(Polyline(
            consumeTapEvents: true,
            polylineId: const PolylineId('route'),
            points: _convertToLatLng(_decodePolyline(route)),
            color: Colors.red.shade900,
            width: 6,
            onTap: () {
              showTooltip();
            }));

        _markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation,
          icon: _pickUpIcon,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ));

        _markers.add(Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation,
          icon: _deliveryIcon,
          infoWindow: const InfoWindow(title: 'Delivery Location'),
        ));
      });
    } catch (e) {
      print(e);
    }
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = [];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List _decodePolyline(String polyline) {
    var points = polyline.codeUnits;
    var len = points.length;
    var index = 0;
    var lat = 0;
    var lng = 0;
    List results = [];

    while (index < len) {
      int b;
      var shift = 0;
      var result = 0;
      do {
        b = points[index] - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
        index++;
      } while (b >= 0x20);

      var dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = points[index] - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
        index++;
      } while (b >= 0x20);

      var dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      results.add(lat / 1e5);
      results.add(lng / 1e5);
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController pickuploc = TextEditingController(
        text: widget.info['pickup_other_address'].toString());
    final TextEditingController deliveryloc = TextEditingController(
        text: widget.info['delivery_other_address'].toString());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup and Delivery'),
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 12.0,
            ),
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            polylines: _polylines,
            markers: Set<Marker>.from(_markers)),
        Positioned(
            top: 5.0,
            left: 5.0,
            right: 5.0,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200.0),
              child: SingleChildScrollView(
                  child: TextField(
                controller: pickuploc,
                keyboardType: TextInputType.text,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    overflow: TextOverflow.ellipsis),
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(70.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(70.0),
                    ),
                    labelText: 'Pickup Location',
                    labelStyle: TextStyle(color: Colors.orange.shade900),
                    prefixIcon: const Icon(Icons.location_on, size: 24),
                    prefixIconColor: Colors.red),
              )),
            )),
        Positioned(
          top: 70.0,
          left: 5.0,
          right: 5.0,
          child: Container(
              constraints: const BoxConstraints(maxHeight: 200.0),
              child: SingleChildScrollView(
                  child: TextField(
                controller: deliveryloc,
                keyboardType: TextInputType.text,
                style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.transparent,
                  labelText: 'Delivery Location',
                  labelStyle: TextStyle(color: Colors.orange.shade900),
                  prefixIcon: const Icon(Icons.pin_drop, size: 24),
                  prefixIconColor: Colors.red,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(70.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(70.0),
                  ),
                ),
              ))),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red.shade900,
        child: const Icon(Icons.my_location),
        onPressed: () {
          mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation ?? const LatLng(0.0, 0.0),
                zoom: 11.0,
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class Directions {
  static final _apiKey = dotenv.env['API_KEY'];

  static Future<String> getDirections(
      double startLat, double startLng, double endLat, double endLng) async {
    String apiUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$_apiKey';

    final response = await http.get(Uri.parse(apiUrl));
    final json = jsonDecode(response.body);
    if (json['status'] == 'OK') {
      var routes = json['routes'][0]['overview_polyline']['points'];
      return routes;
    } else {
      throw Exception('Failed to fetch directions');
    }
  }
}
