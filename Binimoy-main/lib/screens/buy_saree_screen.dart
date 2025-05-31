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

  bool _isDisposed = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Cash on Delivery',
      'icon': Icons.payments_outlined,
      'description': 'Pay when you receive the item'
    },
    {
      'name': 'bKash',
      'icon': Icons.account_balance_wallet_outlined,
      'description': 'Mobile banking payment'
    },
    {
      'name': 'Nagad',
      'icon': Icons.account_balance_wallet_outlined,
      'description': 'Digital financial service'
    },
    {
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card_outlined,
      'description': 'Secure card payment'
    },
  ];

  // Helper method to get display image URL
  String _getDisplayImageUrl() {
    if (widget.saree['images'] != null && widget.saree['images'] is Map) {
      final images = widget.saree['images'] as Map<String, dynamic>;
      return images['anchol'] ??
          images['par'] ??
          images['jomin'] ??
          images['kuchi'] ??
          '';
    }
    return widget.saree['imageUrl'] ?? '';
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    if (!_isDisposed && mounted) {
      _animationController.forward();
    }

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
    _isDisposed = true;
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

      final transactionRef =
          await FirebaseFirestore.instance.collection('transactions').add({
        'sareeId': widget.saree['documentId'] ?? widget.saree['id'],
        'sareeName': widget.saree['name'] ?? 'Unknown',
        'sareeImage': _getDisplayImageUrl(),
        'buyerId': user.uid,
        'buyerName': _nameController.text,
        'buyerPhone': _phoneController.text,
        'buyerAddress': _addressController.text,
        'buyerCity': _cityController.text,
        'buyerPostalCode': _postalCodeController.text,
        'sellerId': widget.saree['userId'] ?? '',
        'sellerName': widget.saree['userName'] ?? 'Anonymous',
        'type': TransactionType.buy.toString(),
        'status': TransactionStatus.pending.toString(),
        'amount': widget.saree['totalPrice'] ?? widget.saree['price'] ?? 0.0,
        'paymentMethod': _selectedPaymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final sareeId = widget.saree['documentId'] ?? widget.saree['id'];
      if (sareeId == null) {
        throw Exception('Invalid saree ID');
      }

      await FirebaseFirestore.instance
          .collection('sarees')
          .doc(sareeId)
          .update({
        'isAvailable': false,
        'lastTransactionId': transactionRef.id,
      });

      if (!mounted) return;

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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Custom App Bar with glass effect
                  Container(
                    margin: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.arrow_back,
                                      color: Colors.white, size: 20.r),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Complete Purchase',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'BUY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: SingleChildScrollView(
                              physics: BouncingScrollPhysics(),
                              child: Padding(
                                padding: EdgeInsets.all(20.r),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Order Summary Section
                                      _buildOrderSummary(),
                                      SizedBox(height: 24.h),

                                      // Shipping Information Section
                                      _buildShippingSection(),
                                      SizedBox(height: 24.h),

                                      // Payment Method Section
                                      _buildPaymentSection(),
                                      SizedBox(height: 32.h),

                                      // Submit Button
                                      _buildSubmitButton(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final basePrice = widget.saree['basePrice'] ?? widget.saree['price'] ?? 0.0;
    final serviceCharge = widget.saree['serviceCharge'] ?? 0.0;
    final totalPrice = widget.saree['totalPrice'] ?? basePrice;
    final deliveryFee = 60.0;
    final finalTotal = totalPrice + deliveryFee;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_outlined, color: Colors.white, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Saree item card
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // Saree image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: 60.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Image.network(
                      _getDisplayImageUrl(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withOpacity(0.1),
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white.withOpacity(0.5),
                            size: 24.r,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Saree details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.saree['name'] ?? 'Unknown Saree',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          widget.saree['type'] ?? 'Saree',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14.r, color: Colors.white.withOpacity(0.7)),
                          SizedBox(width: 4.w),
                          Text(
                            widget.saree['userName'] ?? 'Anonymous',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white.withOpacity(0.8),
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
          SizedBox(height: 16.h),

          // Price breakdown
          _buildPriceRow('Base Price:', '৳${basePrice.toStringAsFixed(2)}'),
          if (serviceCharge > 0) ...[
            _buildPriceRow(
                'Service Charge:', '৳${serviceCharge.toStringAsFixed(2)}'),
          ],
          _buildPriceRow('Subtotal:', '৳${totalPrice.toStringAsFixed(2)}'),
          _buildPriceRow('Delivery Fee:', '৳${deliveryFee.toStringAsFixed(2)}'),

          Divider(color: Colors.white.withOpacity(0.3), height: 24.h),

          _buildPriceRow('Total Amount:', '৳${finalTotal.toStringAsFixed(2)}',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildShippingSection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  color: Colors.white, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Shipping Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildGlassTextField(
            controller: _nameController,
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person_outline,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter your name' : null,
          ),
          SizedBox(height: 16.h),
          _buildGlassTextField(
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
          _buildGlassTextField(
            controller: _addressController,
            labelText: 'Address',
            hintText: 'Enter your street address',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter your address' : null,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildGlassTextField(
                  controller: _cityController,
                  labelText: 'City',
                  hintText: 'Enter city',
                  prefixIcon: Icons.location_city_outlined,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter city' : null,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildGlassTextField(
                  controller: _postalCodeController,
                  labelText: 'Postal Code',
                  hintText: 'Enter postal code',
                  prefixIcon: Icons.markunread_mailbox_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter postal code'
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_outlined, color: Colors.white, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Column(
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['name'];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method['name'];
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10.w,
                                    height: 10.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            method['icon'],
                            color: Colors.white,
                            size: 20.r,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['name'],
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                method['description'],
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20.r,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 20.r),
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
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int? maxLines,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  prefixIcon,
                  color: Colors.white.withOpacity(0.8),
                  size: 20.r,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16.h,
                  horizontal: 16.w,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              keyboardType: keyboardType,
              maxLines: maxLines ?? 1,
              validator: validator,
            ),
          ),
        ),
      ),
    );
  }
}
