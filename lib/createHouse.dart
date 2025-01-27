import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

var uuid = Uuid();
var houseCode = uuid.v4();

class CreateHousePage extends StatefulWidget {
  @override
  _CreateHousePageState createState() => _CreateHousePageState();
}

class _CreateHousePageState extends State<CreateHousePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(""),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 70),
            Text(
              'Your house code is:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.grey[300],
              width:
                  double.infinity, // Make the container as wide as the parent
              child: Center(
                  child: Text(
                houseCode,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis, // Handle overflow
              )),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                Clipboard.setData(ClipboardData(text: houseCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('House code copied to clipboard')),
                );
              },
              child: Text('Copy Code'),
            ),
            SizedBox(height: 70),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[100],
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                onPressed: () async {
                  var url;
                  if (kIsWeb) {
                    url = Uri.parse('https://servidor-ssw.onrender.com/house/createhouse');
                  } else {
                    url = Uri.parse('https://servidor-ssw.onrender.com/house/createhouse');
                  }

                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  String? token = await prefs.getString('token');
                  token = token!.substring(1, token.length - 1);
                  var response = await http.post(
                    url,
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({'houseCode': houseCode}),
                  );

                  if (response.statusCode == 200) {
                    print('House created successfully');
                    context.go('/ListsPage.dart');
                  } else {
                    print(response.body);
                  }
                },
                child: const Text(
                  'Create House',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
