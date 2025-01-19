import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_builder_image_picker/form_builder_image_picker.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

List<int>? imgForApi;
int tabIndex = 0;

Future addPantryItem(
    String name, String brand, num quantity, String picUrl, num weight) async {
  var url = Uri.parse('http://localhost:3000/house/createpantryitem');
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

Future addBuyListItem(
    String name, String brand, num quantity, String picUrl, num weight) async {
  var url = Uri.parse('http://localhost:3000/house/createbuylistitem');
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
  final int quantity;
  final int weight;
  final int v;
  final String? picUrl;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Login & Signup'),
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
              child: TabBar(
                controller: _controller,
                tabs: listTabs,
              ),
            )
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
    var url = Uri.parse('http://localhost:3000/house/pantryitems');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = await prefs.getString('token');
    token = token!.substring(1, token.length - 1);

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      List<Product> products = jsonList
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
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
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      String? cleanedBase64String =
                          products[i].picUrl?.split(',').last;
                      cleanedBase64String = cleanedBase64String!
                          .replaceAll(RegExp(r'\s'), '')
                          .replaceAll('&#x2F;', '/')
                          .replaceAll('&#x3D;', '=')
                          .replaceAll('&#x2B;', '+');
                      final decodedBytes = base64Decode(cleanedBase64String);
                      return ProductItem(
                        product: products[i],
                        decodedBytes: decodedBytes,
                      );
                    },
                  ),
                ),
                AddContainers(q: q, callback: refresh)
              ],
            );
          } else {
            return Center(child: Text('No data'));
          }
        },
      ),
    );
  }
}

class ProductItemPantry extends StatefulWidget {
  final Product product;
  final Uint8List decodedBytes;

  ProductItemPantry({required this.product, required this.decodedBytes});

  @override
  _ProductItemPantry createState() => _ProductItemPantry();
}

class _ProductItemPantry extends State<ProductItemPantry> {
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
                onPressed: () {
                  setState(() {
                    quantity++;
                  });
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.all(8.0),
                  backgroundColor: Colors.green,
                  minimumSize: Size(40, 40),
                  maximumSize: Size(40, 40),
                ),
                child: Icon(Icons.add, color: Colors.black),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'X $quantity',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (quantity > 0) {
                      quantity--;
                    }
                  });
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
}

class ProductItem extends StatefulWidget {
  final Product product;
  final Uint8List decodedBytes;

  ProductItem({required this.product, required this.decodedBytes});

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
                onPressed: () {
                  setState(() {
                    quantity++;
                  });
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.all(8.0),
                  backgroundColor: Colors.green,
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
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (quantity > 0) {
                      quantity--;
                    }
                  });
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
}

class ShopList extends StatefulWidget {
  const ShopList({super.key});
  @override
  State<ShopList> createState() => _ShopList();
}

class _ShopList extends State<ShopList> {
  final nameController = TextEditingController();
  final weightController = TextEditingController();

  final ValueNotifier<int> q = ValueNotifier<int>(0);

  late Future<List<Product>> pantryFuture;

  @override
  void initState() {
    super.initState();
    pantryFuture = fetchBuyListItem();
  }

  refresh() {
    setState(() {});
  }

  Future<List<Product>> fetchBuyListItem() async {
    var url = Uri.parse('http://localhost:3000/house/buylistitems');
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
      print('Failed to load pantry items');
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
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      String? cleanedBase64String =
                          products[i].picUrl?.split(',').last;
                      cleanedBase64String = cleanedBase64String!
                          .replaceAll(RegExp(r'\s'), '')
                          .replaceAll('&#x2F;', '/')
                          .replaceAll('&#x3D;', '=')
                          .replaceAll('&#x2B;', '+');
                      final decodedBytes = base64Decode(cleanedBase64String);
                      return ProductItem(
                        product: products[i],
                        decodedBytes: decodedBytes,
                      );
                    },
                  ),
                ),
                AddContainers(q: q, callback: refresh)
              ],
            );
          } else {
            return Center(child: Text('No data'));
          }
        },
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
  final weightController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
        onPressed: () async {
          await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                    content: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned(
                          right: -40,
                          top: -40,
                          child: InkResponse(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: const CircleAvatar(
                              backgroundColor: Color.fromARGB(255, 255, 0, 0),
                              child: Icon(Icons.close),
                            ),
                          ),
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: FormBuilderImagePicker(
                                  name: 'photos',
                                  decoration: const InputDecoration(
                                      labelText: 'Pick Photos'),
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
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextFormField(
                                  controller: nameController,
                                  decoration:
                                      InputDecoration(labelText: 'Nome:'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextFormField(
                                  controller: marcaController,
                                  decoration:
                                      InputDecoration(labelText: 'Marca:'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  controller: weightController,
                                  decoration:
                                      InputDecoration(labelText: 'Peso:'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: ElevatedButton(
                                  child: const Text('Submit'),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      final num? weightNum =
                                          num.tryParse(weightController.text);
                                      final produto = Produto(
                                          base64Image!,
                                          nameController.text,
                                          marcaController.text,
                                          weightNum!);
                                      if (tabIndex == 0) {
                                        produtosDespensa.add(produto);
                                        await addPantryItem(
                                            produto.name,
                                            produto.brand,
                                            produto.weight,
                                            produto.picture,
                                            1);
                                      } else if (tabIndex == 1) {
                                        produtosCompra.add(produto);
                                        await addBuyListItem(
                                            produto.name,
                                            produto.brand,
                                            produto.weight,
                                            produto.picture,
                                            0);
                                      }
                                      widget.callback();
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ));
        });
  }
}
