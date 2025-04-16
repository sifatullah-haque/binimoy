import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
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

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Buy', 'Rent', 'Pending', 'Completed'];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              height: 5.h,
              width: 40.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5.r),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade700),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.grey.shade200),

            // Transaction details
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Container(
                      height: 200.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        image: DecorationImage(
                          image: NetworkImage(transaction.sareeImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Product name and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.sareeName,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(
                                _getStatusColor(transaction.status)
                                    .replaceAll('#', '0xFF'),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            transaction.status.toString().split('.').last,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Transaction type
                    _buildDetailRow(
                      'Transaction Type',
                      transaction.type.toString().split('.').last,
                      Icons.swap_horiz,
                    ),
                    Divider(color: Colors.grey.shade200, height: 24.h),

                    // Transaction date
                    _buildDetailRow(
                      'Date',
                      DateFormat('dd MMMM yyyy, hh:mm a').format(
                        transaction.createdAt,
                      ),
                      Icons.calendar_today,
                    ),
                    Divider(color: Colors.grey.shade200, height: 24.h),

                    // Payment details
                    _buildDetailRow(
                      'Amount',
                      '৳${transaction.amount.toStringAsFixed(2)}',
                      Icons.payments_outlined,
                    ),
                    Divider(color: Colors.grey.shade200, height: 24.h),

                    // Seller information
                    _buildDetailRow(
                      'Seller',
                      transaction.sellerName,
                      Icons.person_outline,
                    ),

                    // If it's a rental transaction, show rental period
                    if (transaction.type == TransactionType.rent) ...[
                      Divider(color: Colors.grey.shade200, height: 24.h),
                      _buildDetailRow(
                        'Rental Period',
                        '${DateFormat('dd MMM').format(transaction.startDate)} to ${DateFormat('dd MMM, yyyy').format(transaction.endDate ?? transaction.startDate)}',
                        Icons.date_range,
                      ),
                    ],

                    SizedBox(height: 24.h),

                    // Action buttons
                    if (transaction.status == TransactionStatus.pending ||
                        transaction.status == TransactionStatus.confirmed) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Transaction cancelled'),
                                    backgroundColor: Colors.red.shade400,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                backgroundColor: Colors.red.shade50,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text('Cancel Order'),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: Contact seller functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Contacting seller...')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green.shade700,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text('Contact Seller'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // For completed orders, show review button
                    if (transaction.status == TransactionStatus.completed)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Review functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Review functionality coming soon!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green.shade700,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          minimumSize: Size(double.infinity, 48.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text('Write a Review'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.green.shade700,
            size: 20.r,
          ),
        ),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade800.withOpacity(0.3),
                    Colors.teal.shade600.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade800,
              Colors.teal.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Filter tabs
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.green.shade700
                                      : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Transaction list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: StreamBuilder<firestore.QuerySnapshot>(
                      stream: firestore.FirebaseFirestore.instance
                          .collection('transactions')
                          .where('buyerId', isEqualTo: currentUser?.uid)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                                color: Colors.green.shade700),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 60.r,
                                  color: Colors.red.shade300,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Error loading transactions',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                TextButton(
                                  onPressed: () => setState(() {}),
                                  child: Text('Try Again'),
                                ),
                              ],
                            ),
                          );
                        }

                        final transactions = snapshot.data?.docs ?? [];

                        if (transactions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/no_transactions.png', // Replace with your asset
                                  height: 120.h,
                                  width: 120.w,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.receipt_long,
                                    size: 80.r,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  'No Transactions Yet',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Your purchase and rental history will appear here',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Convert to Transaction objects and filter if needed
                        List<Transaction> filteredTransactions = transactions
                            .map((doc) => Transaction.fromMap(
                                  doc.data() as Map<String, dynamic>,
                                  doc.id,
                                ))
                            .where((transaction) {
                          if (_selectedFilter == 'All') return true;
                          if (_selectedFilter == 'Buy') {
                            return transaction.type == TransactionType.buy;
                          }
                          if (_selectedFilter == 'Rent') {
                            return transaction.type == TransactionType.rent;
                          }
                          if (_selectedFilter == 'Pending') {
                            return transaction.status ==
                                TransactionStatus.pending;
                          }
                          if (_selectedFilter == 'Completed') {
                            return transaction.status ==
                                TransactionStatus.completed;
                          }
                          return true;
                        }).toList();

                        if (filteredTransactions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  size: 60.r,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No ${_selectedFilter} Transactions',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Try selecting a different filter',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    // Get appropriate icon based on transaction type
    IconData getTypeIcon() {
      switch (transaction.type) {
        case TransactionType.buy:
          return Icons.shopping_bag_outlined;
        case TransactionType.rent:
          return Icons.event_available_outlined;
        case TransactionType.swap:
          return Icons.swap_horiz;
        default:
          return Icons.shopping_cart_outlined;
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Transaction header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Transaction ID
                    Text(
                      'ID: ${transaction.id.substring(0, 8)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.sp,
                      ),
                    ),
                    // Transaction date
                    Text(
                      DateFormat('dd MMM yyyy').format(transaction.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction body
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saree image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.network(
                        transaction.sareeImage,
                        width: 70.w,
                        height: 70.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70.w,
                            height: 70.h,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),

                    // Transaction details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Saree name
                          Text(
                            transaction.sareeName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: Colors.green.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),

                          // Seller name
                          Text(
                            'Seller: ${transaction.sellerName.isEmpty ? 'Anonymous' : transaction.sellerName}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),

                          // Transaction info
                          Row(
                            children: [
                              // Transaction type
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: transaction.type == TransactionType.buy
                                      ? Colors.green.shade50
                                      : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      getTypeIcon(),
                                      size: 12.r,
                                      color: transaction.type ==
                                              TransactionType.buy
                                          ? Colors.green.shade700
                                          : Colors.amber.shade700,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      transaction.type
                                          .toString()
                                          .split('.')
                                          .last,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: transaction.type ==
                                                TransactionType.buy
                                            ? Colors.green.shade700
                                            : Colors.amber.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Spacer(),

                              // Amount
                              Text(
                                '৳${transaction.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction footer with status
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(
                      _getStatusColor(transaction.status)
                          .replaceAll('#', '0xFF'),
                    ),
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(
                          int.parse(
                            _getStatusColor(transaction.status)
                                .replaceAll('#', '0xFF'),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      transaction.status.toString().split('.').last,
                      style: TextStyle(
                        color: Color(
                          int.parse(
                            _getStatusColor(transaction.status)
                                .replaceAll('#', '0xFF'),
                          ),
                        ),
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '- Tap for details',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
