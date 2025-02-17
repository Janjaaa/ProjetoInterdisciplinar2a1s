import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projeto/haveHouse.dart';
import 'ListsPage.dart';
import 'createHouse.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() => runApp(const MyApp());

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
            path: '/haveHouse.dart',
            builder: (BuildContext context, GoRouterState state) {
              return HousePage();
            }),
        GoRoute(
          path: '/ListsPage.dart',
          builder: (BuildContext context, GoRouterState state) {
            return const Listspage();
          },
        ),
        GoRoute(
          path: '/main.dart',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/createHouse.dart',
          builder: (BuildContext context, GoRouterState state) {
            return CreateHousePage();
          },
        )
      ],
    ),
  ],
);

Future registerUser(String name, String email, String password) async {
  var url;
  if (kIsWeb) {
    url = Uri.parse('https://servidor-ssw.onrender.com/users/register');
  } else {
    url = Uri.parse('https://servidor-ssw.onrender.com/users/register');
  }
  var response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'name': name,
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    print('User registered successfully');
    return response.statusCode;
  } else {
    print('Failed to register user: ${response.statusCode}');
    return response.statusCode;
  }
}

Future loginUser(String email, String password) async {
  Uri url;
  if (kIsWeb) {
    url = Uri.parse('https://servidor-ssw.onrender.com/users/login');
  } else {
    url = Uri.parse('https://servidor-ssw.onrender.com/users/login');
  }
  var response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    print('User logged in successfully');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', response.body);
    await prefs.setString('email', email);
    String? token = await prefs.getString('token');
    token = token!.substring(1, token.length - 1);

    Map<String, dynamic> decodedToken = parseJwt(token);
    print(decodedToken);
    print(decodedToken['data']['name']);
    var userHouse = decodedToken['data']['homeId'];
    var url;

    if (kIsWeb) {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/house/gethouse/$userHouse');
    } else {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/house/gethouse/$userHouse');
    }
    response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var houseResponse = json.decode(response.body);
      var house = houseResponse[0];

      await prefs.setString('houseCode', house['houseCode']);
    } else {
      print(response.statusCode);
      return "no house";
    }
    return response.statusCode;
  } else {
    print('Failed to login user: ${response.statusCode}');
    return response.statusCode;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: null,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(0), // Adjust the height as needed
              child: TabBar(
                tabs: [
                  Tab(text: 'Login'),
                  Tab(text: 'Signup'),
                ],
              ),
            ),
          ),
          body: TabBarView(
            children: [
              LoginForm(),
              SignupForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() {
    return LoginFormState();
  }
}

class LoginFormState extends State<LoginForm> {
  final _loginformKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? emailError;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      context.go('/ListsPage.dart');
    }
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    if (emailError != null) {
      return emailError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 50),
            Icon(Icons.account_circle, size: 100, color: Colors.grey),
            Form(
              key: _loginformKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                      validator: emailValidator,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 200),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          emailError = null;
                        });
                        if (_loginformKey.currentState!.validate()) {
                          final response = await loginUser(
                              usernameController.text, passwordController.text);

                          if (response == 200) {
                            context.go('/ListsPage.dart');
                          } else if (response == "no house") {
                            context.go('/haveHouse.dart');
                          } else {
                            setState(() {
                              emailError = "Wrong email or password!";
                            });
                            _loginformKey.currentState!.validate();
                            print("credentials incorrect");
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[100],
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  SignupFormState createState() {
    return SignupFormState();
  }
}

class SignupFormState extends State<SignupForm> {
  final _signupformKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? emailError;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    if (emailError != null) {
      return emailError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 50),
            Icon(Icons.account_circle, size: 100, color: Colors.grey),
            Form(
              key: _signupformKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                      validator: emailValidator,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          emailError = null;
                        });
                        if (_signupformKey.currentState!.validate()) {
                          final response = await registerUser(
                              nameController.text,
                              emailController.text,
                              passwordController.text);
                          if (response == 200) {
                            await loginUser(
                                emailController.text, passwordController.text);
                            context.go('/haveHouse.dart');
                          } else if (response == 406) {
                            setState(() {
                              emailError = 'Email already in use';
                            });
                            _signupformKey.currentState!.validate();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
