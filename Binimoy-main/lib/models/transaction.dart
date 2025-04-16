import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { buy, rent, swap }
enum TransactionStatus { pending, confirmed, completed, cancelled }

class Transaction {
  final String id;
  final String sareeId;
  final String sareeName;
  final String sareeImage;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final DateTime startDate;
  final DateTime? endDate;  // For rentals
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.sareeId,
    required this.sareeName,
    required this.sareeImage,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.type,
    required this.status,
    required this.amount,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      sareeId: map['sareeId']?.toString() ?? '',
      sareeName: map['sareeName']?.toString() ?? 'Unknown',
      sareeImage: map['sareeImage']?.toString() ?? '',
      buyerId: map['buyerId']?.toString() ?? '',
      buyerName: map['buyerName']?.toString() ?? 'Anonymous',
      sellerId: map['sellerId']?.toString() ?? '',
      sellerName: map['sellerName']?.toString() ?? 'Unknown',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${map['type'] ?? 'buy'}',
        orElse: () => TransactionType.buy,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${map['status'] ?? 'pending'}',
        orElse: () => TransactionStatus.pending,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: map['endDate'] != null 
          ? (map['endDate'] as Timestamp).toDate() 
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sareeId': sareeId,
      'sareeName': sareeName,
      'sareeImage': sareeImage,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'type': type.toString(),
      'status': status.toString(),
      'amount': amount,
      'startDate': startDate,
      'endDate': endDate,
      'createdAt': createdAt,
    };
  }
}