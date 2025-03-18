class PriceHistoryEntry {
  final DateTime date;
  final double price;
  final String retailer;

  PriceHistoryEntry({
    required this.date,
    required this.price,
    required this.retailer,
  });

  factory PriceHistoryEntry.fromMap(Map<String, dynamic> map) {
    return PriceHistoryEntry(
      date: map['date'].toDate(),
      price: map['price'].toDouble(),
      retailer: map['retailer'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'price': price,
      'retailer': retailer,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String brand;
  final List<String> categories;
  final List<String> images;
  final String modelUrl; // 3D model for AR
  final Map<String, dynamic> dimensions;
  final List<PriceHistoryEntry> priceHistory;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.brand,
    this.categories = const [],
    this.images = const [],
    this.modelUrl = '',
    this.dimensions = const {},
    this.priceHistory = const [],
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      brand: map['brand'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      modelUrl: map['modelUrl'] ?? '',
      dimensions: Map<String, dynamic>.from(map['dimensions'] ?? {}),
      priceHistory: (map['priceHistory'] as List<dynamic>?)
          ?.map((e) => PriceHistoryEntry.fromMap(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'brand': brand,
      'categories': categories,
      'images': images,
      'modelUrl': modelUrl,
      'dimensions': dimensions,
      'priceHistory': priceHistory.map((e) => e.toMap()).toList(),
    };
  }
}