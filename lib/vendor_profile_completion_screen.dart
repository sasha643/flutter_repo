import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_provider.dart';
import 'map_screen.dart';
import 'dart:io' show File; // Import for mobile platforms
import 'package:flutter/foundation.dart'
    show kIsWeb; // Check if platform is web
import 'dart:typed_data'; // For web files

class VendorProfileCompletionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: VendorProfileForm(),
      ),
    );
  }
}

class VendorProfileForm extends StatefulWidget {
  @override
  _VendorProfileFormState createState() => _VendorProfileFormState();
}

class _VendorProfileFormState extends State<VendorProfileForm> {
  final _formKey = GlobalKey<FormState>();
  String? _gstin, _businessName;
  List<XFile> _businessPhotos = [];
  XFile? _panCard;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickBusinessPhotos() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _businessPhotos = pickedFiles;
      });
    }
  }

  Future<void> _pickPanCard() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _panCard = pickedFile;
      });
    }
  }

  Future<void> _completeProfile(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_panCard != null && _businessPhotos.isNotEmpty) {
        try {
          if (kIsWeb) {
            // Handling for web
            List<Uint8List> businessPhotosData = [];
            for (var xFile in _businessPhotos) {
              var bytes = await xFile.readAsBytes();
              businessPhotosData.add(bytes);
            }

            Uint8List panCardData = await _panCard!.readAsBytes();

            await authProvider.saveVendorProfileWeb(
              _gstin ?? '',
              _businessName!,
              businessPhotosData,
              panCardData,
              _businessPhotos.map((xFile) => xFile.name).toList(),
              _panCard!.name,
            );
          } else {
            // Handling for mobile (or other platforms)
            List<File> businessPhotosFiles =
                _businessPhotos.map((xFile) => File(xFile.path)).toList();
            File panCardFile = File(_panCard!.path);

            await authProvider.saveVendorProfile(
              _gstin ?? '',
              _businessName!,
              businessPhotosFiles,
              panCardFile,
            );
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MapScreen()),
          );
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to save profile: $error'),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please upload business photos and PAN card.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'GSTIN (Optional)'),
              onSaved: (value) => _gstin = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Business Name'),
              validator: (value) =>
                  value!.isEmpty ? 'Enter a business name' : null,
              onSaved: (value) => _businessName = value,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickBusinessPhotos,
              child: Text('Upload Business Photos'),
            ),
            _businessPhotos.isNotEmpty
                ? Text('${_businessPhotos.length} photos selected')
                : Container(),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickPanCard,
              child: Text('Upload PAN Card'),
            ),
            _panCard != null ? Text('PAN Card selected') : Container(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _completeProfile(context),
              child: Text('Complete Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
