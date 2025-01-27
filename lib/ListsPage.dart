import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_builder_image_picker/form_builder_image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

List<int>? imgForApi;
int tabIndex = 0;
List<Product> itemsCarro = [];
String searchedItem = "";
String? emailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter some text';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(value)) {
    return 'Please enter a valid email address';
  }
  return null;
}

Map<String, dynamic> parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('Invalid token');
  }

  final payload = _decodeBase64(parts[1]);
  final payloadMap = json.decode(payload);
  if (payloadMap is! Map<String, dynamic>) {
    throw Exception('Invalid payload');
  }
  return payloadMap;
}

String _decodeBase64(String str) {
  String output = str.replaceAll('-', '+').replaceAll('_', '/');
  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw Exception('Illegal base64url string!');
  }
  return utf8.decode(base64Url.decode(output));
}

Future addPantryItem(
    String name, String brand, num quantity, String picUrl, num weight) async {
  var url;
  if (kIsWeb) {
    url = Uri.parse('https://servidor-ssw.onrender.com/house/createpantryitem');
  } else {
    url = Uri.parse('https://servidor-ssw.onrender.com/house/createpantryitem');
  }
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = await prefs.getString('token');
  token = token!.substring(1, token.length - 1);
  var response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'picUrl': picUrl,
      'weight': weight,
    }),
  );

  if (response.statusCode == 200) {
    return response.statusCode;
  } else {
    return response.statusCode;
  }
}

Future addBuyListItem(
    String name, String brand, num quantity, String picUrl, num weight) async {
  var url;
  if (kIsWeb) {
    url =
        Uri.parse('https://servidor-ssw.onrender.com/house/createbuylistitem');
  } else {
    url =
        Uri.parse('https://servidor-ssw.onrender.com/house/createbuylistitem');
  }
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = await prefs.getString('token');
  token = token!.substring(1, token.length - 1);
  var response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'picUrl': picUrl,
      'weight': weight,
    }),
  );

  if (response.statusCode == 200) {
    return response.statusCode;
  } else {
    print('failed to add item ${response.statusCode}');
    return response.statusCode;
  }
}

class Product {
  final String id;
  final String name;
  final String brand;
  int quantity;
  final int weight;
  final int v;
  String? picUrl;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.weight,
    required this.v,
    this.picUrl,
  });

  Product.fromJson(Map<String, dynamic> json)
      : id = json['_id'] as String,
        name = json['name'] as String,
        brand = json['brand'] as String,
        quantity = json['quantity'] as int,
        weight = json['weight'] as int,
        v = json['__v'] as int,
        picUrl = json['picUrl'] as String?;
  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'brand': brand,
        'quantity': quantity,
        'weight': weight,
        '__v': v,
        'picUrl': picUrl,
      };
}

class Produto {
  final String picture;
  final String name;
  final String brand;
  final num weight;

  Produto(this.picture, this.name, this.brand, this.weight);

  Produto.fromJson(Map<String, dynamic> json)
      : picture = json['picture'] as String,
        name = json['name'] as String,
        brand = json['brand'] as String,
        weight = json['weight'] as num;

  Map<String, dynamic> toJson() => {
        'picture': picture,
        'name': name,
        'brand': brand,
        'weight': weight,
      };
}

final produtosCompra = <Produto>[];

final produtosDespensa = <Produto>[];

class Listspage extends StatefulWidget {
  const Listspage({super.key});
  @override
  State<Listspage> createState() => _Listspage();
}

class _Listspage extends State<Listspage> with SingleTickerProviderStateMixin {
  late TabController _controller;
  final TextEditingController _searchController = TextEditingController();
  String userEmail = "";
  String userName = "";
  String userId = "";
  var user;
  var house;
  String houseCode = "";
  List<String> houseUsers = [];
  bool isHouseOwner = false;
  final _signupformKey = GlobalKey<FormState>();

  List<Widget> listTabs = [
    Tab(icon: Icon(Icons.shelves)),
    Tab(icon: Icon(Icons.add_shopping_cart)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: listTabs.length, vsync: this);
    _controller.addListener(() {
      setState(() {
        tabIndex = _controller.index;
      });
    });
  }

  void getHouseInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = await prefs.getString('token');
    token = token!.substring(1, token.length - 1);
    Map<String, dynamic> decodedToken = parseJwt(token);
    var tempHouseCode = (await prefs.getString('houseCode'))!;
    userId = decodedToken['data']['userId'];

    List<String> tempHouseUsers = [];
    bool tempIsHouseOwner = false;

