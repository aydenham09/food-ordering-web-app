import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  test('product maps seeded image path to local asset', () {
    final product = Product.fromJson({
      'id': 1,
      'name': 'Burger',
      'description': 'Test',
      'price': 10000,
      'image': '/images/burger.png',
      'avg_rating': 4.5,
      'order_count': 10,
      'category_id': 1,
    });

    expect(product.imagePath, 'assets/images/burger.png');
  });
}
