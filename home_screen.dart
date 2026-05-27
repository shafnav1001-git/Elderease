import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/medication_service.dart';
import 'add_medication_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNewsIndex = 0;
  List<Map<String, dynamic>> _newsArticles = [];
  bool _isLoadingNews = true;
  
  // Medication variables
  final _medicationService = MedicationService();
  List<Map<String, dynamic>> _upcomingMedications = [];
  bool _isLoadingMeds = true;

  final String _newsApiKey = 'a672130cad4e4024993685f5a60de851';

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _fetchUpcomingMedications();
  }

  // Fetch news from NewsAPI
  Future<void> _fetchNews() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://newsapi.org/v2/top-headlines?category=health&country=us&apiKey=$_newsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _newsArticles = List<Map<String, dynamic>>.from(
            (data['articles'] as List).take(5).map((article) => {
              'title': article['title'] ?? 'No title',
              'description': article['description'] ?? 'No description',
              'url': article['url'] ?? '',
              'imageUrl': article['urlToImage'] ?? '',
            }),
          );
          _isLoadingNews = false;
        });
      } else {
        _showDefaultTips();
      }
    } catch (e) {
      print('Error fetching news: $e');
      _showDefaultTips();
    }
  }

  void _showDefaultTips() {
    setState(() {
      _isLoadingNews = false;
      _newsArticles = [
        {
          'title': 'Stay Active Daily',
          'description': 'Regular exercise helps maintain health and mobility in seniors.',
        },
        {
          'title': 'Healthy Eating Tips',
          'description': 'Balanced nutrition is key to healthy aging.',
        },
        {
          'title': 'Stay Connected',
          'description': 'Social connections improve mental health and wellbeing.',
        },
      ];
    });
  }

  // Fetch upcoming medications
  Future<void> _fetchUpcomingMedications() async {
    try {
      final medications = await _medicationService.getUpcomingMedications();
      setState(() {
        _upcomingMedications = medications.take(3).toList();
        _isLoadingMeds = false;
      });
    } catch (e) {
      print('Error fetching medications: $e');
      setState(() {
        _isLoadingMeds = false;
      });
    }
  }

  // DELETE MEDICATION WITH CONFIRMATION
  Future<void> _deleteMedication(String medicationId, String medicationName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Medication?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$medicationName"?\n\nThis action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    // If user confirmed, delete the medication
    if (confirmed == true) {
      try {
        await _medicationService.deleteMedication(medicationId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ "$medicationName" deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          
          // Refresh the medication list
          _fetchUpcomingMedications();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting medication: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  void _previousNews() {
    if (_newsArticles.isEmpty) return;
    setState(() {
      _currentNewsIndex = (_currentNewsIndex - 1 + _newsArticles.length) % _newsArticles.length;
    });
  }

  void _nextNews() {
    if (_newsArticles.isEmpty) return;
    setState(() {
      _currentNewsIndex = (_currentNewsIndex + 1) % _newsArticles.length;
    });
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  Future<void> _navigateToAddMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );

    // Refresh medications if a new one was added
    if (result == true) {
      _fetchUpcomingMedications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFD3D3D3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar with Logo and Profile Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Hello $userName!\nWelcome back!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Update Section
                const Text(
                  "Here's some update for today:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // News Carousel with Arrows
                SizedBox(
                  height: 220,
                  child: Row(
                    children: [
                      // Left Arrow
                      GestureDetector(
                        onTap: _previousNews,
                        child: Container(
                          width: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A4A4A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),

                      // News Card
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B5BA6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _isLoadingNews
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : _newsArticles.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                          'No news available',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _newsArticles[_currentNewsIndex]['title'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              _newsArticles[_currentNewsIndex]['description'],
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 12),
                                            // Page Indicators (Dots)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: List.generate(
                                                _newsArticles.length,
                                                (index) => Container(
                                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: _currentNewsIndex == index
                                                        ? Colors.white
                                                        : Colors.white38,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                        ),
                      ),

                      // Right Arrow
                      GestureDetector(
                        onTap: _nextNews,
                        child: Container(
                          width: 40,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A4A4A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Medication Reminder Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Hey! Don't forget your\nmedications!!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddMedication,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Medication Cards WITH DELETE BUTTON
                _isLoadingMeds
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _upcomingMedications.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No upcoming medications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap "Add" to create your first reminder',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: _upcomingMedications.map((med) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    // Medication Info
                                    Column(
                                      children: [
                                        Text(
                                          '${med['name']} (${med['dosage']})',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(med['time']),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                        if (med['instructions'] != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            med['instructions'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    ),
                                    
                                    // DELETE BUTTON (Top Right)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                        onPressed: () => _deleteMedication(
                                          med['id'],
                                          med['name'],
                                        ),
                                        tooltip: 'Delete medication',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}