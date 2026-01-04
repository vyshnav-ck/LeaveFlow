// import 'package:provider/provider.dart';
// import 'providers/counter_provider.dart';
// import 'package:flutter/material.dart';
// import 'profile_screen.dart';
// import 'main_nav.dart';
// import 'apply_leave_screen.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart';
// import 'leave_list_screen.dart';
// import 'providers/leave_provider.dart';
// import 'package:firebase_core/firebase_core.dart';


// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   runApp(
//   MultiProvider(
//     providers: [
//       ChangeNotifierProvider(create: (_) => CounterProvider()),
//       ChangeNotifierProvider(create: (_) => LeaveProvider()),
//     ],
//     child: MyApp(),
//   ),
// );
// }

// class Product {
//   final String name;
//   final double price;
//   final int quantity;
//   Product({required this.name, required this.price, required this.quantity});

//   @override
//   String toString() =>
//       'Product(name: $name, price: $price, quantity: $quantity)';
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Products Demo',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       home: MainNav(),
//     );
//   }
// }

// class ProductsHome extends StatefulWidget {
//   const ProductsHome({super.key});

//   @override
//   State<ProductsHome> createState() => _ProductsHomeState();
// }

// class _ProductsHomeState extends State<ProductsHome> {

//   // initial sample data
//   final List<Product> _allProducts = [
//     Product(name: 'Scooter EV', price: 55_000, quantity: 1),
//     Product(name: 'ASUS TUF Laptop', price: 65_000, quantity: 1),
//     Product(name: 'Wireless Headphones', price: 2_500, quantity: 2),
//     Product(name: 'Smartwatch', price: 7_999, quantity: 1),
//   ];

//   // what we show: filtered by search
//   List<Product> _visibleProducts = [];
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _visibleProducts = List<Product>.from(_allProducts);
//     _searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     final q = _searchController.text.trim().toLowerCase();
//     setState(() {
//       if (q.isEmpty) {
//         _visibleProducts = List<Product>.from(_allProducts);
//       } else {
//         _visibleProducts = _allProducts
//             .where((p) => p.name.toLowerCase().contains(q))
//             .toList();
//       }
//     });
//   }

//   // add a product from dialog
//   Future<void> _showAddProductDialog() async {
//     final nameController = TextEditingController();
//     final priceController = TextEditingController();
//     final qtyController = TextEditingController();

//     final result = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Add Product'),
//           content: SingleChildScrollView(
//             child: Column(
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(labelText: 'Name'),
//                 ),
//                 TextField(
//                   controller: priceController,
//                   decoration: const InputDecoration(labelText: 'Price (₹)'),
//                   keyboardType:
//                       const TextInputType.numberWithOptions(decimal: true),
//                 ),
//                 TextField(
//                   controller: qtyController,
//                   decoration: const InputDecoration(labelText: 'Quantity'),
//                   keyboardType: TextInputType.number,
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('Cancel')),
//             ElevatedButton(
//                 onPressed: () {
//                   // Basic validation
//                   if (nameController.text.trim().isEmpty ||
//                       priceController.text.trim().isEmpty ||
//                       qtyController.text.trim().isEmpty) {
//                     // keep dialog open, show a quick error
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                         content: Text('Please fill all fields')));
//                     return;
//                   }
//                   Navigator.of(context).pop(true);
//                 },
//                 child: const Text('Add')),

//           ],
//         );
//       },
//     );

//     if (result == true) {
//       final name = nameController.text.trim();
//       final price = double.tryParse(priceController.text.trim()) ?? 0.0;
//       final qty = int.tryParse(qtyController.text.trim()) ?? 1;

//       final newProduct =
//           Product(name: name, price: price, quantity: qty);

//       setState(() {
//         _allProducts.insert(0, newProduct);
//         _onSearchChanged(); // update visible list respecting search
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Added: ${newProduct.name}')));
//     }
//   }

