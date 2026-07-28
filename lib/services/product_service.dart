import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

//-------------------- PRODUCT SERVICE --------------------
class ProductService {
  final CollectionReference _productsRef = FirebaseFirestore.instance
      .collection('products');

  //-------------------- ADD PRODUCT --------------------
  Future<void> addProduct(ProductModel product) async {
    await _productsRef.add(product.toMap());
  }

  //-------------------- UPDATE PRODUCT --------------------
  Future<void> updateProduct(String id, ProductModel product) async {
    await _productsRef.doc(id).update(product.toMap());
  }

  //-------------------- DELETE PRODUCT --------------------
  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }

  //-------------------- GET ALL PRODUCTS (real-time stream) --------------------
  Stream<List<ProductModel>> getProducts() {
    return _productsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ProductModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  //-------------------- GET SINGLE PRODUCT --------------------
  Future<ProductModel?> getProductById(String id) async {
    DocumentSnapshot doc = await _productsRef.doc(id).get();
    if (doc.exists) {
      return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  //-------------------- REDUCE STOCK (used later during Sales) --------------------
  Future<void> reduceStock(String id, int quantitySold) async {
    await _productsRef.doc(id).update({
      'stockQty': FieldValue.increment(-quantitySold),
    });
  }
}
