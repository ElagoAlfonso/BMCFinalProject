import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/screens/admin_panel_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_ecommerce_app/widgets/product_card.dart';
import 'package:my_ecommerce_app/screens/product_detail_screen.dart';
import 'package:my_ecommerce_app/providers/cart_provider.dart';
import 'package:my_ecommerce_app/screens/cart_screen.dart';
import 'package:my_ecommerce_app/screens/order_history_screen.dart';
import 'package:provider/provider.dart';




class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
  class _HomeScreenState extends State <HomeScreen>{

    String _userRole = 'user';
    final User? _currentUser = FirebaseAuth.instance.currentUser;
    @override
    void initState() {
      super.initState();
      _fetchUserRole();
    }
    Future<void> _fetchUserRole() async {
      if (_currentUser == null) return;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          setState(() {
            _userRole = doc.data()!['role'];
          });
        }
      } catch (e) {
        print("Error fetching user role: $e");
      }
    }
    Future<void> _signOut() async {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        print('Error signing out: $e');
      }
    }

    @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser != null ? 'Welcome, ${_currentUser!.displayName}' : 'Home'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Badge(
                label: Text(cart.itemCount.toString()),
                isLabelVisible: cart.itemCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long), // A "receipt" icon
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),

          if(_userRole == 'admin')
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Panel',
            onPressed: ()  {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true) // 3. Show newest first
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }

          final products = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(10.0),

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),

            itemCount: products.length,
            itemBuilder: (context, index) {
              // 1. Get the whole document
              final productDoc = products[index];
              // 2. Get the data map
              final productData = productDoc.data() as Map<String, dynamic>;

              // 3. Find your old ProductCard
              return ProductCard(
                productName: productData['name'],
                price: productData['price'],
                imageUrl: productData['imageUrl'],

                // 4. --- THIS IS THE NEW PART ---
                //    Add the onTap property
                onTap: () {
                  // 5. Navigate to the new screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        // 6. Pass the data to the new screen
                        productData: productData,
                        productId: productDoc.id, // 7. Pass the unique ID!
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}



