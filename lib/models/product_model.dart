//-------------------- BAKERY CATEGORIES CONSTANT --------------------
const List<String> kBakeryCategories = [
  'Cakes & Sweets',
  'Pastries & Desserts',
  'Fresh Bread & Buns',
  'Savories & Snacks',
  'Biscuits & Cookies',
];

//-------------------- PRODUCT MODEL --------------------
class ProductModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int stockQty;
  final String category; // Bakery product category
  final String description;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.stockQty,
    this.category = 'Cakes & Sweets',
    required this.description,
    required this.createdAt,
  });

  //-------------------- FIRESTORE -> MODEL --------------------
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stockQty: (map['stockQty'] ?? 0).toInt(),
      category: map['category'] ?? 'Cakes & Sweets',
      description: map['description'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  //-------------------- MODEL -> FIRESTORE --------------------
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'stockQty': stockQty,
      'category': category,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  //-------------------- HELPER --------------------
  bool get isLowStock => stockQty <= 5;
}
