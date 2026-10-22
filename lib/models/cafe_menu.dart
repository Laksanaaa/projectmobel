
class CafeMenu {
  final int id;
  final String name;
  final String category;
  final double price;
  final bool isAvailable;

  const CafeMenu({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.isAvailable,
  });

  factory CafeMenu.fromMap(Map<String, dynamic> map) {
    return CafeMenu(
      id: int.parse(map['id'].toString()),
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      price: double.parse(map['price'].toString()),
      isAvailable: map['is_available'] == true ||
          map['is_available'].toString() == '1',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'is_available': isAvailable ? 1 : 0,
    };
  }
}
