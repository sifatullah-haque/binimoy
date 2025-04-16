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
  String _selectedType = 'Jamdani'; // Default value
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = Uuid();
  final _storageService = StorageService();

  // Upload progress tracking
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
          'Add New Saree',
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
                // Page title and description
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Share your beautiful saree with others',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                        padding: EdgeInsets.all(20.r),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image picker
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 180.h,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _imageFile != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16.r),
                                          child: Image.file(
                                            _imageFile!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              size: 50.r,
                                              color: Colors.green.shade600,
                                            ),
                                            SizedBox(height: 12.h),
                                            Text(
                                              'Add Saree Photo',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Text(
                                              'Tap to select from gallery',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Saree name field
                              _buildTextField(
                                controller: _nameController,
                                labelText: 'Saree Name',
                                hintText: 'Enter saree name',
                                prefixIcon: Icons.label_outline,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Please enter a name'
                                    : null,
                              ),
                              SizedBox(height: 16.h),

                              // Saree type dropdown - Improved for better visibility
                              Container(
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
                                child: DropdownButtonFormField<String>(
                                  value: _selectedType,
                                  decoration: InputDecoration(
                                    labelText: 'Saree Type',
                                    labelStyle: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.category_outlined,
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
                                  ),
                                  items: _sareeTypes.map((String type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedType = newValue!;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.arrow_drop_down_circle,
                                    color: Colors.green.shade700,
                                  ),
                                  dropdownColor: Colors.white,
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 15.sp,
                                  ),
                                  isExpanded: true,
                                  menuMaxHeight: 300.h,
                                  elevation: 8,
                                  focusColor: Colors.transparent,
                                  iconSize: 26.r,
                                ),
                              ),
                              SizedBox(height: 16.h),

                              // Price field
                              _buildTextField(
                                controller: _priceController,
                                labelText: 'Price',
                                hintText: 'Enter price in BDT',
                                prefixIcon: Icons.monetization_on_outlined,
                                keyboardType: TextInputType.number,
                                prefixText: '৳ ',
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Please enter a price'
                                    : null,
                              ),
                              SizedBox(height: 16.h),

                              // Description field
                              Container(
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
                                  controller: _descriptionController,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15.sp,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    labelStyle: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: 'Describe your saree...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.description_outlined,
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
                                    alignLabelWithHint: true,
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide(
                                        color: Colors.green.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  maxLines: 4,
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Please add a description'
                                      : null,
                                ),
                              ),
                              SizedBox(height: 32.h),

                              // Upload progress indicator
                              if (_showProgress)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Uploading image: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      LinearProgressIndicator(
                                        value: _uploadProgress,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Submit button
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: double.infinity,
                                height: 55.h,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitPost,
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
                                            Icon(Icons.add_circle_outline,
                                                size: 20.r),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Post Saree',
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

  // Helper method to build text fields with consistent styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    String? prefixText,
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
          prefixText: prefixText,
          prefixStyle: prefixText != null
              ? TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                )
              : null,
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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
