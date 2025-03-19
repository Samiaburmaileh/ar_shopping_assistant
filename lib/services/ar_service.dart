import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ArService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cache for 3D models to avoid repeated downloads
  final Map<String, String> _modelCache = {};

  // Preload common models to improve user experience
  Future<void> preloadCommonModels() async {
    try {
      final featuredProducts = await _firestore
          .collection('products')
          .where('featured', isEqualTo: true)
          .where('modelUrl', isNotEqualTo: '')
          .limit(5)
          .get();

      for (final doc in featuredProducts.docs) {
        final modelUrl = doc.data()['modelUrl'] as String;
        if (modelUrl.isNotEmpty) {
          await _downloadAndCacheModel(modelUrl);
        }
      }
    } catch (e) {
      print('Error preloading models: ${e.toString()}');
      // Don't throw here as this is a background optimization
    }
  }

  // Get the local URL for a model, downloading it if needed
  Future<String> getModelUrl(Product product) async {
    if (product.modelUrl.isEmpty) {
      throw Exception('This product does not have a 3D model available');
    }

    // Check cache first
    if (_modelCache.containsKey(product.id)) {
      return _modelCache[product.id]!;
    }

    // Download and cache the model
    final localUrl = await _downloadAndCacheModel(product.modelUrl);

    // Record model view in analytics
    _recordModelView(product.id);

    return localUrl;
  }

  Future<String> _downloadAndCacheModel(String modelUrl) async {
    try {
      final response = await http.get(Uri.parse(modelUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download model: HTTP ${response.statusCode}');
      }

      // Get app's temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = modelUrl.split('/').last;
      final filePath = '${tempDir.path}/$fileName';

      // Save the model to local storage
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Add to cache
      final modelId = fileName.split('.').first;
      _modelCache[modelId] = filePath;

      return filePath;
    } catch (e) {
      throw Exception('Failed to download model: ${e.toString()}');
    }
  }

  Future<void> saveMeasurement({
    required double distance,
    required String productId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('measurements')
          .add({
        'productId': productId,
        'distance': distance,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save measurement: ${e.toString()}');
    }
  }

  Future<String> saveScreenshot({
    required String imagePath,
    required String productId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload screenshot to Firebase Storage
      final file = File(imagePath);
      final storageRef = _storage
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('ar_screenshots')
          .child('$productId-${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Record in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('ar_screenshots')
          .add({
        'productId': productId,
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to save screenshot: ${e.toString()}');
    }
  }

  void _recordModelView(String productId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('ar_views')
          .add({
        'productId': productId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log but don't throw
      print('Failed to record AR view: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getArHistory() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final arViews = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('ar_views')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final List<String> productIds = [];
      final Map<String, DateTime> viewDates = {};

      for (final doc in arViews.docs) {
        final productId = doc.data()['productId'] as String;
        final timestamp = doc.data()['timestamp'] as Timestamp?;

        if (!productIds.contains(productId)) {
          productIds.add(productId);
        }

        if (timestamp != null && (!viewDates.containsKey(productId) || timestamp.toDate().isAfter(viewDates[productId]!))) {
          viewDates[productId] = timestamp.toDate();
        }
      }

      if (productIds.isEmpty) {
        return [];
      }

      final products = await _getProductsByIds(productIds);

      return products.map((product) {
        return {
          'product': product,
          'lastViewed': viewDates[product.id] ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load AR history: ${e.toString()}');
    }
  }

  Future<List<Product>> _getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

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

    return products;
  }
}