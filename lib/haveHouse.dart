import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HousePage extends StatefulWidget {
  @override
  _HousePageState createState() => _HousePageState();
}

class _HousePageState extends State<HousePage> {
  final _houseCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

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
              'Do you have a "house"?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
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
                  if (_formKey.currentState!.validate()) {
                    var url;
                    if (kIsWeb) {
                      url = Uri.parse('http://localhost:3000/house/joinhouse');
                    } else {
                      url = Uri.parse('http://10.0.2.2:3000/house/joinhouse');
                    }

                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    String? token = await prefs.getString('token');
                    token = token!.substring(1, token.length - 1);
                    print(token);
                    var response = await http.post(
                      url,
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
                      },
                      body:
                          jsonEncode({'houseCode': _houseCodeController.text}),
                    );

                    if (response.statusCode == 200) {
                      await prefs.setString(
                          'houseCode', _houseCodeController.text);
                      print(_houseCodeController.text);
                      context.go('/ListsPage.dart');
                      setState(() {
                        _errorMessage = null;
                      });
                    } else {
                      setState(() {
                        _errorMessage = "Please enter a valid code!";
                      });
                      _formKey.currentState!.validate();
                    }
                  }
                },
                child: const Text(
                  'Yes',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _houseCodeController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your house code',
                ),
                validator: (value) {
                  if (_errorMessage != null) {
                    return _errorMessage;
                  }
                  if (value == null || value.isEmpty) {
                    return 'Please enter your house code';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: 70),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  context.go('/createHouse.dart');
                },
                child: const Text(
                  'No',
                  style: TextStyle(
                    color: Colors.white,
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
