import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../services/storage_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  // Multiple image files for mandatory pictures
  File? _ancholImage; // আঁচল
  File? _parImage; // পাড়
  File? _jominImage; // জমিন
  File? _kuchiImage; // কুচি

  // Date controllers for rent
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;
  String _selectedType = 'Jamdani';
  String _selectedCategory = 'RENT';
  String _selectedColor = 'Red';
  String _selectedFabric = 'Cotton';
  String _selectedBrand = 'Aarong';
  // Remove rental percentage variable

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isDisposed = false;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = Uuid();
  final _storageService = StorageService();

  double _uploadProgress = 0;
  bool _showProgress = false;

  final List<String> _sareeTypes = [
    'Jamdani',
    'Katan',
    'Banarasi',
    'Silk',
    'Dola Silk',
    'Georgette',
    'Chiffon',
    'Leheriya',
    'Kanjeevaram',
    'Net',
    'Tussar Silk'
  ];

  final List<String> _colors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Purple',
    'Pink',
    'Orange',
    'Black',
    'White',
    'Gray',
    'Brown',
    'Maroon',
    'Navy',
    'Gold',
    'Silver'
  ];

  final List<String> _fabrics = [
    'Cotton',
    'Gel',
    'Silk',
    'Georgette',
    'Chiffon',
    'Net',
    'Tussar'
  ];

  final List<String> _brands = [
    'Aarong',
    'Khut',
    'Kay Kraft',
    'Le Reve',
    'Jotey',
    'Anjans',
    'Rang',
    'Yellow',
    'Daraz',
    'Deshal',
    'Local',
    'Others'
  ];

  final List<String> _categories = ['RENT', 'SALE'];

  // Image type definitions
  final Map<String, String> _imageTypes = {
    'anchol': 'আঁচল (Anchol)',
    'par': 'পাড় (Par)',
    'jomin': 'জমিন (Jomin)',
    'kuchi': 'কুচি (Kuchi)',
  };

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

    if (!_isDisposed && mounted) {
      _animationController.forward();
    }

    // Listen to retail price changes for automatic calculation
    _retailPriceController.addListener(_calculateRentalPrice);
  }

  void _calculateRentalPrice() {
    // This will trigger UI updates when retail price changes
    setState(() {});
  }

  // Modified pricing calculations for day-wise rental
  double get _basePrice {
    try {
      return double.parse(_retailPriceController.text.trim());
    } catch (e) {
      return 0.0;
    }
  }

  int get _rentalDays {
    if (_selectedCategory == 'RENT' && _startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 0;
  }

  double get _totalRentalPrice {
    if (_selectedCategory == 'RENT') {
      return _basePrice * _rentalDays;
    }
    return _basePrice;
  }

  double get _serviceCharge {
    if (_selectedCategory == 'RENT') {
      return _totalRentalPrice * 0.20; // 20% service charge on total rental
    }
    return _basePrice * 0.20; // 20% service charge for sale
  }

  double get _totalPrice {
    if (_selectedCategory == 'RENT') {
      return _totalRentalPrice + _serviceCharge;
    }
    return _basePrice + _serviceCharge;
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          switch (imageType) {
            case 'anchol':
              _ancholImage = File(pickedFile.path);
              break;
            case 'par':
              _parImage = File(pickedFile.path);
              break;
            case 'jomin':
              _jominImage = File(pickedFile.path);
              break;
            case 'kuchi':
              _kuchiImage = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<String> _uploadImage(File imageFile, String imageType) async {
    try {
      return await _storageService.uploadImage(
        imageFile,
        onProgress: (progress) {
          setState(() {
            _showProgress = true;
            _uploadProgress = progress;
          });
        },
      );
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<void> _submitPost() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate dates for rent category
    if (_selectedCategory == 'RENT' &&
        (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select start and end dates for rental'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    // Validate all mandatory images
    if (_ancholImage == null ||
        _parImage == null ||
        _jominImage == null ||
        _kuchiImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload all 4 mandatory pictures'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    // Check if price is valid
    double? basePrice;
    try {
      basePrice = double.parse(_retailPriceController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    Timer? timeoutTimer;
    timeoutTimer = Timer(Duration(seconds: 120), () {
      if (_isLoading && mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request timed out. Please try again.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Upload all images
      final ancholUrl = await _uploadImage(_ancholImage!, 'anchol');
      final parUrl = await _uploadImage(_parImage!, 'par');
      final jominUrl = await _uploadImage(_jominImage!, 'jomin');
      final kuchiUrl = await _uploadImage(_kuchiImage!, 'kuchi');

      // Save post data to Firestore
      Map<String, dynamic> postData = {
        'name': _nameController.text.trim(),
        'basePrice': basePrice,
        'serviceCharge': _serviceCharge,
        'totalPrice': _totalPrice,
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'color': _selectedColor,
        'fabric': _selectedFabric,
        'brand': _selectedBrand,
        'category': _selectedCategory,
        'images': {
          'anchol': ancholUrl,
          'par': parUrl,
          'jomin': jominUrl,
          'kuchi': kuchiUrl,
        },
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
        'isAvailable': true,
      };

      // Add rental-specific fields
      if (_selectedCategory == 'RENT') {
        postData.addAll({
          'startDate': Timestamp.fromDate(_startDate!),
          'endDate': Timestamp.fromDate(_endDate!),
          'rentalDays': _rentalDays,
          'totalRentalPrice': _totalRentalPrice,
        });
      }

      await FirebaseFirestore.instance.collection('sarees').add(postData);

      timeoutTimer?.cancel();

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saree posted successfully!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      timeoutTimer?.cancel();
      print('Error posting saree: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString().split('\n')[0]}'),
          backgroundColor: Colors.red.shade400,
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: _submitPost,
          ),
        ),
      );
    } finally {
      setState(() => _showProgress = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ??
              _startDate?.add(Duration(days: 1)) ??
              DateTime.now().add(Duration(days: 1))),
      firstDate: isStartDate ? DateTime.now() : (_startDate ?? DateTime.now()),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Colors.black.withOpacity(0.8),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
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
                  // Custom App Bar
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: Colors.white, size: 24.r),
                          onPressed: () => Navigator.pop(context),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Add New Saree',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Subtitle
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Share your beautiful saree with the community',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category Selection Buttons
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = 'RENT';
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: _selectedCategory == 'RENT'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'RENT',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedCategory == 'RENT'
                                      ? Colors.brown.shade800
                                      : Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = 'SALE';
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: _selectedCategory == 'SALE'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'SALE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedCategory == 'SALE'
                                      ? Colors.brown.shade800
                                      : Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Content with Glass Effect
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
                              padding: EdgeInsets.all(20.r),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Mandatory Pictures Section
                                    Text(
                                      '4 Mandatory Standard Pictures',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),

                                    // Image Grid
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12.w,
                                        mainAxisSpacing: 12.h,
                                        childAspectRatio: 1.1,
                                      ),
                                      itemCount: _imageTypes.length,
                                      itemBuilder: (context, index) {
                                        String key =
                                            _imageTypes.keys.elementAt(index);
                                        String label = _imageTypes[key]!;
                                        File? imageFile;

                                        switch (key) {
                                          case 'anchol':
                                            imageFile = _ancholImage;
                                            break;
                                          case 'par':
                                            imageFile = _parImage;
                                            break;
                                          case 'jomin':
                                            imageFile = _jominImage;
                                            break;
                                          case 'kuchi':
                                            imageFile = _kuchiImage;
                                            break;
                                        }

                                        return _buildImagePicker(
                                            key, label, imageFile);
                                      },
                                    ),
                                    SizedBox(height: 24.h),

                                    // Basic Information
                                    Text(
                                      'Basic Information',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),

                                    _buildGlassTextField(
                                      controller: _nameController,
                                      labelText: 'Saree Name',
                                      hintText: 'Enter saree name',
                                      prefixIcon: Icons.label_outline,
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Please enter a name'
                                              : null,
                                    ),
                                    SizedBox(height: 16.h),

                                    // Row for Type and Color
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildGlassDropdown(
                                            value: _selectedType,
                                            labelText: 'Saree Type',
                                            items: _sareeTypes,
                                            prefixIcon: Icons.category_outlined,
                                            onChanged: (value) => setState(
                                                () => _selectedType = value!),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: _buildGlassDropdown(
                                            value: _selectedColor,
                                            labelText: 'Color',
                                            items: _colors,
                                            prefixIcon: Icons.palette_outlined,
                                            onChanged: (value) => setState(
                                                () => _selectedColor = value!),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    // Row for Fabric and Brand
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildGlassDropdown(
                                            value: _selectedFabric,
                                            labelText: 'Fabric',
                                            items: _fabrics,
                                            prefixIcon: Icons.texture_outlined,
                                            onChanged: (value) => setState(
                                                () => _selectedFabric = value!),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: _buildGlassDropdown(
                                            value: _selectedBrand,
                                            labelText: 'Brand',
                                            items: _brands,
                                            prefixIcon: Icons.business_outlined,
                                            onChanged: (value) => setState(
                                                () => _selectedBrand = value!),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    // Pricing Section
                                    Text(
                                      'Pricing Information',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),

                                    _buildGlassTextField(
                                      controller: _retailPriceController,
                                      labelText: _selectedCategory == 'RENT'
                                          ? 'Price per Day'
                                          : 'Price',
                                      hintText: _selectedCategory == 'RENT'
                                          ? 'Enter daily rental price in BDT'
                                          : 'Enter price in BDT',
                                      prefixIcon:
                                          Icons.monetization_on_outlined,
                                      keyboardType: TextInputType.number,
                                      prefixText: '৳ ',
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Please enter a price'
                                              : null,
                                    ),
                                    SizedBox(height: 8.h),

                                    // Service charge info text
                                    Padding(
                                      padding: EdgeInsets.only(left: 16.w),
                                      child: Text(
                                        _selectedCategory == 'RENT'
                                            ? '20% extra will be added as service charge on total rental amount'
                                            : '20% extra price will be added as service charge',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12.sp,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16.h),

                                    // Date Selection for Rent
                                    if (_selectedCategory == 'RENT') ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _selectDate(context, true),
                                              child: Container(
                                                padding: EdgeInsets.all(16.r),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16.r),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      size: 20.r,
                                                    ),
                                                    SizedBox(width: 12.w),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Start Date',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.9),
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          SizedBox(height: 4.h),
                                                          Text(
                                                            _startDate != null
                                                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                                                : 'Select date',
                                                            style: TextStyle(
                                                              color: _startDate !=
                                                                      null
                                                                  ? Colors.white
                                                                  : Colors.white
                                                                      .withOpacity(
                                                                          0.5),
                                                              fontSize: 14.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _selectDate(context, false),
                                              child: Container(
                                                padding: EdgeInsets.all(16.r),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16.r),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      size: 20.r,
                                                    ),
                                                    SizedBox(width: 12.w),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'End Date',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.9),
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          SizedBox(height: 4.h),
                                                          Text(
                                                            _endDate != null
                                                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                                                : 'Select date',
                                                            style: TextStyle(
                                                              color: _endDate !=
                                                                      null
                                                                  ? Colors.white
                                                                  : Colors.white
                                                                      .withOpacity(
                                                                          0.5),
                                                              fontSize: 14.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16.h),
                                    ],

                                    // Price Calculation Display
                                    if (_retailPriceController
                                        .text.isNotEmpty) ...[
                                      Container(
                                        padding: EdgeInsets.all(16.r),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(16.r),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            if (_selectedCategory ==
                                                'RENT') ...[
                                              _buildPriceRow('Price per Day:',
                                                  '৳ ${_basePrice.toStringAsFixed(2)}'),
                                              if (_rentalDays > 0) ...[
                                                _buildPriceRow('Rental Days:',
                                                    '${_rentalDays} days'),
                                                _buildPriceRow('Subtotal:',
                                                    '৳ ${_totalRentalPrice.toStringAsFixed(2)}'),
                                              ],
                                            ] else ...[
                                              _buildPriceRow('Base Price:',
                                                  '৳ ${_basePrice.toStringAsFixed(2)}'),
                                            ],
                                            _buildPriceRow(
                                                'Service Charge (20%):',
                                                '৳ ${_serviceCharge.toStringAsFixed(2)}'),
                                            Divider(
                                                color: Colors.white
                                                    .withOpacity(0.3)),
                                            _buildPriceRow('Total Amount:',
                                                '৳ ${_totalPrice.toStringAsFixed(2)}',
                                                isTotal: true),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                    ],

                                    _buildGlassTextField(
                                      controller: _descriptionController,
                                      labelText: 'Description',
                                      hintText:
                                          'Describe your saree in detail...',
                                      prefixIcon: Icons.description_outlined,
                                      maxLines: 4,
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Please add a description'
                                              : null,
                                    ),
                                    SizedBox(height: 24.h),

                                    // Upload Progress
                                    if (_showProgress) ...[
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12.h),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              child: LinearProgressIndicator(
                                                value: _uploadProgress,
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.2),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white,
                                                ),
                                                minHeight: 6.h,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Submit Button
                                    Container(
                                      width: double.infinity,
                                      height: 56.h,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 10, sigmaY: 10),
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading ? null : _submitPost,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.white.withOpacity(0.2),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
                                                side: BorderSide(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                            child: _isLoading
                                                ? SizedBox(
                                                    height: 24.r,
                                                    width: 24.r,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.publish,
                                                          size: 20.r),
                                                      SizedBox(width: 8.w),
                                                      Text(
                                                        'Post Saree',
                                                        style: TextStyle(
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
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

  Widget _buildImagePicker(String imageType, String label, File? imageFile) {
    return GestureDetector(
      onTap: () => _pickImage(imageType),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: imageFile != null
              ? Stack(
                  children: [
                    Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8.h,
                      left: 8.w,
                      right: 8.w,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16.r,
                        ),
                      ),
                    ),
                  ],
                )
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 24.r,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        SizedBox(height: 8.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String value,
    required String labelText,
    required List<String> items,
    required IconData prefixIcon,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  prefixIcon,
                  color: Colors.white.withOpacity(0.8),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20.h,
                  horizontal: 16.w,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              dropdownColor: Colors.black.withOpacity(0.8),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white.withOpacity(0.8),
              ),
              isExpanded: true, // This ensures the dropdown takes full width
              items: items.map((String item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              selectedItemBuilder: (BuildContext context) {
                return items.map((String item) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    },
                  );
                }).toList();
              },
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
    String? prefixText,
    TextInputType? keyboardType,
    int? maxLines,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
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
                ),
                prefixText: prefixText,
                prefixStyle: prefixText != null
                    ? TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20.h,
                  horizontal: 16.w,
                ),
                alignLabelWithHint: true,
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

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _retailPriceController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
