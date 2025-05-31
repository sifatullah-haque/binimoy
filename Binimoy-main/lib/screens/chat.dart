import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Dummy chat data
  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Arif Rahman',
      'message': 'Is the red saree still available?',
      'time': '10:30 AM',
      'image': 'https://randomuser.me/api/portraits/men/32.jpg',
      'unread': 2,
    },
    {
      'name': 'Nusrat Jahan',
      'message': 'Thank you for the quick delivery!',
      'time': 'Yesterday',
      'image': 'https://randomuser.me/api/portraits/women/44.jpg',
      'unread': 0,
    },
    {
      'name': 'Kamal Hossain',
      'message': 'Can you offer any discount?',
      'time': 'Yesterday',
      'image': 'https://randomuser.me/api/portraits/men/86.jpg',
      'unread': 1,
    },
    {
      'name': 'Sabina Yasmin',
      'message': 'I want to buy the blue jamdani saree',
      'time': 'Monday',
      'image': 'https://randomuser.me/api/portraits/women/22.jpg',
      'unread': 0,
    },
    {
      'name': 'Rahim Khan',
      'message': 'Is cash on delivery available?',
      'time': 'Sunday',
      'image': 'https://randomuser.me/api/portraits/men/56.jpg',
      'unread': 0,
    },
    {
      'name': 'Fatema Begum',
      'message': 'Do you have any wedding collection?',
      'time': '23/05/2023',
      'image': 'https://randomuser.me/api/portraits/women/90.jpg',
      'unread': 0,
    },
    {
      'name': 'Imran Ahmed',
      'message': 'Please send more pictures of that saree',
      'time': '20/05/2023',
      'image': 'https://randomuser.me/api/portraits/men/41.jpg',
      'unread': 0,
    },
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                          'Messages',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.search,
                              color: Colors.white, size: 24.r),
                          onPressed: () {
                            // Add search functionality
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
                            'Stay connected with your saree community',
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

                  // Stats containers
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatsContainer(
                            Icons.inbox_outlined,
                            'Inbox',
                            '${_chats.where((chat) => chat['unread'] > 0).length}',
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildStatsContainer(
                            Icons.send_outlined,
                            'Sent',
                            '${_chats.length}',
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildStatsContainer(
                            Icons.archive_outlined,
                            'Archived',
                            '0',
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
                            child: _chats.isEmpty
                                ? _buildEmptyState()
                                : _buildChatList(),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: FloatingActionButton(
                onPressed: () {
                  // Add new chat functionality
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child:
                    Icon(Icons.chat_outlined, color: Colors.white, size: 24.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContainer(IconData icon, String title, String count) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
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
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 24.r),
                SizedBox(height: 8.h),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  count,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
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
                Icons.chat_bubble_outline,
                size: 48.r,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Start a conversation with a seller or buyer',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: EdgeInsets.all(20.r),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: _buildChatItem(chat),
        );
      },
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
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
                color:
                    Colors.white.withOpacity(chat['unread'] > 0 ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: chat['unread'] > 0
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  // Navigate to chat detail screen
                },
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      // Profile image
                      Stack(
                        children: [
                          Container(
                            width: 56.r,
                            height: 56.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28.r),
                              child: Image.network(
                                chat['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white.withOpacity(0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 24.r,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (chat['unread'] > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '${chat['unread']}',
                                  style: TextStyle(
                                    color: Colors.brown.shade800,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 16.w),

                      // Chat info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    chat['name'],
                                    style: TextStyle(
                                      fontWeight: chat['unread'] > 0
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  chat['time'],
                                  style: TextStyle(
                                    color: chat['unread'] > 0
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.7),
                                    fontSize: 12.sp,
                                    fontWeight: chat['unread'] > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              chat['message'],
                              style: TextStyle(
                                color: chat['unread'] > 0
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                                fontWeight: chat['unread'] > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
