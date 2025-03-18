class ShoppingItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final bool purchased;
  final String? notes;
  final String? arAnnotationReference; // Reference to AR annotation data

  ShoppingItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
    this.purchased = false,
    this.notes,
    this.arAnnotationReference,
  });

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      purchased: map['purchased'] ?? false,
      notes: map['notes'],
      arAnnotationReference: map['arAnnotationReference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'purchased': purchased,
      'notes': notes,
      'arAnnotationReference': arAnnotationReference,
    };
  }

  double get totalPrice => price * quantity;
}

class ShoppingList {
  final String id;
  final String name;
  final String description;
  final List<ShoppingItem> items;
  final double budgetLimit;
  final List<String> sharedWithUsers;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList({
    required this.id,
    required this.name,
    this.description = '',
    this.items = const [],
    this.budgetLimit = 0,
    this.sharedWithUsers = const [],
    this.isPublic = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((e) => ShoppingItem.fromMap(e))
          .toList() ??
          [],
      budgetLimit: (map['budgetLimit'] ?? 0).toDouble(),
      sharedWithUsers: List<String>.from(map['sharedWithUsers'] ?? []),
      isPublic: map['isPublic'] ?? false,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'items': items.map((e) => e.toMap()).toList(),
      'budgetLimit': budgetLimit,
      'sharedWithUsers': sharedWithUsers,
      'isPublic': isPublic,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  double get totalCost {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  int get purchasedItems {
    return items.where((item) => item.purchased).length;
  }

  bool get isCompleted {
    return items.isNotEmpty && items.every((item) => item.purchased);
  }

  bool get isOverBudget {
    return budgetLimit > 0 && totalCost > budgetLimit;
  }
}