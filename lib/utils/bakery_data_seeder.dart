import 'package:cloud_firestore/cloud_firestore.dart';

//-------------------- BAKERY DEMO DATA SEEDER --------------------
// Run this ONCE to seed demo products into Firestore
class BakeryDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedProducts() async {
    final products = _getDemoProducts();
    final batch = _firestore.batch();

    for (final product in products) {
      final ref = _firestore.collection('products').doc();
      batch.set(ref, product);
    }

    await batch.commit();
  }

  List<Map<String, dynamic>> _getDemoProducts() {
    final now = DateTime.now().toIso8601String();

    return [
      // ===================== CAKES & SWEETS =====================
      {
        'name': 'Classic Vanilla Birthday Cake (1 Kg)',
        'category': 'Cakes & Sweets',
        'price': 1800.0,
        'stockQty': 10,
        'description': 'Elegant single-tier vanilla sponge birthday cake with silky vanilla buttercream frosting, decorated with fresh flowers and birthday message. Made to order with premium vanilla extract. Serves 8-10 people.',
        'imageUrl': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400',
        'createdAt': now,
      },
      {
        'name': 'Rich Chocolate Fudge Cake (1 Kg)',
        'category': 'Cakes & Sweets',
        'price': 2000.0,
        'stockQty': 8,
        'description': 'Indulgent triple-layer dark chocolate fudge cake with a thick ganache filling and glossy chocolate glaze on top. Topped with chocolate curls. A chocoholic\'s dream. Serves 8-10 people.',
        'imageUrl': 'https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?w=400',
        'createdAt': now,
      },
      {
        'name': 'Red Velvet Wedding Cake Slice',
        'category': 'Cakes & Sweets',
        'price': 320.0,
        'stockQty': 20,
        'description': 'Stunning red velvet cake slice with 3 layers of moist red sponge and rich cream cheese frosting between each layer. Velvety smooth texture with a subtle cocoa flavor.',
        'imageUrl': 'https://images.unsplash.com/photo-1621303837174-89787a7d4729?w=400',
        'createdAt': now,
      },
      {
        'name': 'Pineapple Cream Cake (500g)',
        'category': 'Cakes & Sweets',
        'price': 950.0,
        'stockQty': 12,
        'description': 'Light and refreshing pineapple cake with fluffy vanilla sponge layers, fresh whipped cream, and chunks of juicy pineapple. Finished with cream rosettes and pineapple slices on top.',
        'imageUrl': 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400',
        'createdAt': now,
      },
      {
        'name': 'Gulab Jamun Box (12 pcs)',
        'category': 'Cakes & Sweets',
        'price': 350.0,
        'stockQty': 40,
        'description': 'Soft, melt-in-mouth khoya gulab jamun soaked in aromatic rose-cardamom sugar syrup. Made fresh daily with pure milk solids. Perfect for celebrations and dessert tables.',
        'imageUrl': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
        'createdAt': now,
      },
      {
        'name': 'Barfi Mithai Box (250g)',
        'category': 'Cakes & Sweets',
        'price': 450.0,
        'stockQty': 35,
        'description': 'Assorted traditional barfi box with kaju (cashew) barfi, pista barfi, and coconut barfi. Garnished with edible silver leaf (warq). Premium mithai for gifting and special occasions.',
        'imageUrl': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400',
        'createdAt': now,
      },
      {
        'name': 'Tres Leches Cake Slice',
        'category': 'Cakes & Sweets',
        'price': 280.0,
        'stockQty': 25,
        'description': 'Classic Latin-inspired tres leches (three milk) cake — ultra-moist sponge soaked in a mixture of whole milk, condensed milk, and heavy cream, topped with lightly sweetened whipped cream and cinnamon.',
        'imageUrl': 'https://images.unsplash.com/photo-1567171466295-4afa63d45416?w=400',
        'createdAt': now,
      },

      // ===================== PASTRIES & DESSERTS =====================
      {
        'name': 'Black Forest Pastry Slice',
        'category': 'Pastries & Desserts',
        'price': 180.0,
        'stockQty': 30,
        'description': 'Classic German-style Black Forest pastry with layers of chocolate sponge, whipped cream, and cherry topping. Fresh baked daily.',
        'imageUrl': 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400',
        'createdAt': now,
      },
      {
        'name': 'Caramel Fudge Brownie',
        'category': 'Pastries & Desserts',
        'price': 150.0,
        'stockQty': 45,
        'description': 'Rich dense chocolate brownie with gooey caramel drizzle and crushed walnuts on top. Packed with cocoa goodness.',
        'imageUrl': 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400',
        'createdAt': now,
      },
      {
        'name': 'Vanilla Cream Cupcake',
        'category': 'Pastries & Desserts',
        'price': 120.0,
        'stockQty': 60,
        'description': 'Soft vanilla sponge cupcake topped with swirled vanilla buttercream frosting and rainbow sprinkles.',
        'imageUrl': 'https://images.unsplash.com/photo-1587668178277-295251f900ce?w=400',
        'createdAt': now,
      },
      {
        'name': 'Mango Fruit Tart',
        'category': 'Pastries & Desserts',
        'price': 220.0,
        'stockQty': 20,
        'description': 'Buttery shortcrust pastry shell filled with smooth custard cream and topped with fresh mango slices and apricot glaze.',
        'imageUrl': 'https://images.unsplash.com/photo-1560180474-e8563fd75bab?w=400',
        'createdAt': now,
      },
      {
        'name': 'Chocolate Mousse Cup',
        'category': 'Pastries & Desserts',
        'price': 200.0,
        'stockQty': 25,
        'description': 'Silky smooth dark chocolate mousse served in an elegant dessert cup with chocolate shavings on top.',
        'imageUrl': 'https://images.unsplash.com/photo-1541599540903-216a46ca1dc0?w=400',
        'createdAt': now,
      },
      {
        'name': 'Strawberry Cheesecake Slice',
        'category': 'Pastries & Desserts',
        'price': 250.0,
        'stockQty': 18,
        'description': 'Creamy New York-style cheesecake on a Graham cracker crust, topped with fresh strawberry compote.',
        'imageUrl': 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400',
        'createdAt': now,
      },
      {
        'name': 'Tiramisu Dessert Box',
        'category': 'Pastries & Desserts',
        'price': 280.0,
        'stockQty': 15,
        'description': 'Italian-inspired tiramisu with espresso-soaked ladyfingers, mascarpone cream, and a dusting of premium cocoa.',
        'imageUrl': 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400',
        'createdAt': now,
      },

      // ===================== FRESH BREAD & BUNS =====================
      {
        'name': 'Large Sandwich Bread',
        'category': 'Fresh Bread & Buns',
        'price': 120.0,
        'stockQty': 80,
        'description': 'Soft and fluffy large loaf perfect for sandwiches and toast. Baked fresh every morning. No preservatives.',
        'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
        'createdAt': now,
      },
      {
        'name': 'Whole Wheat Brown Bread',
        'category': 'Fresh Bread & Buns',
        'price': 150.0,
        'stockQty': 55,
        'description': '100% whole wheat bread packed with fiber and nutrients. Ideal for health-conscious customers. No artificial colors.',
        'imageUrl': 'https://images.unsplash.com/photo-1598373182133-52452f7691ef?w=400',
        'createdAt': now,
      },
      {
        'name': 'Sesame Burger Buns (Pack of 4)',
        'category': 'Fresh Bread & Buns',
        'price': 90.0,
        'stockQty': 100,
        'description': 'Soft, pillowy burger buns topped with sesame seeds. Baked to golden perfection. Perfect for beef and chicken burgers.',
        'imageUrl': 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400',
        'createdAt': now,
      },
      {
        'name': 'Hot Dog Rolls (Pack of 6)',
        'category': 'Fresh Bread & Buns',
        'price': 100.0,
        'stockQty': 70,
        'description': 'Long, soft hot dog rolls with a light golden crust. Freshly baked and ideal for cafes and home use.',
        'imageUrl': 'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=400',
        'createdAt': now,
      },
      {
        'name': 'Milk Bread Loaf',
        'category': 'Fresh Bread & Buns',
        'price': 130.0,
        'stockQty': 65,
        'description': 'Enriched milk bread made with fresh full-cream milk. Softer and sweeter than regular bread. Kids favorite.',
        'imageUrl': 'https://images.unsplash.com/photo-1549931319-a545dcf3bc7c?w=400',
        'createdAt': now,
      },
      {
        'name': 'Garlic Butter Dinner Rolls (6 pcs)',
        'category': 'Fresh Bread & Buns',
        'price': 160.0,
        'stockQty': 40,
        'description': 'Fluffy pull-apart dinner rolls brushed with garlic herb butter. Freshly baked and served warm. Best paired with soup.',
        'imageUrl': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
        'createdAt': now,
      },

      // ===================== SAVORIES & SNACKS =====================
      {
        'name': 'Chicken Puff Pastry',
        'category': 'Savories & Snacks',
        'price': 80.0,
        'stockQty': 120,
        'description': 'Crispy golden puff pastry filled with spiced shredded chicken, onions, and green chilies. Baked fresh every 2 hours.',
        'imageUrl': 'https://images.unsplash.com/photo-1626078299034-694e5c3f25f9?w=400',
        'createdAt': now,
      },
      {
        'name': 'Vegetable Samosa (per piece)',
        'category': 'Savories & Snacks',
        'price': 40.0,
        'stockQty': 200,
        'description': 'Crispy triangular pastry filled with spiced potato and green peas. Served with mint chutney. Always hot and fresh.',
        'imageUrl': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
        'createdAt': now,
      },
      {
        'name': 'Chicken Club Sandwich',
        'category': 'Savories & Snacks',
        'price': 350.0,
        'stockQty': 35,
        'description': 'Triple-decker toasted club sandwich with grilled chicken, fresh lettuce, tomato, cheddar cheese, and mayo.',
        'imageUrl': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400',
        'createdAt': now,
      },
      {
        'name': 'Cheese & Chicken Pizza Slice',
        'category': 'Savories & Snacks',
        'price': 200.0,
        'stockQty': 50,
        'description': 'Generous slice of freshly baked pizza with chicken tikka chunks, mozzarella cheese, capsicum, and tomato sauce.',
        'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
        'createdAt': now,
      },
      {
        'name': 'Chicken Roll (Paratha Style)',
        'category': 'Savories & Snacks',
        'price': 180.0,
        'stockQty': 60,
        'description': 'Crispy layered paratha roll filled with spiced chicken tikka, pickled onions, and raita. A Pakistani deli classic.',
        'imageUrl': 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=400',
        'createdAt': now,
      },
      {
        'name': 'Beef Patties (Qeema Puff)',
        'category': 'Savories & Snacks',
        'price': 120.0,
        'stockQty': 90,
        'description': 'Flaky puff pastry stuffed with spiced minced beef keema with fresh herbs. Crispy on the outside, juicy on the inside.',
        'imageUrl': 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=400',
        'createdAt': now,
      },
      {
        'name': 'Egg Mayo Sandwich',
        'category': 'Savories & Snacks',
        'price': 150.0,
        'stockQty': 45,
        'description': 'Classic egg mayonnaise sandwich on soft white bread with lettuce, black pepper, and a hint of mustard.',
        'imageUrl': 'https://images.unsplash.com/photo-1481070555726-e2fe8357725c?w=400',
        'createdAt': now,
      },

      // ===================== BISCUITS & COOKIES =====================
      {
        'name': 'Almond Naankhatai (250g)',
        'category': 'Biscuits & Cookies',
        'price': 180.0,
        'stockQty': 75,
        'description': 'Traditional Pakistani shortbread biscuits made with flour, ghee, and sugar. Topped with whole almonds. Melt-in-mouth texture.',
        'imageUrl': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400',
        'createdAt': now,
      },
      {
        'name': 'Chocolate Chip Cookies (12 pcs)',
        'category': 'Biscuits & Cookies',
        'price': 220.0,
        'stockQty': 60,
        'description': 'American-style soft and chewy cookies loaded with dark chocolate chips and a sprinkle of sea salt on top.',
        'imageUrl': 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=400',
        'createdAt': now,
      },
      {
        'name': 'Zeera Biscuits (500g Pack)',
        'category': 'Biscuits & Cookies',
        'price': 150.0,
        'stockQty': 90,
        'description': 'Classic crispy cumin-flavored tea biscuits. Perfect to pair with evening chai. Made with pure desi ghee.',
        'imageUrl': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400',
        'createdAt': now,
      },
      {
        'name': 'Plain Cake Rusk (350g)',
        'category': 'Biscuits & Cookies',
        'price': 130.0,
        'stockQty': 110,
        'description': 'Twice-baked golden-crisp cake rusk. Light and crunchy, perfect for dunking in tea or coffee. A bakery staple.',
        'imageUrl': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=400',
        'createdAt': now,
      },
      {
        'name': 'Pistachio Shortbread Cookies (8 pcs)',
        'category': 'Biscuits & Cookies',
        'price': 260.0,
        'stockQty': 40,
        'description': 'Premium buttery shortbread cookies with crushed pistachios and a hint of rose water. Beautifully packaged.',
        'imageUrl': 'https://images.unsplash.com/photo-1588195538326-c5b1e9f80a1b?w=400',
        'createdAt': now,
      },
      {
        'name': 'Coconut Macaroons (6 pcs)',
        'category': 'Biscuits & Cookies',
        'price': 190.0,
        'stockQty': 55,
        'description': 'Chewy coconut macaroon cookies with a crisp golden exterior and soft coconut interior. Dipped in dark chocolate.',
        'imageUrl': 'https://images.unsplash.com/photo-1621236378699-8597faf6a11a?w=400',
        'createdAt': now,
      },
      {
        'name': 'Almond Rusk (400g)',
        'category': 'Biscuits & Cookies',
        'price': 200.0,
        'stockQty': 65,
        'description': 'Premium almond-studded cake rusk. Rich, crunchy, and packed with whole almonds in every bite. A luxury tea-time treat.',
        'imageUrl': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=400',
        'createdAt': now,
      },
    ];
  }
}
