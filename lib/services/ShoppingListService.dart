import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shopping_list_model.dart';

class ShoppingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<ShoppingList>> getShoppingLists() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get lists created by the user
      final ownedListsQuery = await _firestore
          .collection('shoppingLists')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      // Get lists shared with the user
      final sharedListsQuery = await _firestore
          .collection('shoppingLists')
          .where('sharedWithUsers', arrayContains: currentUser.uid)
          .get();

      // Combine and convert to ShoppingList objects
      final allLists = [...ownedListsQuery.docs, ...sharedListsQuery.docs];

      return allLists.map((doc) {
        return ShoppingList.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load shopping lists: ${e.toString()}');
    }
  }

  Future<ShoppingList> getShoppingList(String listId) async {
    try {
      final doc = await _firestore
          .collection('shoppingLists')
          .doc(listId)
          .get();

      if (!doc.exists) {
        throw Exception('Shopping list not found');
      }

      return ShoppingList.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Failed to load shopping list: ${e.toString()}');
    }
  }

  Future<void> createShoppingList({
    required String name,
    String description = '',
    double budgetLimit = 0,
    bool isPublic = false,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('shoppingLists').add({
        'userId': currentUser.uid,
        'name': name,
        'description': description,
        'budgetLimit': budgetLimit,
        'isPublic': isPublic,
        'items': [],
        'sharedWithUsers': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create shopping list: ${e.toString()}');
    }
  }

  Future<void> updateShoppingList(ShoppingList list) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('shoppingLists').doc(list.id).update({
        'name': list.name,
        'description': list.description,
        'budgetLimit': list.budgetLimit,
        'isPublic': list.isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update shopping list: ${e.toString()}');
    }
  }

  Future<void> deleteShoppingList(String listId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // First check if the user is the owner
      final doc = await _firestore
          .collection('shoppingLists')
          .doc(listId)
          .get();

      if (!doc.exists) {
        throw Exception('Shopping list not found');
      }

      final data = doc.data()!;
      if (data['userId'] != currentUser.uid) {
        throw Exception('You don\'t have permission to delete this list');
      }

      await _firestore.collection('shoppingLists').doc(listId).delete();
    } catch (e) {
      throw Exception('Failed to delete shopping list: ${e.toString()}');
    }
  }

  Future<void> addItemToList({
    required String listId,
    required ShoppingItem item,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if the item already exists in the list
      final doc = await _firestore
          .collection('shoppingLists')
          .doc(listId)
          .get();

      if (!doc.exists) {
        throw Exception('Shopping list not found');
      }

      final list = ShoppingList.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });

      // Check if the item already exists
      final existingItemIndex = list.items.indexWhere(
            (i) => i.productId == item.productId,
      );

      if (existingItemIndex >= 0) {
        // Update quantity of existing item
        final existingItem = list.items[existingItemIndex];
        final updatedItem = ShoppingItem(
          productId: existingItem.productId,
          productName: existingItem.productName,
          price: existingItem.price,
          quantity: existingItem.quantity + item.quantity,
          purchased: existingItem.purchased,
          notes: item.notes ?? existingItem.notes,
        );

        list.items[existingItemIndex] = updatedItem;
      } else {
        // Add new item
        list.items.add(item);
      }

      // Update the list in Firestore
      await _firestore.collection('shoppingLists').doc(listId).update({
        'items': list.items.map((i) => i.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add item to shopping list: ${e.toString()}');
    }
  }

  Future<void> removeItemFromList({
    required String listId,
    required String productId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the current list
      final doc = await _firestore
          .collection('shoppingLists')
          .doc(listId)
          .get();

      if (!doc.exists) {
        throw Exception('Shopping list not found');
      }

      final list = ShoppingList.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });

      // Remove the item
      final updatedItems = list.items.where(
            (item) => item.productId != productId,
      ).toList();

      // Update the list in Firestore
      await _firestore.collection('shoppingLists').doc(listId).update({
        'items': updatedItems.map((i) => i.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove item from shopping list: ${e.toString()}');
    }
  }

  Future<void> updateItemInList({
    required String listId,
    required ShoppingItem item,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the current list
      final doc = await _firestore
          .collection('shoppingLists')
          .doc(listId)
          .get();

      if (!doc.exists) {
        throw Exception('Shopping list not found');
      }

      final list = ShoppingList.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });

      // Find and update the item
      final updatedItems = list.items.map((i) {
        if (i.productId == item.productId) {
          return item;
        }
        return i;
      }).toList();

      // Update the list in Firestore
      await _firestore.collection('shoppingLists').doc(listId).update({
        'items': updatedItems.map((i) => i.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update item in shopping list: ${e.toString()}');
    }
  }

  Future<void> toggleItemPurchased({
    required String listId,
    required String productId,
    required bool purchased,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the current list
      final doc = await _firestore
          .collection('shoppingLists')
          .doc(listId)
          .get();

      if (!doc.exists) {
        throw Exception('Shopping list not found');
      }

      final list = ShoppingList.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });

      // Find and update the item
      final updatedItems = list.items.map((i) {
        if (i.productId == productId) {
          return ShoppingItem(
            productId: i.productId,
            productName: i.productName,
            price: i.price,
            quantity: i.quantity,
            purchased: purchased,
            notes: i.notes,
            arAnnotationReference: i.arAnnotationReference,
          );
        }
        return i;
      }).toList();

      // Update the list in Firestore
      await _firestore.collection('shoppingLists').doc(listId).update({
        'items': updatedItems.map((i) => i.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update item in shopping list: ${e.toString()}');
    }
  }

  Future<void> shareShoppingList({
    required String listId,
    required String email,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the user ID for the provided email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found with the provided email');
      }

      final userId = userQuery.docs.first.id;

      // Get the current list
      final listDoc = await _firestore
          .collection('shoppingLists')
          .doc(listId)
          .get();

      if (!listDoc.exists) {
        throw Exception('Shopping list not found');
      }

      // Add the user to the shared list
      final sharedWithUsers = List<String>.from(listDoc.data()!['sharedWithUsers'] ?? []);

      if (sharedWithUsers.contains(userId)) {
        // User already has access
        return;
      }

      sharedWithUsers.add(userId);

      // Update the list in Firestore
      await _firestore.collection('shoppingLists').doc(listId).update({
        'sharedWithUsers': sharedWithUsers,
        'isPublic': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to share shopping list: ${e.toString()}');
    }
  }
}