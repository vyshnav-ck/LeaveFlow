import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/counter_provider.dart';

class ProviderDemoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final counter = Provider.of<CounterProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Provider Demo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              "Count: ${counter.count}",
              style: TextStyle(fontSize: 30),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: counter.increment,
              child: Text("Increment"),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: counter.reset,
              child: Text("Reset"),
            ),
          ],
        ),
      ),
    );
  }
}
