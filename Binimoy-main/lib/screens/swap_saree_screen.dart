import 'package:binimoy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class SwapSaree extends StatefulWidget {
  final Map<String, dynamic> saree;

  const SwapSaree({super.key, required this.saree});

  @override
  State<SwapSaree> createState() => _SwapSareeState();
}

class _SwapSareeState extends State<SwapSaree>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _selectedUserSaree;
  List<Map<String, dynamic>> _userSarees = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    // Load user's sarees for swap
    _loadUserSarees();
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

  Future<void> _loadUserSarees() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final sareesSnapshot = await FirebaseFirestore.instance
          .collection('sarees')
          .where('userId', isEqualTo: user.uid)
          .where('isAvailable', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> sarees = [];

      for (var doc in sareesSnapshot.docs) {
        // Don't include the saree being viewed
        if (doc.id != widget.saree['id']) {
          Map<String, dynamic> saree = doc.data();
          saree['id'] = doc.id;
          sarees.add(saree);
        }
      }

      setState(() {
        _userSarees = sarees;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user sarees: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitSwapRequest() async {
    if (!_formKey.currentState!.validate() || _selectedUserSaree == null) {
      if (_selectedUserSaree == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a saree to swap')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get saree ID - ensure we're using the correct field
      final targetSareeId = widget.saree['id'] ?? widget.saree['documentId'];
      final offerSareeId =
          _selectedUserSaree!['id'] ?? _selectedUserSaree!['documentId'];

      if (targetSareeId == null || offerSareeId == null) {
        throw Exception('Invalid saree IDs');
      }

      // Create swap transaction
      final transactionRef =
          await FirebaseFirestore.instance.collection('transactions').add({
        // Target saree details (the one user wants to get)
        'sareeId': targetSareeId,
        'sareeName': widget.saree['name'] ?? 'Unknown',
        'sareeImage': widget.saree['imageUrl'] ?? '',

        // User's saree details (the one user offers for swap)
        'offerSareeId': offerSareeId,
        'offerSareeName': _selectedUserSaree!['name'] ?? 'Unknown',
        'offerSareeImage': _selectedUserSaree!['imageUrl'] ?? '',

        // User info (person who initiates the swap)
        'buyerId': user.uid, // In swap, this is the initiator
        'buyerName': _nameController.text,
        'buyerPhone': _phoneController.text,
        'buyerAddress': _addressController.text,

        // Seller info (original owner of the saree user wants)
        'sellerId': widget.saree['userId'] ?? '',
        'sellerName': widget.saree['userName'] ?? 'Anonymous',

        'type': TransactionType.swap.toString(),
        'status': TransactionStatus.pending.toString(),
        'amount': 0, // Swap doesn't involve money
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update both sarees status
      await FirebaseFirestore.instance
          .collection('sarees')
          .doc(targetSareeId)
          .update({
        'swapStatus': 'pending',
        'isAvailable': false, // Mark as not available during swap process
        'lastTransactionId': transactionRef.id,
      });

      await FirebaseFirestore.instance
          .collection('sarees')
          .doc(offerSareeId)
          .update({
        'swapStatus': 'pending',
        'isAvailable': false, // Mark as not available during swap process
        'lastTransactionId': transactionRef.id,
      });

      if (!mounted) return;

      // Modified navigation to match buy/rent screens
      // This will keep the first route (home) in the stack
      Navigator.pushNamedAndRemoveUntil(
          context, '/transaction_history', (route) => route.isFirst);
    } catch (e) {
      print('Swap error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process swap request: ${e.toString()}'),
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
          'Swap This Saree',
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
                              // Swap explanation
                              Container(
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue.shade700,
                                          size: 20.r,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'How Swapping Works',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Select one of your sarees to offer in exchange for this saree. The owner will review your offer and can accept or decline.',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.blue.shade800,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Target saree summary
                              Text(
                                'Saree You Want',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              _buildSareeCard(widget.saree, isTarget: true),

                              SizedBox(height: 32.h),

                              // User's sarees selection
                              Text(
                                'Select Your Saree to Swap',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              SizedBox(height: 16.h),

                              // Show user's sarees
                              _isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.green.shade700,
                                      ),
                                    )
                                  : _userSarees.isEmpty
                                      ? _buildNoSareesMessage()
                                      : _buildUserSareesList(),

                              SizedBox(height: 32.h),

                              // Contact information
                              if (_userSarees.isNotEmpty) ...[
                                Text(
                                  'Your Information',
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
                                  hintText: 'Enter your address',
                                  prefixIcon: Icons.location_on_outlined,
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Please enter your address'
                                      : null,
                                ),
                                SizedBox(height: 32.h),

                                // Submit button
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  width: double.infinity,
                                  height: 55.h,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _submitSwapRequest,
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.blue.shade700,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      elevation: 3,
                                      shadowColor: Colors.blue.withOpacity(0.3),
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
                                              Icon(Icons.swap_horiz,
                                                  size: 20.r),
                                              SizedBox(width: 8.w),
                                              Text(
                                                'Submit Swap Request',
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
                              ],
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

  Widget _buildNoSareesMessage() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48.r,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Sarees Available for Swap',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'You need to add sarees to your collection before you can swap.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () async {
              // Navigate to add post screen and wait for result
              final result = await Navigator.pushNamed(context, '/add-post');

              // Reload user sarees when returning from add post screen
              if (result != null) {
                _loadUserSarees();
              } else {
                // Even if no result, still reload to check for new sarees
                _loadUserSarees();
              }
            },
            icon: Icon(Icons.add),
            label: Text('Add a Saree'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green.shade600,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSareesList() {
    return Column(
      children: [
        for (var saree in _userSarees)
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedUserSaree = saree;
                });
              },
              borderRadius: BorderRadius.circular(16.r),
              child: _buildSareeCard(saree,
                  isSelected: _selectedUserSaree != null &&
                      _selectedUserSaree!['id'] == saree['id']),
            ),
          ),
      ],
    );
  }

  Widget _buildSareeCard(Map<String, dynamic> saree,
      {bool isSelected = false, bool isTarget = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected
              ? Colors.blue.shade400
              : isTarget
                  ? Colors.green.shade300
                  : Colors.grey.shade200,
          width: isSelected || isTarget ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saree image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14.r),
              bottomLeft: Radius.circular(14.r),
            ),
            child: Image.network(
              saree['imageUrl'] ?? '',
              width: 120.w,
              height: 140.h,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120.w,
                  height: 140.h,
                  color: Colors.grey.shade300,
                  child: Icon(Icons.image_not_supported, size: 30.r),
                );
              },
            ),
          ),

          // Saree details
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saree['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: isSelected
                          ? Colors.blue.shade800
                          : isTarget
                              ? Colors.green.shade800
                              : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),

                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 16.r,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        saree['type'] ?? 'Saree',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        size: 16.r,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '৳${saree['price'] ?? 0}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  if (!isTarget) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 16.r,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Added: ${_formatDate(saree['createdAt'])}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],

                  // Status badge or selection indicator
                  if (isTarget)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 16.r,
                            color: Colors.green.shade700,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Target Saree',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16.r,
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            isSelected ? 'Selected' : 'Tap to Select',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'Unknown';
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
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.blue.shade600,
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
              color: Colors.blue.shade400,
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
