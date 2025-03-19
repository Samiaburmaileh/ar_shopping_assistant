import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart' as app;
import '../models/product_model.dart';
import '../models/shopping_list_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User methods
  Future<app.User?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return null;
      }

      return app.User.fromMap({
        'id': userDoc.id,
        ...userDoc.data()!,
      });
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  Future<void> updateUser(app.User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'preferences': preferences,
      });
    } catch (e) {
      throw Exception('Failed to update user preferences: ${e.toString()}');
    }
  }

  // Product methods
  Future<List<Product>> getFavoriteProducts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      // Get user to retrieve favorite item IDs
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return [];
      }

      final user = app.User.fromMap({
        'id': userDoc.id,
        ...userDoc.data()!,
      });

      if (user.favoriteItems.isEmpty) {
        return [];
      }

      // Fetch products by IDs
      const batchSize = 10;
      final products = <Product>[];

      for (var i = 0; i < user.favoriteItems.length; i += batchSize) {
        final endIndex = (i + batchSize < user.favoriteItems.length) ? i + batchSize : user.favoriteItems.length;
        final batch = user.favoriteItems.sublist(i, endIndex);

        final batchResults = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        products.addAll(batchResults.docs.map((doc) => Product.fromMap({
          'id': doc.id,
          ...doc.data(),
        })));
      }

      return products;
    } catch (e) {
      throw Exception('Failed to get favorite products: ${e.toString()}');
    }
  }

  Future<void> toggleFavoriteProduct(String productId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userRef = _firestore.collection('users').doc(currentUser.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final user = app.User.fromMap({
        'id': userDoc.id,
        ...userDoc.data()!,
      });

      // Check if product is already a favorite
      final favorites = List<String>.from(user.favoriteItems);
      if (favorites.contains(productId)) {
        // Remove from favorites
        favorites.remove(productId);
      } else {
        // Add to favorites
        favorites.add(productId);
      }

      // Update user document
      await userRef.update({
        'favoriteItems': favorites,
      });
    } catch (e) {
      throw Exception('Failed to toggle favorite product: ${e.toString()}');
    }
  }

  Future<bool> isProductFavorite(String productId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return false;
      }

      final user = app.User.fromMap({
        'id': userDoc.id,
        ...userDoc.data()!,
      });

      return user.favoriteItems.contains(productId);
    } catch (e) {
      return false;
    }
  }

  // Analytics methods
  Future<void> trackEvent(String eventName, Map<String, dynamic> params) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return;
      }

      await _firestore
          .collection('analytics')
          .doc(currentUser.uid)
          .collection('events')
          .add({
        'eventName': eventName,
        'params': params,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log but don't throw
      print('Failed to track event: ${e.toString()}');
    }
  }
}