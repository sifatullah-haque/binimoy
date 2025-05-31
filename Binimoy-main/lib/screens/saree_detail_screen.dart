import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../widgets/rental_calendar.dart';
import '../widgets/review_dialog.dart';
import '../screens/chat_screen.dart';
import '../screens/buy_saree_screen.dart';
import '../screens/rent_saree_screen.dart';
import '../screens/swap_saree_screen.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String targetId;
  final String targetType;
  final int rating;
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
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

enum TransactionType { buy, rent, swap }

enum TransactionStatus { pending, approved, rejected }

class SareeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> saree;

  const SareeDetailScreen({
    super.key,
    required this.saree,
  });

  @override
  State<SareeDetailScreen> createState() => _SareeDetailScreenState();
}

class _SareeDetailScreenState extends State<SareeDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  // Image type definitions matching add post screen
  final Map<String, String> _imageTypes = {
    'anchol': 'আঁচল (Anchol)',
    'par': 'পাড় (Par)',
    'jomin': 'জমিন (Jomin)',
    'kuchi': 'কুচি (Kuchi)',
  };

  // Helper method to get all available images
  List<MapEntry<String, String>> _getAvailableImages() {
    final images = widget.saree['images'] as Map<String, dynamic>? ?? {};
    return _imageTypes.entries
        .where((entry) =>
            images[entry.key] != null &&
            images[entry.key].toString().isNotEmpty)
        .map((entry) => MapEntry(images[entry.key].toString(), entry.value))
        .toList();
  }

  // Helper method to get display image URL for main image
  String _getDisplayImageUrl() {
    final availableImages = _getAvailableImages();
    return availableImages.isNotEmpty ? availableImages.first.key : '';
  }

  // Helper method to format price display
  String _getDisplayPrice() {
    final category = widget.saree['category'] ?? 'SALE';
    final basePrice = widget.saree['basePrice'] ?? widget.saree['price'] ?? 0;

    if (category == 'RENT') {
      return '৳${basePrice}/day';
    } else {
      return '৳${basePrice}';
    }
  }

  // Helper method to get rental details
  Map<String, dynamic> _getRentalDetails() {
    final category = widget.saree['category'] ?? 'SALE';
    if (category != 'RENT') return {};

    final basePrice = widget.saree['basePrice'] ?? 0.0;
    final rentalDays = widget.saree['rentalDays'] ?? 0;
    final totalRentalPrice =
        widget.saree['totalRentalPrice'] ?? (basePrice * rentalDays);
    final serviceCharge =
        widget.saree['serviceCharge'] ?? (totalRentalPrice * 0.20);
    final totalPrice =
        widget.saree['totalPrice'] ?? (totalRentalPrice + serviceCharge);

    return {
      'basePrice': basePrice,
      'rentalDays': rentalDays,
      'totalRentalPrice': totalRentalPrice,
      'serviceCharge': serviceCharge,
      'totalPrice': totalPrice,
      'startDate': widget.saree['startDate'],
      'endDate': widget.saree['endDate'],
    };
  }

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
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableImages = _getAvailableImages();
    final rentalDetails = _getRentalDetails();

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
                                'Saree Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.favorite_border,
                                      color: Colors.white, size: 20.r),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Added to favorites')),
                                  );
                                },
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.share,
                                      color: Colors.white, size: 20.r),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Share functionality')),
                                  );
                                },
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image Gallery Section
                                    _buildImageGallery(availableImages),
                                    SizedBox(height: 20.h),

                                    // Saree Basic Info
                                    _buildBasicInfo(),
                                    SizedBox(height: 20.h),

                                    // Price Information
                                    _buildPriceInformation(rentalDetails),
                                    SizedBox(height: 20.h),

                                    // Detailed Information
                                    _buildDetailedInfo(),
                                    SizedBox(height: 20.h),

                                    // Rental Calendar (if rent)
                                    if (widget.saree['category'] == 'RENT' &&
                                        rentalDetails.isNotEmpty) ...[
                                      _buildRentalCalendar(rentalDetails),
                                      SizedBox(height: 20.h),
                                    ],

                                    // Seller Information
                                    _buildSellerInfo(),
                                    SizedBox(height: 20.h),

                                    // Action Buttons
                                    _buildActionButtons(),
                                    SizedBox(height: 20.h),

                                    // Reviews Section
                                    _buildReviewsSection(),
                                  ],
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

  Widget _buildImageGallery(List<MapEntry<String, String>> availableImages) {
    if (availableImages.isEmpty) {
      return Container(
        height: 300.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported,
                  size: 50.r, color: Colors.white.withOpacity(0.5)),
              SizedBox(height: 8.h),
              Text(
                'No images available',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Main Image Display
        Container(
          height: 300.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border:
                Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _imagePageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: availableImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Image.network(
                          availableImages[index].key,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child:
                                  Icon(Icons.image_not_supported, size: 50.r),
                            );
                          },
                        ),
                        // Image type label
                        Positioned(
                          bottom: 16.h,
                          left: 16.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              availableImages[index].value,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Category badge
                Positioned(
                  top: 16.h,
                  right: 16.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: widget.saree['category'] == 'RENT'
                          ? Colors.blue.withOpacity(0.9)
                          : Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      widget.saree['category'] ?? 'SALE',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Navigation arrows
                if (availableImages.length > 1) ...[
                  Positioned(
                    left: 8.w,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          if (_currentImageIndex > 0) {
                            _imagePageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chevron_left,
                              color: Colors.white, size: 20.r),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8.w,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          if (_currentImageIndex < availableImages.length - 1) {
                            _imagePageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chevron_right,
                              color: Colors.white, size: 20.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Image Thumbnails
        if (availableImages.length > 1) ...[
          SizedBox(
            height: 60.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableImages.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    _imagePageController.animateToPage(
                      index,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 60.w,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        availableImages[index].key,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: Icon(Icons.image_not_supported, size: 20.r),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Page indicator
        if (availableImages.length > 1) ...[
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(availableImages.length, (index) {
              return Container(
                width: 8.w,
                height: 8.h,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentImageIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildBasicInfo() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.saree['name'] ?? 'Unknown Saree',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        widget.saree['type'] ?? 'Saree',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getDisplayPrice(),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.saree['category'] == 'RENT' &&
                      widget.saree['rentalDays'] != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      '${widget.saree['rentalDays']} days',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInformation(Map<String, dynamic> rentalDetails) {
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
              Icon(Icons.monetization_on_outlined,
                  color: Colors.white, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Pricing Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (widget.saree['category'] == 'RENT' &&
              rentalDetails.isNotEmpty) ...[
            _buildPriceRow('Price per Day:',
                '৳ ${rentalDetails['basePrice']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildPriceRow(
                'Rental Days:', '${rentalDetails['rentalDays'] ?? 0} days'),
            _buildPriceRow('Subtotal:',
                '৳ ${rentalDetails['totalRentalPrice']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildPriceRow('Service Charge (20%):',
                '৳ ${rentalDetails['serviceCharge']?.toStringAsFixed(2) ?? '0.00'}'),
            Divider(color: Colors.white.withOpacity(0.3), height: 24.h),
            _buildPriceRow('Total Amount:',
                '৳ ${rentalDetails['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                isTotal: true),
          ] else ...[
            _buildPriceRow('Base Price:',
                '৳ ${(widget.saree['basePrice'] ?? widget.saree['price'] ?? 0).toStringAsFixed(2)}'),
            _buildPriceRow('Service Charge (20%):',
                '৳ ${(widget.saree['serviceCharge'] ?? 0).toStringAsFixed(2)}'),
            Divider(color: Colors.white.withOpacity(0.3), height: 24.h),
            _buildPriceRow('Total Amount:',
                '৳ ${(widget.saree['totalPrice'] ?? widget.saree['price'] ?? 0).toStringAsFixed(2)}',
                isTotal: true),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
    final details = [
      if (widget.saree['color'] != null) {'Color': widget.saree['color']},
      if (widget.saree['fabric'] != null) {'Fabric': widget.saree['fabric']},
      if (widget.saree['brand'] != null) {'Brand': widget.saree['brand']},
    ];

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
              Icon(Icons.info_outline, color: Colors.white, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Saree Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...details
              .map((detail) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child:
                        _buildDetailRow(detail.keys.first, detail.values.first),
                  ))
              .toList(),
          SizedBox(height: 12.h),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.saree['description'] ?? 'No description available',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCalendar(Map<String, dynamic> rentalDetails) {
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
              Icon(Icons.calendar_today, color: Colors.white, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Rental Period',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        rentalDetails['startDate'] != null
                            ? '${(rentalDetails['startDate'] as Timestamp).toDate().day}/${(rentalDetails['startDate'] as Timestamp).toDate().month}/${(rentalDetails['startDate'] as Timestamp).toDate().year}'
                            : 'Not specified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        rentalDetails['endDate'] != null
                            ? '${(rentalDetails['endDate'] as Timestamp).toDate().day}/${(rentalDetails['endDate'] as Timestamp).toDate().month}/${(rentalDetails['endDate'] as Timestamp).toDate().year}'
                            : 'Not specified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
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
              Icon(Icons.person_outline, color: Colors.white, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Seller Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  size: 20.r,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.saree['userName'] ?? 'Anonymous',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Verified Seller',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Contact seller button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: widget.saree['userId'],
                        receiverName: widget.saree['userName'],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          color: Colors.white, size: 16.r),
                      SizedBox(width: 6.w),
                      Text(
                        'Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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
              Icon(Icons.local_offer_outlined, color: Colors.white, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Purchase Options',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildActionButton(
                title: 'Buy',
                icon: Icons.shopping_bag_outlined,
                color: Colors.green.shade300,
                onTap: _handleBuy,
              ),
              SizedBox(width: 12.w),
              _buildActionButton(
                title: 'Rent',
                icon: Icons.event_available_outlined,
                color: Colors.amber.shade300,
                onTap: _handleRent,
              ),
              SizedBox(width: 12.w),
              _buildActionButton(
                title: 'Swap',
                icon: Icons.swap_horiz,
                color: Colors.blue.shade300,
                onTap: _handleSwap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('targetId', isEqualTo: widget.saree['id'])
          .where('targetType', isEqualTo: 'saree')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final reviews = snapshot.data?.docs ?? [];

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rate_review_outlined,
                          color: Colors.white, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (context) => ReviewDialog(
                          targetId: widget.saree['id'],
                          targetType: 'saree',
                        ),
                      );
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Review submitted successfully')),
                        );
                      }
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review,
                              size: 14.r, color: Colors.white),
                          SizedBox(width: 4.w),
                          Text(
                            'Add Review',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              if (reviews.isEmpty)
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 40.r, color: Colors.white.withOpacity(0.5)),
                        SizedBox(height: 12.h),
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Be the first to leave a review',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final review = Review.fromMap(
                      reviews[index].data() as Map<String, dynamic>,
                      reviews[index].id,
                    );

                    return Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16.r,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  review.userName.isNotEmpty
                                      ? review.userName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < review.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16.r,
                                  );
                                }),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            review.comment,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20.r),
              SizedBox(height: 6.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBuy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to make a purchase')),
      );
      return;
    }

    if (user.uid == widget.saree['userId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot buy your own saree')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuySareeScreen(saree: widget.saree),
      ),
    );
  }

  Future<void> _handleRent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to rent')),
      );
      return;
    }

    if (user.uid == widget.saree['userId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot rent your own saree')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentSareeScreen(saree: widget.saree),
      ),
    );
  }

  Future<void> _handleSwap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to swap')),
      );
      return;
    }

    if (user.uid == widget.saree['userId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot swap your own saree')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SwapSaree(saree: widget.saree),
      ),
    );
  }
}
