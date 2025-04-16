import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String targetId; // User or Saree ID being reviewed
  final String targetType; // 'user' or 'saree'
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.targetId,
    required this.targetType,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'targetId': targetId,
      'targetType': targetType,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}