import 'package:flutter/material.dart';
import 'auth_screen.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select User Type'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CheckboxListTile(
              title: Text('Vendor'),
              value: true, // Default to vendor
              onChanged: (value) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AuthScreen(isVendor: true)),
                );
              },
            ),
            CheckboxListTile(
              title: Text('Customer'),
              value: false,
              onChanged: (value) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AuthScreen(isVendor: false)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
