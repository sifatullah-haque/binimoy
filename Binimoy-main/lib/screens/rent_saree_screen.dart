import 'package:binimoy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class RentSareeScreen extends StatefulWidget {
  final Map<String, dynamic> saree;

  const RentSareeScreen({super.key, required this.saree});

  @override
  State<RentSareeScreen> createState() => _RentSareeScreenState();
}

class _RentSareeScreenState extends State<RentSareeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime _selectedStartDate = DateTime.now().add(Duration(days: 1));
  DateTime _selectedEndDate = DateTime.now().add(Duration(days: 3));
  int _rentalDuration = 3; // Default duration in days
  bool _isLoading = false;
  String _selectedPaymentMethod = 'bKash';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now().add(Duration(days: 1));
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  final List<String> _unavailableDates = [];
  double _dailyRate = 0; // Will be calculated based on saree price

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

    // Initialize range selection
    _rangeStart = _selectedStartDate;
    _rangeEnd = _selectedEndDate;

    // Calculate daily rate (10% of saree price)
    if (widget.saree['price'] != null) {
      setState(() {
        _dailyRate = (widget.saree['price'] as num) * 0.1;
      });
    }

    // Load unavailable dates from Firestore
    _loadUnavailableDates();

    // Pre-fill user data if available
    _loadUserData();
  }

  Future<void> _loadUnavailableDates() async {
    try {
      final transactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('sareeId', isEqualTo: widget.saree['id'])
          .where('type', isEqualTo: 'TransactionType.rent')
          .where('status', whereIn: [
        'TransactionStatus.approved',
        'TransactionStatus.pending'
      ]).get();

      final List<String> dates = [];

      for (var doc in transactions.docs) {
        final data = doc.data();
        if (data['startDate'] != null && data['endDate'] != null) {
          final start = (data['startDate'] as Timestamp).toDate();
          final end = (data['endDate'] as Timestamp).toDate();

          // Add all dates between start and end (inclusive)
          for (var d = start;
              d.isBefore(end.add(Duration(days: 1)));
              d = d.add(Duration(days: 1))) {
            dates.add(DateFormat('yyyy-MM-dd').format(d));
          }
        }
      }

      if (mounted) {
        setState(() {
          _unavailableDates.addAll(dates);
        });
      }
    } catch (e) {
      print('Error loading unavailable dates: $e');
    }
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateRentalDuration() {
    if (_rangeStart != null && _rangeEnd != null) {
      setState(() {
        _selectedStartDate = _rangeStart!;
        _selectedEndDate = _rangeEnd!;
        _rentalDuration = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      });
    }
  }

  bool _isUnavailableDate(DateTime day) {
    final formatted = DateFormat('yyyy-MM-dd').format(day);
    return _unavailableDates.contains(formatted);
  }

  Future<void> _submitRentalRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final totalAmount = _dailyRate * _rentalDuration;

      // Create rental transaction
      final transactionRef =
          await FirebaseFirestore.instance.collection('transactions').add({
        'sareeId': widget.saree['id'],
        'sareeName': widget.saree['name'] ?? 'Unknown',
        'sareeImage': widget.saree['imageUrl'] ?? '',
        'buyerId': user.uid,
        'buyerName': _nameController.text,
        'buyerPhone': _phoneController.text,
        'buyerAddress': _addressController.text,
        'sellerId': widget.saree['userId'] ?? '',
        'sellerName': widget.saree['userName'] ?? 'Anonymous',
        'type': TransactionType.rent
            .toString(), // Fix: Changed from string to enum toString()
        'status': TransactionStatus.pending.toString(),
        'amount': totalAmount,
        'startDate': _selectedStartDate,
        'endDate': _selectedEndDate,
        'rentalDuration': _rentalDuration,
        'dailyRate': _dailyRate,
        'paymentMethod': _selectedPaymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update saree status
      await FirebaseFirestore.instance
          .collection('sarees')
          .doc(widget.saree['id'])
          .update({
        'rentalStatus': 'pending',
        'lastTransactionId': transactionRef.id,
      });

      if (!mounted) return;

      // Navigate directly to transaction history screen
      Navigator.pushNamedAndRemoveUntil(
          context, '/transaction_history', (route) => route.isFirst);
    } catch (e) {
      print('Rental error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process rental request. Please try again.'),
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
          'Rent This Saree',
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
                              // Saree rental summary
                              _buildRentalSummary(),
                              SizedBox(height: 24.h),

                              // Calendar for date selection
                              Text(
                                'Select Rental Dates',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              SizedBox(height: 16.h),

                              _buildCalendar(),
                              SizedBox(height: 16.h),

                              // Selected date range display
                              Container(
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Start Date',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                DateFormat('MMM d, yyyy')
                                                    .format(_selectedStartDate),
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 40.h,
                                          width: 1,
                                          color: Colors.green.shade200,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsets.only(left: 16.w),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'End Date',
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  DateFormat('MMM d, yyyy')
                                                      .format(_selectedEndDate),
                                                  style: TextStyle(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.green.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Duration:',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          '$_rentalDuration days',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Amount:',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          '৳${(_dailyRate * _rentalDuration).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Renter information form
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
                                  onPressed:
                                      _isLoading ? null : _submitRentalRequest,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.amber.shade700,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    elevation: 3,
                                    shadowColor: Colors.amber.withOpacity(0.3),
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
                                            Icon(Icons.event_available_outlined,
                                                size: 20.r),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Submit Rental Request',
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

  Widget _buildRentalSummary() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saree image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              widget.saree['imageUrl'] ?? '',
              width: 80.w,
              height: 100.h,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80.w,
                  height: 100.h,
                  color: Colors.grey.shade300,
                  child: Icon(Icons.image_not_supported, size: 24.r),
                );
              },
            ),
          ),
          SizedBox(width: 16.w),

          // Saree details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.saree['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: Colors.green.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Type: ${widget.saree['type'] ?? 'Saree'}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Owner: ${widget.saree['userName'] ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Daily Rate: ৳${_dailyRate.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        child: TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          rangeSelectionMode: RangeSelectionMode.enforced,
          enabledDayPredicate: (day) {
            // Disable days that are unavailable for rental
            return !_isUnavailableDate(day);
          },
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: Colors.green.shade700,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: Colors.green.shade700,
            ),
            headerMargin: EdgeInsets.only(bottom: 16.h),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            // Add default text style with dark grey color
            defaultTextStyle: TextStyle(color: Colors.grey.shade800),
            weekendTextStyle: TextStyle(color: Colors.red.shade800),
            holidayTextStyle: TextStyle(color: Colors.red.shade800),
            todayDecoration: BoxDecoration(
              color: Colors.amber.shade200,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
            rangeStartDecoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
            rangeEndDecoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
            rangeHighlightColor: Colors.green.shade100,
            disabledTextStyle: TextStyle(
              color: Colors.grey.shade400,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          onRangeSelected: (start, end, focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
              _rangeStart = start;
              _rangeEnd = end;
              if (start != null && end != null) {
                _updateRentalDuration();
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    final List<Map<String, dynamic>> _paymentOptions = [
      {'name': 'bKash', 'icon': Icons.payment},
      {'name': 'Nagad', 'icon': Icons.account_balance_wallet_outlined},
      {'name': 'Rocket', 'icon': Icons.account_balance_wallet_outlined},
    ];

    return Row(
      children: _paymentOptions.map((method) {
        final bool isSelected = _selectedPaymentMethod == method['name'];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = method['name'];
                });
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color:
                      isSelected ? Colors.amber.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? Colors.amber.shade400
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      method['icon'],
                      color: isSelected
                          ? Colors.amber.shade700
                          : Colors.grey.shade600,
                      size: 24.r,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      method['name'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.amber.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
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

  Widget _buildRentalInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
