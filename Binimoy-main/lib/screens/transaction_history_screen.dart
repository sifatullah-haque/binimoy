import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  String _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return '#FFA500';
      case TransactionStatus.confirmed:
        return '#4CAF50';
      case TransactionStatus.completed:
        return '#2196F3';
      case TransactionStatus.cancelled:
        return '#F44336';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<firestore.QuerySnapshot>(
        stream: firestore.FirebaseFirestore.instance
            .collection('transactions')
            .where('buyerId', isEqualTo: currentUser?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transactions = snapshot.data?.docs ?? [];

          if (transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet'),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = Transaction.fromMap(
                transactions[index].data() as Map<String, dynamic>,
                transactions[index].id,
              );

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(transaction.sareeImage),
                  ),
                  title: Text(transaction.sareeName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount: ৳${transaction.amount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Type: ${transaction.type.toString().split('.').last}'),
                      if (transaction.type == TransactionType.rent)
                        Text(
                          'Duration: ${transaction.startDate.toString().split(' ')[0]} - ${transaction.endDate?.toString().split(' ')[0] ?? 'N/A'}',
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(
                          _getStatusColor(transaction.status).replaceAll('#', '0xFF'),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.status.toString().split('.').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}