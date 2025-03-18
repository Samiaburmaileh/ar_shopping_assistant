import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('featured', isEqualTo: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList();
    } catch (e) {
      throw Exception('Failed to load featured products: ${e.toString()}');
    }
  }

  Future<List<Product>> getRecommendedProducts() async {
    try {
      // In a real app, this would use a recommendation algorithm
      // For now, just return some random products
      final querySnapshot = await _firestore
          .collection('products')
          .limit(6)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList();
    } catch (e) {
      throw Exception('Failed to load recommended products: ${e.toString()}');
    }
  }

  Future<List<Product>> getRecentlyViewedProducts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('productViews')
          .orderBy('viewedAt', descending: true)
          .limit(10)
          .get();

      final productIds = querySnapshot.docs.map((doc) => doc.id).toList();

      if (productIds.isEmpty) {
        return [];
      }

      // Firestore doesn't support direct "where in" for large arrays
      // so we need to batch the queries if we have many IDs
      const batchSize = 10;
      final products = <Product>[];

      for (var i = 0; i < productIds.length; i += batchSize) {
        final endIndex = (i + batchSize < productIds.length) ? i + batchSize : productIds.length;
        final batch = productIds.sublist(i, endIndex);

        final batchResults = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        products.addAll(batchResults.docs.map((doc) => Product.fromMap({
          'id': doc.id,
          ...doc.data(),
        })));
      }

      // Re-sort according to view history
      products.sort((a, b) =>
          productIds.indexOf(a.id).compareTo(productIds.indexOf(b.id)));

      return products;
    } catch (e) {
      throw Exception('Failed to load recently viewed products: ${e.toString()}');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      // For a real app, you'd use a proper search solution like Algolia
      // This is a simple implementation for demonstration
      final querySnapshot = await _firestore
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: ${e.toString()}');
    }
  }

  Future<void> recordProductView(Product product) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return;
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('productViews')
          .doc(product.id)
          .set({
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log but don't throw
      print('Failed to record product view: ${e.toString()}');
    }
  }
}