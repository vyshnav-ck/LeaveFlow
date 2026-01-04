import 'package:flutter/material.dart';

class DemoBasicsScreen extends StatefulWidget {
  @override
  _DemoBasicsScreenState createState() => _DemoBasicsScreenState();
}

class _DemoBasicsScreenState extends State<DemoBasicsScreen> {

  String title = "Hello Flutter!";
  TextEditingController inputController = TextEditingController();

  List<String> items = ["Apple", "Banana", "Grapes"];

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Flutter Basics Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // TEXT + BUTTON (setState)
            Text(title, style: TextStyle(fontSize: 24)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  title = "You clicked the button!";
                });
              },
              child: Text("Click Me"),
            ),

            Divider(height: 30),

            // ROW + SPACER
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange),
                Spacer(),
                Icon(Icons.favorite, color: Colors.red),
              ],
            ),

            Divider(height: 30),

            // STACK
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.blue.shade100,
                ),
                Positioned(
                  left: 20,
                  top: 20,
                  child: Text("This is a Stack"),
                )
              ],
            ),

            Divider(height: 30),

            // TEXTFIELD + ADD TO LIST
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    decoration: InputDecoration(
                      hintText: "Enter item",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (inputController.text.isNotEmpty) {
                        items.add(inputController.text);
                        inputController.clear();
                      }
                    });
                  },
                  child: Text("Add"),
                ),
              ],
            ),

            SizedBox(height: 20),

            // LISTVIEW
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.circle, size: 10),
                    title: Text(items[index]),
                  );
                },
              ),
            ),

          ],
        ),

      ),
    );
  }
}
