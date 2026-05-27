import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample chat data
    final List<Map<String, String>> chats = [
      {'name': 'xyz', 'message': 'Hello'},
      {'name': 'xyz', 'message': 'Hello'},
      {'name': 'xyz', 'message': ''},
      {'name': 'xyz', 'message': ''},
      {'name': 'xyz', 'message': ''},
      {'name': 'xyz', 'message': ''},
      {'name': 'xyz', 'message': ''},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFD3D3D3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and profile icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  // GestureDetector(
                  //   onTap: () {
                  //     // Navigate to profile
                  //   },
                  //   child: Container(
                  //     width: 50,
                  //     height: 50,
                  //     decoration: BoxDecoration(
                  //       color: const Color(0xFF2B5BA6),
                  //       shape: BoxShape.circle,
                  //     ),
                  //     child: const Icon(
                  //       Icons.person,
                  //       color: Colors.white,
                  //       size: 30,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Title
              const Text(
                'Chat with\npeople!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 25),
              
              // Chat List
              Expanded(
                child: ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    return _buildChatItem(
                      context,
                      name: chats[index]['name']!,
                      message: chats[index]['message']!,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, {
    required String name,
    required String message,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to individual chat
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 15),
            
            // Name and Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}