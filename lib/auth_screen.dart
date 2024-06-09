// auth_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'map_screen.dart';
import 'vendor_profile_completion_screen.dart';

class AuthScreen extends StatelessWidget {
  final bool isVendor;

  AuthScreen({required this.isVendor});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.token != null) {
      return isVendor ? VendorProfileCompletionScreen() : MapScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(authProvider.isSignUp ? 'Sign Up' : 'Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: authProvider.isSignUp
            ? SignUpForm(isVendor: isVendor)
            : LoginForm(isVendor: isVendor),
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  final bool isVendor;

  SignUpForm({required this.isVendor});

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _email, _mobileNumber;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Name'),
            validator: (value) => value!.isEmpty ? 'Enter your name' : null,
            onSaved: (value) => _name = value,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) => value!.isEmpty ? 'Enter an email' : null,
            onSaved: (value) => _email = value,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Mobile Number'),
            validator: (value) =>
                value!.isEmpty ? 'Enter a mobile number' : null,
            onSaved: (value) => _mobileNumber = value,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                authProvider
                    .signUp(_name!, _email!, _mobileNumber!, widget.isVendor)
                    .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Sign Up successful. Please log in.'),
                  ));
                  authProvider.toggleAuthMode();
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Sign Up failed: $error'),
                  ));
                });
              }
            },
            child: Text('Sign Up'),
          ),
          TextButton(
            onPressed: () {
              authProvider.toggleAuthMode();
            },
            child: Text('Already have an account? Login'),
          ),
        ],
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final bool isVendor;

  LoginForm({required this.isVendor});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String? _mobileNumber;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Mobile Number'),
            validator: (value) =>
                value!.isEmpty ? 'Enter a mobile number' : null,
            onSaved: (value) => _mobileNumber = value,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                try {
                  await authProvider.login(_mobileNumber!, widget.isVendor);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Welcome ${authProvider.userName}!'),
                  ));
                  if (authProvider.isVendor) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              VendorProfileCompletionScreen()),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MapScreen()),
                    );
                  }
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Login failed: $error'),
                  ));
                }
              }
            },
            child: Text('Login'),
          ),
          TextButton(
            onPressed: () {
              authProvider.toggleAuthMode();
            },
            child: Text('Don\'t have an account? Sign Up'),
          ),
        ],
      ),
    );
  }
}
