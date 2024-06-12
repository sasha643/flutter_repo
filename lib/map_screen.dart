import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'auth_screen.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng _currentPosition = LatLng(37.7749, -122.4194);
  String _currentAddress = '';
  bool _isLocationReady = false;
  Marker? _currentLocationMarker;
  TextEditingController _addressController = TextEditingController();
  String _lastAddress = '';

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
    _getLocation();
  }

  void _onAddressChanged() {
    if (_addressController.text != _lastAddress) {
      _lastAddress = _addressController.text;
      _printLatLngForAddress(_lastAddress);
    }
  }

  Future<void> _printLatLngForAddress(String address) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=";
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['results'].isNotEmpty) {
          var location = jsonData['results'][0]['geometry']['location'];
          double lat = location['lat'];
          double lng = location['lng'];
          print('Address: $address -> Latitude: $lat, Longitude: $lng');
        }
      } else {
        print(
            "Failed to fetch coordinates for the address. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error getting coordinates for address: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_isLocationReady) {
      mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    }
  }

  Future<void> _getLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng initialPosition = LatLng(position.latitude, position.longitude);

      // Print the latitude and longitude
      print(
          'Current Position: ${initialPosition.latitude}, ${initialPosition.longitude}');

      // Fetch initial address
      String initialAddress = await _getAddressFromLatLng(initialPosition);

      setState(() {
        _currentPosition = initialPosition;
        _currentAddress = initialAddress;
        _addressController.text = _currentAddress;
        _currentLocationMarker = Marker(
          markerId: MarkerId('currentLocation'),
          position: _currentPosition,
          draggable: true,
          onDragEnd: (newPosition) => _onMarkerDragEnd(newPosition),
        );
        _isLocationReady = true;
      });

      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      }

      Geolocator.getPositionStream().listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentLocationMarker = Marker(
            markerId: MarkerId('currentLocation'),
            position: _currentPosition,
            draggable: true,
            onDragEnd: (newPosition) => _onMarkerDragEnd(newPosition),
          );

          if (mapController != null) {
            mapController!
                .animateCamera(CameraUpdate.newLatLng(_currentPosition));
          }
          _updateLocationOnServer(
              _currentPosition.latitude, _currentPosition.longitude);
        });
      });
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=";
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return jsonData['results'][0]['formatted_address'];
      } else {
        print("Failed to fetch address. Status code: ${response.statusCode}");
        return '';
      }
    } catch (e) {
      print("Error getting current address: $e");
      return '';
    }
  }

  void _onMarkerDragEnd(LatLng newPosition) async {
    try {
      String address = await _getAddressFromLatLng(newPosition);

      // Print the latitude and longitude when the marker is dragged
      print(
          'Dragged Position: ${newPosition.latitude}, ${newPosition.longitude}');
      await _updateLocationOnServer(
          newPosition.latitude, newPosition.longitude);

      setState(() {
        _currentAddress = address;
        _addressController.text = _currentAddress;
      });
    } catch (e) {
      print("Error getting current address: $e");
    }
  }

  Future<void> _updateLocationOnServer(
      double latitude, double longitude) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final custId = authProvider.customerId;
      final vendorId = authProvider.vendorId;

      if (custId == null && vendorId == null) {
        print('No ID available. Unable to update location.');
        return;
      }

      String url;
      Map<String, dynamic> body;

      if (authProvider.isVendor) {
        if (vendorId == null) {
          print('Vendor ID not available. Unable to update location.');
          return;
        }
        url = 'http://127.0.0.1:8000/vend_location/';
        body = {
          'latitude': latitude,
          'longitude': longitude,
          'vendor_id': vendorId,
        };
      } else {
        if (custId == null) {
          print('Customer ID not available. Unable to update location.');
          return;
        }
        url = 'http://127.0.0.1:8000/cust_location/';
        body = {
          'latitude': latitude,
          'longitude': longitude,
          'customer_id': custId,
        };
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update location: ${response.body}');
      }

      print('Location updated on server: ($latitude, $longitude)');
    } catch (error) {
      print("Error updating location on server: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AuthScreen(isVendor: authProvider.isVendor)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15.0,
            ),
            markers: _currentLocationMarker != null
                ? Set.of([_currentLocationMarker!])
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onCameraMove: (CameraPosition position) {
              setState(() {
                _currentPosition = position.target;
              });
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    super.dispose();
  }
}
