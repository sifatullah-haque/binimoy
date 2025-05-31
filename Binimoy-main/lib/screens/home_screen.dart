import 'package:binimoy/screens/chat.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/auth_service.dart';
import 'saree_detail_screen.dart';
import 'add_post_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;

  const HomeScreen({super.key, required this.authService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedCategory = 'RENT';
  final List<String> _categories = [
    'RENT',
    'SALE'
  ]; // Updated to match add post screen

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

  void _handleSignOut() async {
    try {
      setState(() => _isLoading = true);
      await widget.authService.signOut();
      setState(() => _isLoading = false);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } on SocketException catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Network error: Please check your internet connection')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
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
            child: Column(
              children: [
                // Header with search and notification
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Text(
                        'Binimoy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24.sp,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon:
                            Icon(Icons.search, color: Colors.white, size: 24.r),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SearchScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 24.r),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TransactionHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Welcome message and RENT/SALE buttons
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Column(
                    children: [
                      Text(
                        'RENT | SELL | SWAP | REPEAT',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = 'RENT';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
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
                                    fontSize: 14.sp,
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
                                padding: EdgeInsets.symmetric(vertical: 8.h),
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
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),

                        // New Arrivals Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              Text(
                                'New Arrivals',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'See All',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // New Arrivals Horizontal List with Category Filter
                        SizedBox(
                          height: 180.h,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('sarees')
                                .orderBy('createdAt', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final allSarees = snapshot.data?.docs ?? [];

                              // Filter by category if the saree has a category field, otherwise show all
                              final sarees = allSarees.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final category = data['category'];
                                // If no category field exists (old data), show it
                                // If category exists, filter by selected category
                                return category == null ||
                                    category == _selectedCategory;
                              }).toList();

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemCount: sarees.length,
                                itemBuilder: (context, index) {
                                  final saree = {
                                    ...sarees[index].data()
                                        as Map<String, dynamic>,
                                    'id': sarees[index].id,
                                  };

                                  return Container(
                                    width: 130.w,
                                    margin: EdgeInsets.only(right: 12.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16.r),
                                            topRight: Radius.circular(16.r),
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: 1.1,
                                            child: Image.network(
                                              saree['imageUrl'] ?? '',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade200,
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey.shade400,
                                                    size: 30.r,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.r),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                saree['name'] ?? 'Unknown',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11.sp,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 3.h),
                                              Text(
                                                '৳${saree['price'] ?? 0}',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Best Deals Section with Category Filter
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              Text(
                                'Best Deals',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'See All',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Best Deals Horizontal List with Category Filter
                        SizedBox(
                          height: 180.h,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('sarees')
                                .orderBy('createdAt', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final allSarees = snapshot.data?.docs ?? [];

                              // Filter by category if the saree has a category field, otherwise show all
                              final sarees = allSarees.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final category = data['category'];
                                return category == null ||
                                    category == _selectedCategory;
                              }).toList();

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemCount: sarees.length,
                                itemBuilder: (context, index) {
                                  final saree = {
                                    ...sarees[index].data()
                                        as Map<String, dynamic>,
                                    'id': sarees[index].id,
                                  };

                                  return Container(
                                    width: 130.w,
                                    margin: EdgeInsets.only(right: 12.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(16.r),
                                                topRight: Radius.circular(16.r),
                                              ),
                                              child: AspectRatio(
                                                aspectRatio: 1.1,
                                                child: Image.network(
                                                  saree['imageUrl'] ?? '',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors
                                                            .grey.shade400,
                                                        size: 30.r,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8.r),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    saree['name'] ?? 'Unknown',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11.sp,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 3.h),
                                                  Text(
                                                    '৳${saree['price'] ?? 0}',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Deal badge
                                        Positioned(
                                          top: 6.h,
                                          right: 6.w,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              'DEAL',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 7.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Premium Collection Section with Category Filter
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              Text(
                                'Premium Collection',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'See All',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Premium Collection with Category Filter
                        SizedBox(
                          height: 180.h,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('sarees')
                                .where('price', isGreaterThan: 2000)
                                .orderBy('price', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final allSarees = snapshot.data?.docs ?? [];

                              // Filter by category if the saree has a category field, otherwise show all
                              final sarees = allSarees.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final category = data['category'];
                                return category == null ||
                                    category == _selectedCategory;
                              }).toList();

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemCount: sarees.length,
                                itemBuilder: (context, index) {
                                  final saree = {
                                    ...sarees[index].data()
                                        as Map<String, dynamic>,
                                    'id': sarees[index].id,
                                  };

                                  return Container(
                                    width: 130.w,
                                    margin: EdgeInsets.only(right: 12.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(16.r),
                                                topRight: Radius.circular(16.r),
                                              ),
                                              child: AspectRatio(
                                                aspectRatio: 1.1,
                                                child: Image.network(
                                                  saree['imageUrl'] ?? '',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors
                                                            .grey.shade400,
                                                        size: 30.r,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8.r),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    saree['name'] ?? 'Unknown',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11.sp,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 3.h),
                                                  Text(
                                                    '৳${saree['price'] ?? 0}',
                                                    style: TextStyle(
                                                      color: Colors.amber,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Premium badge
                                        Positioned(
                                          top: 6.h,
                                          right: 6.w,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: Colors.amber,
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              'PREMIUM',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 7.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 100.h), // Space for bottom navigation
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: null,
      bottomNavigationBar: ClipRRect(
        // borderRadius: BorderRadius.only(
        //   topLeft: Radius.circular(25.r),
        //   topRight: Radius.circular(25.r),
        // ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              // borderRadius: BorderRadius.only(
              //   topLeft: Radius.circular(25.r),
              //   topRight: Radius.circular(25.r),
              // ),
              border: Border.all(
                color: Colors.brown.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Container(
              height: 80.h,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 0,
                    isSelected: _selectedIndex == 0,
                  ),
                  _buildNavItem(
                    icon: Icons.add_circle_outline,
                    label: 'List',
                    index: 1,
                    isSelected: _selectedIndex == 1,
                  ),
                  _buildNavItem(
                    icon: Icons.shopping_bag,
                    label: 'Rentals',
                    index: 2,
                    isSelected: _selectedIndex == 2,
                  ),
                  _buildNavItem(
                    icon: Icons.person,
                    label: 'Profile',
                    index: 3,
                    isSelected: _selectedIndex == 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Chat()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProfileScreen(authService: widget.authService),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.r,
              // color: isSelected
              //     ? Colors.brown.shade200
              //     : Colors.white.withOpacity(0.7),
              color: Colors.white.withOpacity(0.7),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                // color: isSelected
                //     ? Colors.brown.shade200
                //     : Colors.white.withOpacity(0.7),
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
