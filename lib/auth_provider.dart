import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  String? _userName;
  bool _isSignUp = false;
  bool _isVendor = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userName => _userName;
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
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/vendorprofile/'),
      );
      request.fields['gstin'] = gstin;
      request.fields['business_name'] = businessName;

      for (var photo in businessPhotos) {
        request.files.add(
            await http.MultipartFile.fromPath('business_photos', photo.path));
      }

      request.files
          .add(await http.MultipartFile.fromPath('pan_card', panCard.path));

      final response = await request.send();

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Failed to save vendor profile: $responseBody');
      }
    } catch (error) {
      throw Exception('Failed to save vendor profile: $error');
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    if (_token == null) {
      throw Exception('User is not authenticated');
    }

    try {
      String url = _isVendor
          ? 'http://127.0.0.1:8000/vend_location/'
          : 'http://127.0.0.1:8000/cust_location/';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
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
    _isLoggedIn = false;
    _isVendor = false;
    notifyListeners();
  }

  void toggleAuthMode() {
    _isSignUp = !_isSignUp;
    notifyListeners();
  }
}
