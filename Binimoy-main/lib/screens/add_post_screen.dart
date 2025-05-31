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
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;
  String _selectedType = 'Jamdani';
  String _selectedCategory = 'RENT'; // Add category selection
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = Uuid();
  final _storageService = StorageService();

  double _uploadProgress = 0;
  bool _showProgress = false;

  final List<String> _sareeTypes = [
    'Jamdani',
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

  final List<String> _categories = ['RENT', 'SALE']; // Add categories list

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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
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

  Future<String> _uploadImage(File imageFile) async {
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
    } finally {
      setState(() => _showProgress = false);
    }
  }

  Future<void> _submitPost() async {
    // Validate form and image
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    // Check if price is a valid number
    double? price;
    try {
      price = double.parse(_priceController.text.trim());
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

    // Add a timeout to prevent infinite loading state
    Timer? timeoutTimer;
    timeoutTimer = Timer(Duration(seconds: 60), () {
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
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('Starting to upload saree post...');
      print('Image path: ${_imageFile!.path}');

      // Validate image file before uploading
      if (!await _imageFile!.exists() || await _imageFile!.length() == 0) {
        throw Exception('Invalid image file: File does not exist or is empty');
      }

      // Use new upload method
      final imageUrl = await _uploadImage(_imageFile!);

      // Save post data to Firestore
      print('Saving data to Firestore...');
      await FirebaseFirestore.instance.collection('sarees').add({
        'name': _nameController.text.trim(),
        'price': price,
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'category': _selectedCategory, // Add category to data
        'imageUrl': imageUrl,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
        'isAvailable': true,
      });

      print('Post saved to Firestore successfully');

      // Cancel the timeout timer
      timeoutTimer?.cancel();

      if (!mounted) return;

      // Reset loading state before navigating
      setState(() => _isLoading = false);

      // Show success message and pop screen
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saree posted successfully!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      // Cancel the timeout timer
      timeoutTimer?.cancel();

      print('Error posting saree: $e');
      if (!mounted) return;

      // Reset loading state
      setState(() => _isLoading = false);

      // Show error message with more details
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

                  // Category Selection Buttons (matching home screen style)
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
                                    // Image Picker with Glass Effect
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        height: 200.h,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20.r),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20.r),
                                          child: _imageFile != null
                                              ? Stack(
                                                  children: [
                                                    Image.file(
                                                      _imageFile!,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                                    // Dark overlay for better visibility
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.black
                                                                .withOpacity(
                                                                    0.3),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    // Change photo button
                                                    Positioned(
                                                      bottom: 12.h,
                                                      right: 12.w,
                                                      child: Container(
                                                        padding:
                                                            EdgeInsets.all(8.r),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20.r),
                                                        ),
                                                        child: Icon(
                                                          Icons.edit,
                                                          color: Colors.white,
                                                          size: 20.r,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                      sigmaX: 10, sigmaY: 10),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  20.r),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.1),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .add_photo_alternate,
                                                            size: 40.r,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        SizedBox(height: 16.h),
                                                        Text(
                                                          'Add Saree Photo',
                                                          style: TextStyle(
                                                            fontSize: 18.sp,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        SizedBox(height: 8.h),
                                                        Text(
                                                          'Tap to select from gallery',
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.7),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 24.h),

                                    // Form Fields
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

                                    // Saree Type Dropdown
                                    Container(
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
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: _selectedType,
                                              decoration: InputDecoration(
                                                labelText: 'Saree Type',
                                                labelStyle: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.category_outlined,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 16.h,
                                                  horizontal: 16.w,
                                                ),
                                              ),
                                              dropdownColor:
                                                  Colors.black.withOpacity(0.8),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15.sp,
                                              ),
                                              icon: Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                              ),
                                              items: _sareeTypes
                                                  .map((String type) {
                                                return DropdownMenuItem(
                                                  value: type,
                                                  child: Text(
                                                    type,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedType = newValue!;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16.h),

                                    _buildGlassTextField(
                                      controller: _priceController,
                                      labelText: 'Price',
                                      hintText: 'Enter price in BDT',
                                      prefixIcon:
                                          Icons.monetization_on_outlined,
                                      keyboardType: TextInputType.number,
                                      prefixText: '৳ ',
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Please enter a price'
                                              : null,
                                    ),
                                    SizedBox(height: 16.h),

                                    _buildGlassTextField(
                                      controller: _descriptionController,
                                      labelText: 'Description',
                                      hintText: 'Describe your saree...',
                                      prefixIcon: Icons.description_outlined,
                                      maxLines: 4,
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Please add a description'
                                              : null,
                                    ),
                                    SizedBox(height: 24.h),

                                    // Upload Progress
                                    if (_showProgress)
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
                  vertical: 16.h,
                  horizontal: 16.w,
                ),
                alignLabelWithHint: true,
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
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
