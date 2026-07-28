//-------------------- INVOICE ITEM MODEL --------------------
class InvoiceItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double total;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      price: (map['price'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }
}

//-------------------- INVOICE MODEL --------------------
class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final List<InvoiceItem> items;
  final double totalAmount;
  final double amountPaid;
  final double dueAmount;
  final String createdBy; // uid of admin/staff who made the sale
  final DateTime date;
  final double discount;
  final double tax;
  final DateTime? dueDate;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.amountPaid,
    required this.dueAmount,
    required this.createdBy,
    required this.date,
    this.discount = 0.0,
    this.tax = 0.0,
    this.dueDate,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    final total = (map['totalAmount'] ?? 0).toDouble();
    return InvoiceModel(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: total,
      amountPaid: (map['amountPaid'] ?? total).toDouble(),
      dueAmount: (map['dueAmount'] ?? 0).toDouble(),
      createdBy: map['createdBy'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'dueAmount': dueAmount,
      'createdBy': createdBy,
      'date': date.toIso8601String(),
      'discount': discount,
      'tax': tax,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
