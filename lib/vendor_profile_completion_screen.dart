import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'auth_provider.dart';
import 'map_screen.dart';

class VendorProfileCompletionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
  List<File> _businessPhotos = [];
  File? _panCard;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickBusinessPhotos() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _businessPhotos = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _pickPanCard() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _panCard = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                if (_panCard != null && _businessPhotos.isNotEmpty) {
                  authProvider
                      .saveVendorProfile(_gstin ?? '', _businessName!,
                          _businessPhotos, _panCard!)
                      .then((_) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MapScreen()),
                    );
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to save profile: $error'),
                    ));
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Please upload business photos and PAN card.'),
                  ));
                }
              }
            },
            child: Text('Complete Profile'),
          ),
        ],
      ),
    );
  }
}