    var url;
    if (kIsWeb) {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/users/?homeId=$tempHouseCode');
    } else {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/users/?homeId=$tempHouseCode');
    }

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      var usersHouseRes = json.decode(response.body);
      for (var user in usersHouseRes) {
        tempHouseUsers.add(user['name']);
      }
    } else {
      print(response.statusCode);
    }
    if (kIsWeb) {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/house/gethouse/$tempHouseCode');
    } else {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/house/gethouse/$tempHouseCode');
    }
    response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      var house = json.decode(response.body);
      if (userId == house[0]['owner']) {
        tempIsHouseOwner = true;
      }
    } else {
      print(response.statusCode);
    }
    setState(() {
      houseCode = tempHouseCode;
      houseUsers = tempHouseUsers;
      isHouseOwner = tempIsHouseOwner;
    });
  }

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'User Profile',
                  style: TextStyle(fontSize: 28),
                ),
                Form(
                  key: _signupformKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: userName,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(fontSize: 22),
                        ),
                        readOnly: true,
                        style: TextStyle(fontSize: 22),
                      ),
                      TextFormField(
                        initialValue: userEmail,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(fontSize: 22),
                        ),
                        validator: emailValidator,
                        onChanged: (value) {
                          setState(() {
                            userEmail = value;
                          });
                        },
                        style: TextStyle(fontSize: 22),
                      ),
                      TextFormField(
                        initialValue: houseCode,
                        decoration: InputDecoration(
                          labelText: 'House',
                          labelStyle: TextStyle(fontSize: 22),
                        ),
                        readOnly: true,
                        style: TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_signupformKey.currentState!.validate()) {
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? token = await prefs.getString('token');
                          token = token!.substring(1, token.length - 1);

                          var url;
                          if (kIsWeb) {
                            url = Uri.parse(
                                'https://servidor-ssw.onrender.com/users/updateuser/$userId');
                          } else {
                            url = Uri.parse(
                                'https://servidor-ssw.onrender.com/users/updateuser/$userId');
                          }

                          var response = await http.put(
                            url,
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({'email': userEmail}),
                          );

                          if (response.statusCode == 200) {
                            print('Email updated successfully');
                          } else {
                            print(
                                'Failed to update email: ${response.statusCode}');
                          }

                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(fontSize: 22, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight + 20),
          child: Container(
            margin: EdgeInsets.only(top: 15),
            child: AppBar(
              title: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                searchedItem = _searchController.text;
                                if (searchedItem == "") {
                                  setState(() {});
                                }
                              },
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search items',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () async {
                              final SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              String? token = await prefs.getString('token');
                              token = token!.substring(1, token.length - 1);
                              var url;
                              if (tabIndex == 0) {
                                if (kIsWeb) {
                                  url = Uri.parse(
                                      'https://servidor-ssw.onrender.com/house/searchitenspantry/${_searchController.text}');
                                } else {
                                  url = Uri.parse(
                                      'https://servidor-ssw.onrender.com/house/searchitenspantry/${_searchController.text}');
                                }
                              } else {
                                if (kIsWeb) {
                                  url = Uri.parse(
                                      'https://servidor-ssw.onrender.com/house/searchitensbuylist/${_searchController.text}');
                                } else {
                                  url = Uri.parse(
                                      'https://servidor-ssw.onrender.com/house/searchitensbuylist/${_searchController.text}');
                                }
                              }
                              var response = await http.get(
                                url,
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                              );

                              if (response.statusCode == 200) {
                                var searchResponse = json.decode(response.body);
                                print(searchResponse[0]['_id']);
                                setState(() {
                                  searchedItem = searchResponse[0]['_id'];
                                });
                              } else {
                                setState(() {
                                  searchedItem = "";
                                });
                                print(response.statusCode);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.account_circle),
                    onPressed: () async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      String? token = await prefs.getString('token');
                      token = token!.substring(1, token.length - 1);
                      Map<String, dynamic> decodedToken = parseJwt(token);
                      userName = decodedToken['data']['name'];
                      ;
                      houseCode = decodedToken['data']['homeId'];
                      ;
                      userId = decodedToken['data']['userId'];
                      var url;
                      if (kIsWeb) {
                        url = Uri.parse(
                            'https://servidor-ssw.onrender.com/users/$userId');
                      } else {
                        url = Uri.parse(
                            'https://servidor-ssw.onrender.com/users/$userId');
                      }
                      var response = await http.get(
                        url,
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                      );

                      if (response.statusCode == 200) {
                        var userResponse = json.decode(response.body);
                        user = userResponse[0];
                      } else {
                        print(response.statusCode);
                      }

                      userEmail = user['email'];
                      _showProfileModal(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        onDrawerChanged: (isOpened) {
          if (isOpened) {
            getHouseInfo();
          }
        },
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      houseCode,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: 'Menu Title'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Title copied to clipboard')),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < houseUsers.length; i++)
                ListTile(
                  title: Text(houseUsers[i]),
                  trailing: isHouseOwner && i != 0
                      ? IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            var url;
                            if (kIsWeb) {
                              url = Uri.parse(
                                  'https://servidor-ssw.onrender.com/users/?homeId=$houseCode');
                            } else {
                              url = Uri.parse(
                                  'https://servidor-ssw.onrender.com/users/?homeId=$houseCode');
                            }

                            final SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            String? token = await prefs.getString('token');
                            token = token!.substring(1, token.length - 1);

                            var response = await http.get(url, headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            });
                            if (response.statusCode == 200) {
                              var houseDecoded = json.decode(response.body);
                              var url;
                              if (kIsWeb) {
                                url = Uri.parse(
                                    'https://servidor-ssw.onrender.com/users/deleteuseradmin/${houseDecoded[i]['_id']}');
                              } else {
                                url = Uri.parse(
                                    'https://servidor-ssw.onrender.com/users/deleteuseradmin/${houseDecoded[i]['_id']}');
                              }
                              final SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              String? token = await prefs.getString('token');
                              token = token!.substring(1, token.length - 1);

                              response = await http.put(url, headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json',
                              });
                              if (response.statusCode == 200) {
                                setState(() {});
                              } else {
                                print(response.statusCode);
                              }
                            } else {
                              print(response.statusCode);
                            }
                            setState(() {});
                          },
                        )
                      : null,
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.remove('token');
                      context.go('/main.dart');
                    },
                    child: Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: [
                  Pantry(),
                  ShopList(),
                ],
              ),
            ),
            Container(
              color: Colors.grey,
              height: 55,
              child: TabBar(
                controller: _controller,
                tabs: listTabs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Pantry extends StatefulWidget {
  const Pantry({super.key});
  @override
  State<Pantry> createState() => _PantryState();
}

class _PantryState extends State<Pantry> {
  final nameController = TextEditingController();
  final weightController = TextEditingController();

  final ValueNotifier<int> q = ValueNotifier<int>(0);

  late Future<List<Product>> pantryFuture;
  @override
  void initState() {
    super.initState();
    pantryFuture = fetchPantryItem();
  }

  refresh() {
    setState(() {});
  }

  Future<List<Product>> fetchPantryItem() async {
    var url;
    if (kIsWeb) {
      url = Uri.parse('https://servidor-ssw.onrender.com/house/pantryitems');
    } else {
      url = Uri.parse('https://servidor-ssw.onrender.com/house/pantryitems');
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = await prefs.getString('token');
    token = token!.substring(1, token.length - 1);

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      List<Product> products = jsonList
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    } else {
      throw Exception('Failed to load pantry items');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder<List<Product>>(
          future: fetchPantryItem(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              List<Product> products = snapshot.data!;

              List<Product> filteredProducts = searchedItem.isEmpty
                  ? products
                  : products
                      .where((product) => product.id == searchedItem)
                      .toList();

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, i) {
                        String? cleanedBase64String =
                            filteredProducts[i].picUrl?.split(',').last;
                        cleanedBase64String = cleanedBase64String!
                            .replaceAll(RegExp(r'\s'), '')
                            .replaceAll('&#x2F;', '/')
                            .replaceAll('&#x3D;', '=')
                            .replaceAll('&#x2B;', '+');
                        final decodedBytes = base64Decode(cleanedBase64String);
                        final productItem = ProductItem(
                          product: filteredProducts[i],
                          decodedBytes: decodedBytes,
                          callback: refresh,
                        );
                        if (searchedItem.isNotEmpty) {
                          filteredProducts = products;
                        }
                        return productItem;
                      },
                    ),
                  ),
                ],
              );
            } else {
              return Center(child: Text('No data'));
            }
          },
        ),
        floatingActionButton: AddContainers(q: q, callback: refresh));
  }
}

