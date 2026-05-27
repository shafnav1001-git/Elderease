import 'package:flutter/material.dart';
import 'caretaker_booking_page.dart';
import 'games_page.dart';
import 'set_alarms_page.dart';
import 'chatbot_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                //     onTap: () {
                //       // Navigate to profile
                //       Navigator.pushNamed(context, '/profile');
                //     },
                //     child: Container(
                //       width: 50,
                //       height: 50,
                //       decoration: BoxDecoration(
                //         color: const Color(0xFF2B5BA6),
                //         shape: BoxShape.circle,
                //       ),
                //       child: const Icon(
                //         Icons.person,
                //         color: Colors.white,
                //         size: 30,
                //       ),
                //     ),
                //   ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Menu Items
              _buildMenuItem(
                context,
                icon: Icons.local_hospital,
                text: 'Caretaker Booking',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CaretakerBookingPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              
              _buildMenuItem(
                context,
                icon: Icons.games,
                text: 'Games',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GamesPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              
              _buildMenuItem(
                context,
                icon: Icons.alarm,
                text: 'Set alarms',
                onTap: () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SetAlarmsPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              
              _buildMenuItem(
                context,
                icon: Icons.chat_bubble,
                text: 'Chatbot Assistance',
                onTap: () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ChatbotPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.black,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}