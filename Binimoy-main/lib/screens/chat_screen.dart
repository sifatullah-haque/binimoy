import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final chatId = _getChatId();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('chatId', isEqualTo: chatId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Chat error: ${snapshot.error}');
                  return const Center(
                    child: Text('Failed to load messages. Please try again.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == _currentUser!.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe 
                              ? CrossAxisAlignment.end 
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageData['message'] as String,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              messageData['senderName'] as String,
                              style: TextStyle(
                                color: isMe 
                                    ? Colors.white.withOpacity(0.7) 
                                    : Colors.black.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChatId() {
    final List<String> ids = [_currentUser!.uid, widget.receiverId];
    ids.sort();
    return ids.join('_');
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null) return;

    try {
      final chatId = _getChatId();
      final message = {
        'senderId': _currentUser!.uid,
        'senderName': _currentUser!.displayName ?? 'Anonymous',
        'receiverId': widget.receiverId,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'chatId': chatId,
      };

      await _firestore
          .collection('chats')
          .add(message);

      _messageController.clear();
    } catch (e) {
      print('Send message error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}