class ProductItemShopList extends StatefulWidget {
  final Product product;
  final Uint8List decodedBytes;
  final VoidCallback callback;
  final ValueNotifier<bool> buttonNotifier;

  ProductItemShopList(
      {required this.product,
      required this.decodedBytes,
      required this.callback,
      required this.buttonNotifier});

  @override
  _ProductItemShopList createState() => _ProductItemShopList();
}

class _ProductItemShopList extends State<ProductItemShopList> {
  int quantity = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Image.memory(
              widget.decodedBytes,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.product.weight.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _incrementQuantity(widget.buttonNotifier);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.all(8.0),
                  backgroundColor: const Color.fromARGB(255, 112, 223, 115),
                  minimumSize: Size(40, 40),
                  maximumSize: Size(40, 40),
                ),
                child: Icon(Icons.add, color: Colors.black),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'X ${quantity + widget.product.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 17, 17, 17),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _decrementQuantity(widget.buttonNotifier);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.all(8.0),
                  backgroundColor: Colors.red,
                  minimumSize: Size(40, 40),
                  maximumSize: Size(40, 40),
                ),
                child: Icon(Icons.remove, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _incrementQuantity(buttonNotifier) async {
    setState(() {
      widget.product.quantity++;
    });
    var url;
    if (kIsWeb) {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/house/editBuyListItem/${widget.product.id}');
    } else {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/house/editBuyListItem/${widget.product.id}');
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = await prefs.getString('token');
    token = token!.substring(1, token.length - 1);

    var response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'quantity': widget.product.quantity,
      }),
    );
    if (response.statusCode == 200 && response.body == "Item updated") {
      String? produtoImg = widget.product.picUrl?.split(',').last;
      produtoImg = produtoImg!
          .replaceAll(RegExp(r'\s'), '')
          .replaceAll('&#x2F;', '/')
          .replaceAll('&#x3D;', '=')
          .replaceAll('&#x2B;', '+');
      if (widget.product.quantity == 1) {
        widget.product.picUrl = produtoImg;
        itemsCarro.add(widget.product);
        buttonNotifier.value = itemsCarro.isNotEmpty;
      } else if (widget.product.quantity > 1) {
        updateProductQuantity(
            itemsCarro, widget.product.id, widget.product.quantity);
      }
    } else {
      print('Failed to update item: ${response.body}');
    }
  }

  Future<void> _decrementQuantity(buttonNotifier) async {
    if (widget.product.quantity > 0) {
      setState(() {
        widget.product.quantity--;
      });
      var url;
      if (kIsWeb) {
        url = Uri.parse(
            'https://servidor-ssw.onrender.com/house/editBuyListItem/${widget.product.id}');
      } else {
        url = Uri.parse(
            'https://servidor-ssw.onrender.com/house/editBuyListItem/${widget.product.id}');
      }
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = await prefs.getString('token');
      token = token!.substring(1, token.length - 1);

      var response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quantity': widget.product.quantity,
        }),
      );

      if (response.statusCode == 200 && response.body == "Item updated") {
        if (widget.product.quantity == 0) {
          removeProductById(itemsCarro, widget.product.id);
          buttonNotifier.value = itemsCarro.isNotEmpty;
        }
      } else {
        print('Failed to update item: ${response.statusCode}');
      }
    }
  }
}

