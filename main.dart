import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase optional for offline
  }
  runApp(const ApnaMarketApp());
}

class ApnaMarketApp extends StatelessWidget {
  const ApnaMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.green);
    return MaterialApp(
      title: 'Apna Market',
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent.withOpacity(.1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.orangeAccent.withOpacity(.3),
                    child: const Icon(Icons.storefront, size: 32, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  const Text("Welcome to Apna Market", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Phone or Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password (placeholder)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                  },
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: (){},
                  child: const Text("Use OTP (Firebase-ready placeholder)"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Product {
  final int id;
  final String title;
  final int price;
  final String desc;
  Product({required this.id, required this.title, required this.price, required this.desc});
  factory Product.fromJson(Map<String, dynamic> j) =>
      Product(id: j['id'], title: j['title'], price: j['price'], desc: j['desc'] ?? '');
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> products = [];
  final Map<int, int> cart = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txt = await rootBundle.loadString('assets/products.json');
    final data = (json.decode(txt) as List).map((e) => Product.fromJson(e)).toList();
    setState(() => products = data);
  }

  int get total => cart.entries.fold(0, (sum, e) {
    final p = products.firstWhere((x) => x.id == e.key);
    return sum + p.price * e.value;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apna Market'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Stack(alignment: Alignment.topRight, children: [
            IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => _openCart(context)),
            if (cart.isNotEmpty)
              CircleAvatar(
                radius: 10, backgroundColor: Colors.orange,
                child: Text("${cart.values.fold(0, (a, b) => a + b)}", style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
          ]),
        ],
      ),
      body: products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(.15),
                      child: const Icon(Icons.local_mall, color: Colors.orange),
                    ),
                    title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(p.desc),
                    trailing: Column(
                      mainAxisAlignment: MainAlignment.center,
                      children: [
                        Text("₹${p.price}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(72, 32)),
                          onPressed: () {
                            setState(() => cart[p.id] = (cart[p.id] ?? 0) + 1);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${p.title} added to cart"), duration: const Duration(milliseconds: 700)));
                          },
                          child: const Text("Add"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCart(context),
        label: Text("Cart • ₹$total"),
        icon: const Icon(Icons.shopping_bag),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final items = cart.entries.toList();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Icon(Icons.shopping_bag, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(child: Text("Your Cart", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Text("₹$total", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text("Cart is empty"))
              else ...[
                for (final e in items) _cartTile(e.key, e.value),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Place Order (Offline Demo)"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44)),
                  onPressed: () {
                    cart.clear();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order placed (offline demo)")));
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _cartTile(int id, int qty) {
    final p = products.firstWhere((x) => x.id == id);
    return ListTile(
      title: Text(p.title),
      subtitle: Text("₹${p.price} x $qty"),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(onPressed: () => setState(() { if ((cart[id] ?? 0) > 0) cart[id] = cart[id]! - 1; if(cart[id]==0) cart.remove(id); }), icon: const Icon(Icons.remove_circle_outline)),
        Text("$qty"),
        IconButton(onPressed: () => setState(() { cart[id] = (cart[id] ?? 0) + 1; }), icon: const Icon(Icons.add_circle)),
      ]),
    );
  }
}
