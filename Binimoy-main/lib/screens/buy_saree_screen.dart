import 'package:binimoy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class BuySareeScreen extends StatefulWidget {
  final Map<String, dynamic> saree;

  const BuySareeScreen({super.key, required this.saree});

  @override
  State<BuySareeScreen> createState() => _BuySareeScreenState();
}

class _BuySareeScreenState extends State<BuySareeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'bKash',
    'Nagad',
    'Credit/Debit Card',
  ];

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

    // Pre-fill user data if available
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          setState(() {
            _nameController.text = userData?['name'] ?? user.displayName ?? '';
            _phoneController.text = userData?['phone'] ?? '';
            _addressController.text = userData?['address'] ?? '';
            _cityController.text = userData?['city'] ?? '';
            _postalCodeController.text = userData?['postalCode'] ?? '';
          });
        } else {
          _nameController.text = user.displayName ?? '';
        }
      } catch (e) {
        print('Error loading user data: $e');
        _nameController.text = user.displayName ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create transaction document
      final transactionRef =
          await FirebaseFirestore.instance.collection('transactions').add({
        'sareeId': widget.saree['documentId'] ??
            widget.saree['id'], // Try both possible ID fields
        'sareeName': widget.saree['name'] ?? 'Unknown',
        'sareeImage': widget.saree['imageUrl'] ?? '',
        'buyerId': user.uid,
        'buyerName': _nameController.text,
        'buyerPhone': _phoneController.text,
        'buyerAddress': _addressController.text,
        'buyerCity': _cityController.text,
        'buyerPostalCode': _postalCodeController.text,
        'sellerId': widget.saree['userId'] ?? '',
        'sellerName': widget.saree['userName'] ?? 'Anonymous',
        'type': TransactionType.buy
            .toString(), // Fix: Changed from string to enum toString()
        'status': TransactionStatus.pending.toString(),
        'amount': widget.saree['price'] ?? 0.0,
        'paymentMethod': _selectedPaymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get the saree ID
      final sareeId = widget.saree['documentId'] ?? widget.saree['id'];
      if (sareeId == null) {
        throw Exception('Invalid saree ID');
      }

      // Update the saree document
      await FirebaseFirestore.instance
          .collection('sarees')
          .doc(sareeId)
          .update({
        'isAvailable': false,
        'lastTransactionId': transactionRef.id,
      });

      if (!mounted) return;

      // Navigate to transaction history screen directly
      Navigator.pushNamedAndRemoveUntil(
          context, '/transaction_history', (route) => route.isFirst);
    } catch (e) {
      print('Transaction error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process order: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'Complete Your Purchase',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Main content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.r),
                        topRight: Radius.circular(30.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.r),
                        topRight: Radius.circular(30.r),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24.r),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order summary
                              _buildOrderSummary(),
                              SizedBox(height: 24.h),

                              // Shipping information form
                              Text(
                                'Shipping Information',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              SizedBox(height: 16.h),

                              // Name field
                              _buildTextField(
                                controller: _nameController,
                                labelText: 'Full Name',
                                hintText: 'Enter your full name',
                                prefixIcon: Icons.person_outline,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Please enter your name'
                                    : null,
                              ),
                              SizedBox(height: 16.h),

                              // Phone field
                              _buildTextField(
                                controller: _phoneController,
                                labelText: 'Phone Number',
                                hintText: 'Enter your phone number',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Please enter your phone number'
                                    : null,
                              ),
                              SizedBox(height: 16.h),

                              // Address field
                              _buildTextField(
                                controller: _addressController,
                                labelText: 'Address',
                                hintText: 'Enter your street address',
                                prefixIcon: Icons.location_on_outlined,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Please enter your address'
                                    : null,
                              ),
                              SizedBox(height: 16.h),

                              // City and postal code fields
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _cityController,
                                      labelText: 'City',
                                      hintText: 'Enter city',
                                      prefixIcon: Icons.location_city_outlined,
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Please enter city'
                                              : null,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _postalCodeController,
                                      labelText: 'Postal Code',
                                      hintText: 'Enter postal code',
                                      prefixIcon:
                                          Icons.markunread_mailbox_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Please enter postal code'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24.h),

                              // Payment method selection
                              Text(
                                'Payment Method',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              SizedBox(height: 16.h),

                              _buildPaymentMethodSelection(),
                              SizedBox(height: 32.h),

                              // Submit button
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: double.infinity,
                                height: 55.h,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitOrder,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green.shade700,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    elevation: 3,
                                    shadowColor: Colors.green.withOpacity(0.3),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 24.r,
                                          width: 24.r,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.shopping_bag_outlined,
                                                size: 20.r),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Place Order',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final sareePrice = widget.saree['price'] ?? 0.0;
    final deliveryFee = 60.0;
    final total = sareePrice + deliveryFee;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 16.h),

          // Saree item
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saree image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  widget.saree['imageUrl'] ?? '',
                  width: 60.w,
                  height: 80.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60.w,
                      height: 80.h,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.image_not_supported, size: 24.r),
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),

              // Saree details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.saree['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Type: ${widget.saree['type'] ?? 'Saree'}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Seller: ${widget.saree['userName'] ?? 'Anonymous'}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Text(
                '৳${sareePrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),

          Divider(height: 24.h, color: Colors.grey.shade300),

          // Price breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '৳${sareePrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '৳${deliveryFee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          Divider(height: 24.h, color: Colors.grey.shade300),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                '৳${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      children: _paymentMethods.map((method) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method;
              });
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == method
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _selectedPaymentMethod == method
                      ? Colors.green.shade400
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22.w,
                    height: 22.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedPaymentMethod == method
                            ? Colors.green.shade700
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _selectedPaymentMethod == method
                        ? Center(
                            child: Container(
                              width: 12.w,
                              height: 12.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.shade700,
                              ),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    method,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: _selectedPaymentMethod == method
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _selectedPaymentMethod == method
                          ? Colors.green.shade800
                          : Colors.grey.shade800,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    _getPaymentMethodIcon(method),
                    color: _selectedPaymentMethod == method
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                    size: 24.r,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Cash on Delivery':
        return Icons.payments_outlined;
      case 'bKash':
        return Icons.account_balance_wallet_outlined;
      case 'Nagad':
        return Icons.account_balance_wallet_outlined;
      case 'Credit/Debit Card':
        return Icons.credit_card_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  // Helper method to build text fields with consistent styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 15.sp,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.green.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 16.w,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: Colors.green.shade400,
              width: 1.5,
            ),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