class ProductItem extends StatefulWidget {
  final Product product;
  final Uint8List decodedBytes;
  final VoidCallback callback;

  ProductItem(
      {required this.product,
      required this.decodedBytes,
      required this.callback});

  @override
  _ProductItemState createState() => _ProductItemState();
}

class _ProductItemState extends State<ProductItem> {
  int quantity = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Image.memory(
              widget.decodedBytes,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.product.weight.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _incrementQuantity();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.all(8.0),
                  backgroundColor: const Color.fromARGB(255, 112, 223, 115),
                  minimumSize: Size(40, 40),
                  maximumSize: Size(40, 40),
                ),
                child: Icon(Icons.add, color: Colors.black),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'X ${quantity + widget.product.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _decrementQuantity();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.all(8.0),
                  backgroundColor: Colors.red,
                  minimumSize: Size(40, 40),
                  maximumSize: Size(40, 40),
                ),
                child: Icon(Icons.remove, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _incrementQuantity() async {
    setState(() {
      quantity++;
    });
    var url;
    if (kIsWeb) {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/house/editPantryItem/${widget.product.id}');
    } else {
      url = Uri.parse(
          'https://servidor-ssw.onrender.com/house/editPantryItem/${widget.product.id}');
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = await prefs.getString('token');
    token = token!.substring(1, token.length - 1);

    var response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'quantity': quantity + widget.product.quantity,
      }),
    );
    if (response.statusCode == 200 && response.body == "Item updated") {
      print(response.body);
    } else {
      print('Failed to update item: ${response.body}');
    }
  }

  Future<void> _decrementQuantity() async {
    setState(() {
      quantity--;
    });
    if ((quantity + widget.product.quantity) > 0) {
      var url;
      if (kIsWeb) {
        url = Uri.parse(
            'https://servidor-ssw.onrender.com/house/editpantryitem/${widget.product.id}');
      } else {
        url = Uri.parse(
            'https://servidor-ssw.onrender.com/house/editpantryitem/${widget.product.id}');
      }
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = await prefs.getString('token');
      token = token!.substring(1, token.length - 1);

      var response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quantity': quantity + widget.product.quantity,
        }),
      );

      if (response.statusCode == 200 && response.body == "Item updated") {
        print(response.body);
      } else {
        print('Failed to update item: ${response.statusCode}');
      }
    } else {
      var url;
      if (kIsWeb) {
        url = Uri.parse(
            'https://servidor-ssw.onrender.com/house/excludepantryitem/${widget.product.id}');
      } else {
        url = Uri.parse(
            'https://servidor-ssw.onrender.com/house/excludepantryitem/${widget.product.id}');
      }
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = await prefs.getString('token');
      token = token!.substring(1, token.length - 1);

      var response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
      } else {
        print(response.statusCode);
      }

      String? cleanedBase64String = widget.product.picUrl?.split(',').last;
      cleanedBase64String = cleanedBase64String!
          .replaceAll(RegExp(r'\s'), '')
          .replaceAll('&#x2F;', '/')
          .replaceAll('&#x3D;', '=')
          .replaceAll('&#x2B;', '+');

      addBuyListItem(widget.product.name, widget.product.brand, 0,
          cleanedBase64String, widget.product.weight);
      widget.callback();
    }
  }
}