//   // delete with confirmation via snackbar undo
//   void _deleteProduct(int index, Product product) {
//     setState(() {
//       _allProducts.remove(product);
//       _onSearchChanged();
//     });
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Deleted ${product.name}'),
//         action: SnackBarAction(
//             label: 'UNDO',
//             onPressed: () {
//               setState(() {
//                 _allProducts.insert(index, product);
//                 _onSearchChanged();
//               });
//             }),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Products'),
//         centerTitle: false,
//         actions: [
//           IconButton(
//             onPressed: () {
//               _searchController.clear();
//               FocusScope.of(context).unfocus();
//             },
//             icon: const Icon(Icons.clear),
//             tooltip: 'Clear search',
//           ),
//           ElevatedButton(
//   onPressed: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => ProfileScreen()),
//     );
//   },
//   child: Text("Go to Profile Screen"),
// ),

//         ],
//       ),

//       body: Column(
//         children: [
//           // Search bar
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search products...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 isDense: true,
//               ),
//             ),
//           ),

//           // Info / empty state
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               children: [
//                 Text(
//                   '${_visibleProducts.length} items',
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 const Spacer(),
//                 Text(
//                   'Total products: ${_allProducts.length}',
//                   style: const TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 8),

//           // List
//           Expanded(
//             child: _visibleProducts.isEmpty
//                 ? const Center(
//                     child: Text('No products found. Try adding some!'),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     itemCount: _visibleProducts.length,
//                     itemBuilder: (context, i) {
//                       final product = _visibleProducts[i];
//                       final originalIndex = _allProducts.indexOf(product);

//                       return Dismissible(
//                         key: ValueKey(product.hashCode),
//                         direction: DismissDirection.endToStart,
//                         background: Container(
//                           alignment: Alignment.centerRight,
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           decoration: BoxDecoration(
//                               color: Colors.red,
//                               borderRadius: BorderRadius.circular(12)),
//                           child: const Icon(Icons.delete, color: Colors.white),
//                         ),
//                         onDismissed: (_) => _deleteProduct(originalIndex, product),
//                         child: ProductCard(
//                           product: product,
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (_) => ProductDetail(product: product)),
//                             );
//                           },
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
      
//       floatingActionButton: SpeedDial(
//   icon: Icons.add,
//   activeIcon: Icons.close,
//   backgroundColor: Colors.blue,
//   children: [
//     SpeedDialChild(
//       child: Icon(Icons.edit_calendar),
//       label: "Apply Leave",
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => ApplyLeaveScreen()),
//         );
//       },
//     ),
//     SpeedDialChild(
//       child: Icon(Icons.add),
//       label: "Add Product",
//       onTap: () {
//         // your product add code here
//       },
//     ),
//     SpeedDialChild(
//   child: Icon(Icons.list_alt),
//   label: "Leave List",
//   onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => LeaveListScreen()),
//     );
//   },
// ),

//   ],
// ),

      

//     );
//   }
// }

// /// Small reusable Product card widget
// class ProductCard extends StatelessWidget {
//   final Product product;
//   final VoidCallback? onTap;
//   const ProductCard({super.key, required this.product, this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             children: [
//               // Hero avatar for nice transition
//               Hero(
//                 tag: 'product-${product.name}',
//                 child: Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade100,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Center(
//                     child: Text(
//                       product.name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join(),
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               // Info
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(product.name,
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                     const SizedBox(height: 6),
//                     Text('Qty: ${product.quantity} • ₹${product.price.toStringAsFixed(0)}',
//                         style: const TextStyle(color: Colors.black54)),
//                   ],
//                 ),
//               ),

//               IconButton(
//                 onPressed: () {
//                   // quick action: show details
//                   if (onTap != null) onTap!();
//                 },
//                 icon: const Icon(Icons.arrow_forward_ios, size: 18),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class ProductDetail extends StatelessWidget {
//   final Product product;
//   const ProductDetail({super.key, required this.product});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(product.name),
//       ),

//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           // center content
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Hero(
//               tag: 'product-${product.name}',
//               child: Container(
//                 width: 120,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade100,
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//                 child: Center(
//                   child: Text(
//                     product.name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join(),
//                     style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
//             const SizedBox(height: 8),
//             Text('Price: ₹${product.price.toStringAsFixed(0)}',
//                 style: const TextStyle(fontSize: 18)),
//             const SizedBox(height: 6),
//             Text('Available: ${product.quantity}', style: const TextStyle(fontSize: 16)),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Checked ${product.name}')),
//                 );
//               },
//               icon: const Icon(Icons.check),
//               label: const Text('Check Product'),
//             ),

//           ],
//         ),
//       ),
//     );
//   }
// }
