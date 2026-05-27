import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  bool isEditing = false;
  bool isUploadingImage = false;
  
  // User data
  String userName = '';
  String userEmail = '';
  String profilePictureBase64 = '';
  File? _localImageFile;
  DateTime? accountCreationDate;
  List<Map<String, String>> interests = [];
  int medicationCount = 0;
  int alarmCount = 0;
  int communityCount = 0; // Added community count
  int daysSinceJoined = 0;
  List<Map<String, dynamic>> userCommunities = []; // Store user's communities
  
  // Controllers for editing
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _newInterestController = TextEditingController();
  String _selectedEmoji = '😊';
  
  // Image picker
  final ImagePicker _picker = ImagePicker();
  
  // Available emojis for interests
  final List<String> availableEmojis = [
    '😊', '🎮', '📚', '🎵', '🎨', '🏃', '🧘', '🍳', '✈️', '📸',
    '💻', '🎬', '🏋️', '🎯', '🌱', '🐕', '☕', '🎭', '🏊', '🚴',
    '🧩', '🎲', '🎸', '🖌️', '📝', '🌸', '🏔️', '🎤', '🍕', '🌊'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newInterestController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      // Get user document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        
        // Calculate days since account creation
        if (data['createdAt'] != null) {
          accountCreationDate = (data['createdAt'] as Timestamp).toDate();
          daysSinceJoined = DateTime.now().difference(accountCreationDate!).inDays;
        }

        // Get medications count
        final medicationsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('medications')
            .get();
        medicationCount = medicationsSnapshot.docs.length;

        // Get alarms count
        final alarmsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('alarms')
            .get();
        alarmCount = alarmsSnapshot.docs.length;

        // Get communities count - NEW
        final groupsSnapshot = await FirebaseFirestore.instance
            .collection('groups')
            .where('members', arrayContains: user!.uid)
            .get();
        
        communityCount = groupsSnapshot.docs.length;
        
        // Store community details for display
        userCommunities = groupsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unnamed Group',
            'description': data['description'] ?? '',
            'memberCount': (data['members'] as List).length,
          };
        }).toList();

        // Get interests
        if (data['interests'] != null) {
          interests = List<Map<String, String>>.from(
            (data['interests'] as List).map((item) => {
              'emoji': item['emoji'] as String,
              'text': item['text'] as String,
            })
          );
        }

        setState(() {
          userName = data['displayName'] ?? user!.displayName ?? user!.email!.split('@')[0];
          userEmail = user!.email ?? '';
          profilePictureBase64 = data['profilePictureBase64'] ?? '';
          _usernameController.text = userName;
        });
      } else {
        // Initialize user data if doesn't exist
        setState(() {
          userName = user!.displayName ?? user!.email!.split('@')[0];
          userEmail = user!.email ?? '';
          _usernameController.text = userName;
          accountCreationDate = user!.metadata.creationTime;
          if (accountCreationDate != null) {
            daysSinceJoined = DateTime.now().difference(accountCreationDate!).inDays;
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (user == null) {
      print('Error: User is null');
      return;
    }

    try {
      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        print('No source selected');
        return;
      }

      print('Picking image from $source');

      // Pick image with smaller size to reduce Firestore storage
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) {
        print('No image selected');
        return;
      }

      print('Image picked: ${image.path}');

      setState(() {
        isUploadingImage = true;
      });

      // Read image as bytes
      final bytes = await image.readAsBytes();
      
      // Check file size (Firestore has 1MB document limit)
      if (bytes.length > 800000) {
        throw Exception('Image too large. Please select a smaller image or take a new photo.');
      }

      // Convert to base64
      final base64Image = base64Encode(bytes);

      print('Image converted to base64, size: ${bytes.length} bytes');

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'profilePictureBase64': base64Image,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Firestore updated');

      setState(() {
        profilePictureBase64 = base64Image;
        _localImageFile = File(image.path);
        isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e, stackTrace) {
      print('Error uploading image: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('too large') 
                ? 'Image too large! Please select a smaller image.'
                : 'Error uploading image: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'displayName': _usernameController.text,
        'profilePictureBase64': profilePictureBase64,
        'interests': interests,
        'email': userEmail,
        'createdAt': accountCreationDate != null 
            ? Timestamp.fromDate(accountCreationDate!)
            : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        userName = _usernameController.text;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  void _addInterest() {
    if (_newInterestController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an interest name'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if interest already exists (case-insensitive)
    final newInterestText = _newInterestController.text.trim().toLowerCase();
    final isDuplicate = interests.any(
      (interest) => interest['text']!.toLowerCase() == newInterestText
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This interest already exists!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      interests.add({
        'emoji': _selectedEmoji,
        'text': _newInterestController.text.trim(),
      });
      _newInterestController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Interest added successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeInterest(int index) {
    setState(() {
      interests.removeAt(index);
    });
  }

  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Emoji'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableEmojis.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEmoji = availableEmojis[index];
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedEmoji == availableEmojis[index]
                          ? Colors.blue
                          : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      availableEmojis[index],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (isUploadingImage) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (profilePictureBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(profilePictureBase64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error displaying image: $error');
              return const Icon(Icons.person, size: 36, color: Colors.grey);
            },
          ),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return const Icon(Icons.person, size: 36, color: Colors.grey);
      }
    }

    return const Icon(Icons.person, size: 36, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3D3D3),
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and logout
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.blue[700],
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Profile Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isEditing
                                    ? TextField(
                                        controller: _usernameController,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Enter your name',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        userName,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                const SizedBox(height: 4),
                                Text(
                                  userEmail,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Profile Picture with Edit
                          GestureDetector(
                            onTap: isEditing ? _pickAndUploadImage : null,
                            child: Stack(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _buildProfileImage(),
                                ),
                                if (isEditing && !isUploadingImage)
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Interests Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Interests:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        if (isEditing)
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Add Interest'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: _showEmojiPicker,
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.blue),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _selectedEmoji,
                                                style: const TextStyle(fontSize: 24),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: _newInterestController,
                                              decoration: const InputDecoration(
                                                hintText: 'Interest name',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _addInterest();
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    interests.isEmpty
                        ? const Text(
                            'No interests added yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: interests.asMap().entries.map((entry) {
                              final index = entry.key;
                              final interest = entry.value;
                              return Chip(
                                avatar: Text(
                                  interest['emoji']!,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                label: Text(interest['text']!),
                                deleteIcon: isEditing ? const Icon(Icons.close, size: 18) : null,
                                onDeleted: isEditing ? () => _removeInterest(index) : null,
                                backgroundColor: Colors.blue[50],
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 24),

                    // Active in> Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active in>',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Activity Stats
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildActivityCard(
                                icon: Icons.calendar_today,
                                label: 'Member',
                                value: '$daysSinceJoined days',
                                color: Colors.blue,
                              ),
                              _buildActivityCard(
                                icon: Icons.medication,
                                label: 'Medications',
                                value: '$medicationCount',
                                color: Colors.green,
                              ),
                              _buildActivityCard(
                                icon: Icons.alarm,
                                label: 'Reminders',
                                value: '$alarmCount',
                                color: Colors.orange,
                              ),
                              _buildActivityCard(
                                icon: Icons.favorite,
                                label: 'Communities',
                                value: '$communityCount', // Updated with actual count
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Communities Section - UPDATED
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Communities',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          userCommunities.isEmpty
                              ? Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.groups_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No communities yet',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: userCommunities.map((community) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.blue[700],
                                            radius: 20,
                                            child: Text(
                                              community['name'][0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  community['name'],
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (community['description'].isNotEmpty)
                                                  Text(
                                                    community['description'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[700],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.people,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${community['memberCount']}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
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
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        // Edit Profile Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (isEditing) {
                                _saveProfile();
                              } else {
                                setState(() {
                                  isEditing = true;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B5BA6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Save Profile' : 'Edit Profile',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Cancel/Share Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (isEditing) {
                                setState(() {
                                  isEditing = false;
                                  _usernameController.text = userName;
                                  _loadUserData(); // Reload original data
                                });
                              } else {
                                // Share profile functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Share feature coming soon!'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEditing 
                                  ? Colors.grey[600] 
                                  : const Color(0xFF2B5BA6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Cancel' : 'Share Profile',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}