class ShopList extends StatefulWidget {
  const ShopList({super.key});
  @override
  State<ShopList> createState() => _ShopList();
}

class _ShopList extends State<ShopList> {
  final nameController = TextEditingController();
  final weightController = TextEditingController();
  late ValueNotifier<bool> isCartButtonEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<int> q = ValueNotifier<int>(0);
  late Future<List<Product>> pantryFuture;

  @override
  void initState() {
    super.initState();
    pantryFuture = fetchBuyListItem();
    if (itemsCarro.isNotEmpty) {
      isCartButtonEnabled = ValueNotifier<bool>(true);
    }
  }

  refresh() {
    setState(() {});
  }

  Future<List<Product>> fetchBuyListItem() async {
    var url;
    if (kIsWeb) {
      url = Uri.parse('https://servidor-ssw.onrender.com/house/buylistitems');
    } else {
      url = Uri.parse('https://servidor-ssw.onrender.com/house/buylistitems');
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = await prefs.getString('token');
    token = token!.substring(1, token.length - 1);

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      List<Product> products = jsonList
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    } else {
      throw Exception('Failed to load pantry items');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Product>>(
        future: fetchBuyListItem(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            List<Product> products = snapshot.data!;

            List<Product> filteredProducts = searchedItem.isEmpty
                ? products
                : products
                    .where((product) => product.id == searchedItem)
                    .toList();

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, i) {
                      String? cleanedBase64String =
                          filteredProducts[i].picUrl?.split(',').last;
                      cleanedBase64String = cleanedBase64String!
                          .replaceAll(RegExp(r'\s'), '')
                          .replaceAll('&#x2F;', '/')
                          .replaceAll('&#x3D;', '=')
                          .replaceAll('&#x2B;', '+');
                      final decodedBytes = base64Decode(cleanedBase64String);
                      final productItem = ProductItemShopList(
                        product: filteredProducts[i],
                        decodedBytes: decodedBytes,
                        callback: refresh,
                        buttonNotifier: isCartButtonEnabled,
                      );
                      if (searchedItem.isNotEmpty) {
                        filteredProducts = products;
                      }

                      return productItem;
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No data'));
          }
        },
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: AddContainers(q: q, callback: refresh),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0, left: 40),
              child: ValueListenableBuilder<bool>(
                valueListenable: isCartButtonEnabled,
                builder: (context, isEnabled, child) {
                  return FloatingActionButton(
                    onPressed: isEnabled
                        ? () async {
                            for (var item in itemsCarro) {
                              String? cleanedBase64String =
                                  item.picUrl?.split(',').last;
                              cleanedBase64String = cleanedBase64String!
                                  .replaceAll(RegExp(r'\s'), '')
                                  .replaceAll('&#x2F;', '/')
                                  .replaceAll('&#x3D;', '=')
                                  .replaceAll('&#x2B;', '+');
                              var url;
                              if (kIsWeb) {
                                url = Uri.parse(
                                    'https://servidor-ssw.onrender.com/house/createpantryitem');
                              } else {
                                url = Uri.parse(
                                    'https://servidor-ssw.onrender.com/house/createpantryitem');
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
                                body: jsonEncode({
                                  'name': item.name,
                                  'brand': item.brand,
                                  'quantity': item.quantity,
                                  'picUrl': cleanedBase64String,
                                  'weight': item.weight,
                                }),
                              );

                              if (response.statusCode == 200) {
                              } else {
                                print(
                                    'failed to add item ${response.statusCode}');
                              }

                              if (kIsWeb) {
                                url = Uri.parse(
                                    'https://servidor-ssw.onrender.com/house/excludeBuyListItem/${item.id}');
                              } else {
                                url = Uri.parse(
                                    'https://servidor-ssw.onrender.com/house/excludeBuyListItem/${item.id}');
                              }

                              response = await http.delete(
                                url,
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                              );

                              if (response.statusCode == 200) {
                                setState(() {
                                  itemsCarro = [];
                                  isCartButtonEnabled =
                                      ValueNotifier<bool>(false);
                                });
                              } else {
                                print(response.statusCode);
                              }
                            }
                          }
                        : null,
                    backgroundColor:
                        isEnabled ? Colors.lightGreenAccent : Colors.grey,
                    child:
                        Icon(Icons.shopping_cart_checkout, color: Colors.black),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddContainers extends StatefulWidget {
  @override
  _AddContainersState createState() => _AddContainersState();

  final ValueNotifier<int> q;
  final VoidCallback callback;
  AddContainers({required this.q, required this.callback});
}

class _AddContainersState extends State<AddContainers> {
  String? base64Image;
  final _formKey = GlobalKey<FormState>();
  final imageController = TextEditingController();
  final marcaController = TextEditingController();
  final nameController = TextEditingController();
  final quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
        shape: CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 0, 0, 0),
          size: 40,
        ),
        onPressed: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      right: -40,
                      top: -40,
                      child: InkResponse(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            height: 80,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: FormBuilderImagePicker(
                                name: 'photos',
                                decoration: const InputDecoration(
                                  labelText: 'Picture',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 10),
                                ),
                                maxImages: 1,
                                onChanged: (images) async {
                                  if (images != null && images.isNotEmpty) {
                                    XFile xfile = images.first;
                                    if (kIsWeb) {
                                      // For web
                                      html.FileReader reader =
                                          html.FileReader();
                                      reader.readAsDataUrl(html.Blob(
                                          [await xfile.readAsBytes()]));
                                      reader.onLoadEnd.listen((event) {
                                        base64Image = reader.result as String;
                                      });
                                    } else {
                                      // For mobile
                                      File imageFile = File(xfile.path);
                                      List<int> imageBytes =
                                          await imageFile.readAsBytes();
                                      base64Image = base64Encode(imageBytes);
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Product Name',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextFormField(
                              controller: marcaController,
                              decoration: InputDecoration(
                                labelText: 'Product Brand',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              controller: quantityController,
                              decoration: InputDecoration(
                                labelText: 'Weight',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: ElevatedButton(
                              // ignore: sort_child_properties_last
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  final num? quantityNum =
                                      num.tryParse(quantityController.text);
                                  final produto = Produto(
                                      base64Image!,
                                      nameController.text,
                                      marcaController.text,
                                      quantityNum!);
                                  if (tabIndex == 0) {
                                    produtosDespensa.add(produto);
                                    await addPantryItem(
                                        produto.name,
                                        produto.brand,
                                        1,
                                        produto.picture,
                                        produto.weight);
                                  } else if (tabIndex == 1) {
                                    produtosCompra.add(produto);
                                    await addBuyListItem(
                                        produto.name,
                                        produto.brand,
                                        0,
                                        produto.picture,
                                        produto.weight);
                                  }
                                  widget.callback();
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightGreen,
                                  minimumSize: Size(200, 50)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

void updateProductQuantity(List<Product> products, String id, int newQuantity) {
  for (var product in products) {
    if (product.id == id) {
      product.quantity = newQuantity;
      break;
    }
  }
}

void removeProductById(List<Product> products, String id) {
  products.removeWhere((product) => product.id == id);
}
