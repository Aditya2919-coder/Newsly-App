import 'package:flutter/material.dart';

/// Placeholder OTP verification screen — implement your OTP UI here.
class OtpVerificationScreen extends StatelessWidget {
  final String? phoneNumber;

  const OtpVerificationScreen({super.key, this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('OTP Verification${phoneNumber != null ? ' for $phoneNumber' : ''}'),
      ),
    );
  }
}
