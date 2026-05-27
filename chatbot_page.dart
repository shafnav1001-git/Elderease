import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  bool _isTyping = false;
  bool _isSending = false;

  List<Map<String, dynamic>> messages = [
    {
      'text': 'Hello! I\'m here to help you. How can I assist you today?',
      'isBot': true,
      'time': _getFormattedTime(),
    },
  ];

  static String _getFormattedTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getCurrentTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      messages.add({
        'text': userMessage,
        'isBot': false,
        'time': _getCurrentTime(),
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final botReply = await _chatService.sendMessage(userMessage);

      if (mounted) {
        setState(() {
          messages.add({
            'text': botReply,
            'isBot': true,
            'time': _getCurrentTime(),
          });
          _isTyping = false;
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add({
            'text': 'Oops! Something went wrong. Please try again later.',
            'isBot': true,
            'time': _getCurrentTime(),
          });
          _isTyping = false;
          _isSending = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleQuickAction(String text) {
    if (_isSending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the current response...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      messages.add({
        'text': text,
        'isBot': false,
        'time': _getCurrentTime(),
      });
      _isSending = true;
      _isTyping = true;
    });
    
    _scrollToBottom();
    _sendQuickBotResponse(text);
  }

  Future<void> _sendQuickBotResponse(String text) async {
    try {
      final response = await _chatService.sendMessage(text);
      if (mounted) {
        setState(() {
          messages.add({
            'text': response,
            'isBot': true,
            'time': _getCurrentTime(),
          });
          _isTyping = false;
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add({
            'text': 'Sorry, I couldn\'t process that right now.',
            'isBot': true,
            'time': _getCurrentTime(),
          });
          _isTyping = false;
          _isSending = false;
        });
      }
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3D3D3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B5BA6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Color(0xFF2B5BA6),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chatbot Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isSending ? 'Processing...' : 'Online',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Action Buttons
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickButton('Medicine Help', Icons.medication),
                  const SizedBox(width: 10),
                  _buildQuickButton('Health Tips', Icons.health_and_safety),
                  const SizedBox(width: 10),
                  _buildQuickButton('Emergency', Icons.emergency),
                  const SizedBox(width: 10),
                  _buildQuickButton('Diet Info', Icons.restaurant),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 15),
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy, color: Color(0xFF2B5BA6)),
                        const SizedBox(width: 10),
                        const Text("Typing", style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 5),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final message = messages[index];
                final isBot = message['isBot'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: isBot
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isBot)
                        Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2B5BA6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isBot
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isBot
                                    ? Colors.white
                                    : const Color(0xFF2B5BA6),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                message['text'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isBot ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              message['time'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isBot)
                        Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD3D3D3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isSending,
                      decoration: InputDecoration(
                        hintText: _isSending 
                            ? 'Please wait...' 
                            : 'Type your message...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isSending 
                          ? Colors.grey 
                          : const Color(0xFF2B5BA6),
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String text, IconData icon) {
    return Opacity(
      opacity: _isSending ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: _isSending ? null : () => _handleQuickAction(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2B5BA6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2B5BA6),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2B5BA6)),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF2B5BA6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}