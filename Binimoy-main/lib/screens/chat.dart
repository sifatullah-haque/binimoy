import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Add search functionality
            },
          ),
        ],
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
          child: Column(
            children: [
              // Stats container
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatsContainer(
                      Icons.inbox,
                      'Inbox',
                      '${_chats.where((chat) => chat['unread'] > 0).length}',
                    ),
                    _buildStatsContainer(
                      Icons.send,
                      'Sent',
                      '${_chats.length}',
                    ),
                    _buildStatsContainer(
                      Icons.archive_outlined,
                      'Archived',
                      '0',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),

              // Main content with white background
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  child: _chats.isEmpty ? _buildEmptyState() : _buildChatList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new chat functionality
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsContainer(IconData icon, String title, String count) {
    return Container(
      width: 90.w,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24.r),
          SizedBox(height: 6.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            count,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80.r,
            color: Colors.grey.withOpacity(0.7),
          ),
          SizedBox(height: 16.h),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start a conversation with a seller or buyer',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 20.h),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return _buildChatItem(chat);
      },
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    return InkWell(
      onTap: () {
        // Navigate to chat detail screen
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            // Profile image
            Stack(
              children: [
                Container(
                  width: 60.r,
                  height: 60.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.shade100,
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(chat['image']),
                      fit: BoxFit.cover,
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
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${chat['unread']}',
                        style: TextStyle(
                          color: Colors.white,
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
                      Text(
                        chat['name'],
                        style: TextStyle(
                          fontWeight: chat['unread'] > 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 16.sp,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        chat['time'],
                        style: TextStyle(
                          color: chat['unread'] > 0
                              ? Colors.green.shade700
                              : Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    chat['message'],
                    style: TextStyle(
                      color: chat['unread'] > 0
                          ? Colors.black87
                          : Colors.grey.shade600,
                      fontSize: 14.sp,
                      fontWeight: chat['unread'] > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
