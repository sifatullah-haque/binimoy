import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';

class ReviewDialog extends StatefulWidget {
  final String targetId;
  final String targetType;

  const ReviewDialog({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _commentController = TextEditingController();
  double _rating = 5.0;

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final review = Review(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        targetId: widget.targetId,
        targetType: widget.targetType,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('reviews').add(review.toMap());

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write a Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Write your review',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}