class User {
  final String id;
  final String email;
  final String name;
  final String profilePicture;
  final List<String> favoriteItems;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profilePicture = '',
    this.favoriteItems = const [],
    this.preferences = const {},
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
      favoriteItems: List<String>.from(map['favoriteItems'] ?? []),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profilePicture': profilePicture,
      'favoriteItems': favoriteItems,
      'preferences': preferences,
    };
  }
}