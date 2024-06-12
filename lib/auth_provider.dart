import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
//import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  String? _userName;
  int? _customerId;
  int? _vendorId; // Add this line to store the vendor ID
  bool _isSignUp = false;
  bool _isVendor = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userName => _userName;
  int? get customerId => _customerId;
  int? get vendorId => _vendorId; // Add this line to access the vendor ID
  bool get isSignUp => _isSignUp;
  bool get isVendor => _isVendor;

  void setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  Future<void> login(String mobileNumber, bool isVendor) async {
    try {
      String url = isVendor
          ? 'http://127.0.0.1:8000/vendorsignin/'
          : 'http://127.0.0.1:8000/customersignin/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_no': mobileNumber}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _token = responseData['token'];
        _userName = responseData['Welcome'];
        if (isVendor) {
          _vendorId = responseData['vendor_id']; // Store the vendor ID
        } else {
          _customerId = responseData['customer_id']; // Store the customer ID
        }
        _isLoggedIn = true;
        _isVendor = isVendor;
        notifyListeners();
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (error) {
      throw Exception('Failed to login: $error');
    }
  }

  Future<void> signUp(
      String name, String email, String mobileNumber, bool isVendor) async {
    try {
      String url = isVendor
          ? 'http://127.0.0.1:8000/vendorauth/'
          : 'http://127.0.0.1:8000/customerauth/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'mobile_no': mobileNumber,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _token = responseData['token'];
        _userName = responseData['userName'];
        _isLoggedIn = false;
        _isVendor = isVendor;
        notifyListeners();
      } else {
        throw Exception('Failed to sign up: ${response.body}');
      }
    } catch (error) {
      throw Exception('Failed to sign up: $error');
    }
  }

  Future<void> saveVendorProfile(String gstin, String businessName,
      List<File> businessPhotos, File panCard) async {
    if (_vendorId == null) {
      throw Exception('Vendor ID is not available');
    }

    var uri = Uri.parse('http://127.0.0.1:8000/vendor-complete-profile/');
    var request = http.MultipartRequest('POST', uri);

    request.fields['gstin'] = gstin;
    request.fields['business_name'] = businessName;
    request.fields['vendor_id'] = _vendorId.toString(); // Include the vendor ID

    for (var photo in businessPhotos) {
      var mimeType = lookupMimeType(photo.path);
      var multipartFile = await http.MultipartFile.fromPath(
        'business_photos',
        photo.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      request.files.add(multipartFile);
    }

    var panCardMimeType = lookupMimeType(panCard.path);
    var panCardFile = await http.MultipartFile.fromPath(
      'pan_card',
      panCard.path,
      contentType:
          panCardMimeType != null ? MediaType.parse(panCardMimeType) : null,
    );
    request.files.add(panCardFile);

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to save vendor profile: $responseBody');
    }
  }

  Future<void> saveVendorProfileWeb(
      String gstin,
      String businessName,
      List<Uint8List> businessPhotosData,
      Uint8List panCardData,
      List<String> businessPhotoNames,
      String panCardName) async {
    if (_vendorId == null) {
      throw Exception('Vendor ID is not available');
    }

    var uri = Uri.parse('http://127.0.0.1:8000/vendor-complete-profile/');
    var request = http.MultipartRequest('POST', uri);

    request.fields['gstin_number'] = gstin;
    request.fields['business_name'] = businessName;
    request.fields['vendor_id'] = _vendorId.toString(); // Include the vendor ID

    for (int i = 0; i < businessPhotosData.length; i++) {
      var mimeType = lookupMimeType(businessPhotoNames[i]);
      var multipartFile = http.MultipartFile.fromBytes(
        'business_photos',
        businessPhotosData[i],
        filename: businessPhotoNames[i],
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      request.files.add(multipartFile);
    }

    var panCardMimeType = lookupMimeType(panCardName);
    var panCardFile = http.MultipartFile.fromBytes(
      'pan_card',
      panCardData,
      filename: panCardName,
      contentType:
          panCardMimeType != null ? MediaType.parse(panCardMimeType) : null,
    );
    request.files.add(panCardFile);

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to save vendor profile: $responseBody');
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    if (_token == null || (_customerId == null && _vendorId == null)) {
      // Check if either customer ID or vendor ID is available
      throw Exception('User is not authenticated');
    }

    try {
      String url = _isVendor
          ? 'http://127.0.0.1:8000/vend_location/'
          : 'http://127.0.0.1:8000/cust_location/';

      // Construct the request body
      Map<String, dynamic> requestBody = {
        'latitude': latitude,
        'longitude': longitude,
      };

      if (_isVendor) {
        requestBody['vendor_id'] = _vendorId;
      } else {
        requestBody['customer_id'] = _customerId;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (error) {
      throw Exception('Failed to update location: $error');
    }
  }

  void logout() {
    _token = null;
    _userName = null;
    _customerId = null;
    _vendorId = null; // Reset the vendor ID
    _isLoggedIn = false;
    _isVendor = false;
    notifyListeners();
  }

  void toggleAuthMode() {
    _isSignUp = !_isSignUp;
    notifyListeners();
  }
}
