import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'saree_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;

  const ProfileScreen({super.key, required this.authService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  User? user = FirebaseAuth.instance.currentUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _postsCount = 0;
  bool _isLoadingPosts = true;

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
    _refreshUserData();
  }

  Future<void> _loadPostsCount() async {
    setState(() => _isLoadingPosts = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('sarees')
          .where('userId', isEqualTo: user?.uid)
          .get();

      if (mounted) {
        setState(() {
          _postsCount = querySnapshot.docs.length;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Error loading posts count: $e');
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  Future<void> _updateProfile(String? photoUrl, String? displayName) async {
    try {
      if (user == null) return;

      setState(() => _isLoading = true);

      // Try to update Firebase Auth first (direct approach)
      try {
        if (displayName != null && displayName.isNotEmpty) {
          await user!.updateDisplayName(displayName);
        }
        if (photoUrl != null && photoUrl.isNotEmpty) {
          await user!.updatePhotoURL(photoUrl);
        }

        // Force reload user data
        await user!.reload();
        setState(() {
          // Update the current user reference after reload
          user = FirebaseAuth.instance.currentUser;
        });
      } catch (authError) {
        print('Auth update error: $authError');
        // If direct update fails, we'll try fallback approach below
      }

      // Try to update Firestore as a secondary approach
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({
          'displayName': displayName ?? user!.displayName,
          'photoURL': photoUrl ?? user!.photoURL,
          'email': user!.email,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (firestoreError) {
        print('Firestore update error (non-critical): $firestoreError');
        // We can continue even if Firestore update fails, since we have Auth data
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      print('Profile update error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload to storage service
      final imageUrl = await _storageService.uploadImage(File(image.path));

      if (imageUrl.isEmpty) {
        throw Exception('Failed to get image URL after upload');
      }

      // Update profile with new image URL
      await _updateProfile(imageUrl, null);

      // Reload user state after update
      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });
    } catch (e) {
      print('Image upload error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    final currentName = user?.displayName ?? '';
    _nameController.text = currentName;

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          style: TextStyle(color: Colors.black87), // Set text color to black
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: Colors.green.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.green.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.green.shade400, width: 2),
            ),
            prefixIcon:
                Icon(Icons.person_outline, color: Colors.green.shade600),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = _nameController.text.trim();
              Navigator.pop(context);

              if (newName.isNotEmpty && newName != user?.displayName) {
                await _updateProfile(null, newName);
                // Immediately update UI with new name
                setState(() {
                  // We can update this immediately for better UX
                  if (user != null) {
                    // Create a temporary user with the new name
                    final tempDisplayName = newName;
                    // Force UI update with the new name while we wait for the backend
                    setState(() {});
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
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
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon:
                              Icon(Icons.edit, color: Colors.white, size: 24.r),
                          onPressed: _editProfile,
                        ),
                        IconButton(
                          icon: Icon(Icons.logout,
                              color: Colors.white, size: 24.r),
                          onPressed: () async {
                            try {
                              await widget.authService.signOut();
                              if (!mounted) return;
                              Navigator.pushReplacementNamed(context, '/login');
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to sign out'),
                                  backgroundColor: Colors.red.shade400,
                                ),
                              );
                            }
                          },
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
                            'Manage your saree collection and profile',
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

                  SizedBox(height: 20.h),

                  // Profile Header with Glass Effect
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          padding: EdgeInsets.all(20.r),
                          child: _buildProfileHeader(),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

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
                            child: RefreshIndicator(
                              onRefresh: () async {
                                await _refreshUserData();
                              },
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(20.r),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'My Collection',
                                            style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 6.h),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              _isLoadingPosts
                                                  ? 'Loading...'
                                                  : '$_postsCount Posts',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildPostsGrid(),
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

  Widget _buildProfileHeader() {
    final displayName = user?.displayName ?? 'Anonymous';
    final email = user?.email ?? '';
    final photoURL = user?.photoURL;

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  width: 100.r,
                  height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50.r),
                    child: photoURL != null
                        ? Image.network(
                            photoURL,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.white.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 50.r,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              );
                            },
                          )
                        : Icon(
                            Icons.person,
                            size: 50.r,
                            color: Colors.white.withOpacity(0.7),
                          ),
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 30.r,
                        height: 30.r,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 4.h,
                right: 4.w,
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.brown.shade800,
                    size: 16.r,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          displayName,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          email,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14.sp,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat(
                _isLoadingPosts ? '...' : _postsCount.toString(), 'Posts'),
            _buildDivider(),
            _buildStat('0', 'Followers'),
            _buildDivider(),
            _buildStat('0', 'Following'),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40.h,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sarees')
          .where('userId', isEqualTo: user?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(40.r),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(40.r),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.white.withOpacity(0.7),
                    size: 40.r,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Error loading posts',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(40.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.post_add,
                      size: 48.r,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Your saree collection will appear here',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/add-post');
                          },
                          icon: Icon(Icons.add, size: 20.r),
                          label: Text('Add Your First Post'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              return _buildPostCard(post);
            },
          ),
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SareeDetailScreen(saree: post),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                        ),
                        child: Image.network(
                          post['imageUrl'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withOpacity(0.1),
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white.withOpacity(0.5),
                                size: 30.r,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Details
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            post['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '৳${post['price']}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: BoxDecoration(
                                  color: post['isAvailable'] == true
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.red.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  post['isAvailable'] == true
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: post['isAvailable'] == true
                                      ? Colors.green.shade700
                                      : Colors.white.withOpacity(0.7),
                                  size: 16.r,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Future<void> _refreshUserData() async {
    try {
      // Try to get fresh data from Auth
      try {
        await FirebaseAuth.instance.currentUser?.reload();
        User? currentUser = FirebaseAuth.instance.currentUser;

        setState(() {
          user = currentUser;
        });
      } catch (authError) {
        print('Auth refresh error: $authError');
      }

      // Try to get Firestore data, but don't fail if not available
      try {
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

          // We only use this as supplementary data if available
          if (userDoc.exists) {
            print('Firestore user data found');
          }
        }
      } catch (firestoreError) {
        print('Firestore data fetch error (non-critical): $firestoreError');
        // Continue with Auth data only
      }

      // Reload posts count regardless
      await _loadPostsCount();
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
