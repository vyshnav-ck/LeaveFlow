import 'package:flutter/material.dart';

class AddressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Address")),
      body: Center(
        child: Text(
          "Kozhikode, Kerala",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
