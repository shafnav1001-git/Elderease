import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart'; // ADD THIS IMPORT!

class AlarmRingScreen extends StatefulWidget {
  final String alarmTitle;
  final String alarmTime;
  final String alarmId;

  const AlarmRingScreen({
    super.key,
    required this.alarmTitle,
    required this.alarmTime,
    required this.alarmId,
  });

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  Future<void> _stopAlarm() async {
    setState(() {
      _isPlaying = false;
    });
    
    // Stop the alarm using the alarm package
    try {
      await Alarm.stop(int.parse(widget.alarmId));
      print('✅ Alarm stopped: ${widget.alarmId}');
    } catch (e) {
      print('❌ Error stopping alarm: $e');
    }
    
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _snoozeAlarm() async {
    // Stop current alarm
    try {
      await Alarm.stop(int.parse(widget.alarmId));
      print('⏰ Alarm snoozed: ${widget.alarmId}');
    } catch (e) {
      print('❌ Error snoozing alarm: $e');
    }
    
    // Schedule snooze alarm (5 minutes from now)
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final snoozeSettings = AlarmSettings(
      id: int.parse(widget.alarmId) + 1000000, // Different ID for snooze
      dateTime: snoozeTime,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      notificationTitle: '${widget.alarmTitle} (Snoozed)',
      notificationBody: 'Snooze alarm ringing!',
      enableNotificationOnKill: true,
    );
    
    try {
      await Alarm.set(alarmSettings: snoozeSettings);
      print('✅ Snooze alarm set for: $snoozeTime');
    } catch (e) {
      print('❌ Error setting snooze: $e');
    }
    
    if (mounted) {
      Navigator.of(context).pop(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Alarm snoozed for 5 minutes'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: const Color(0xFF2B5BA6),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated alarm icon
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 0.5 - 0.25,
                      child: Icon(
                        Icons.alarm,
                        size: 120,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // Alarm title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.alarmTitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Alarm time
                Text(
                  widget.alarmTime,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Current date/time
                Text(
                  _getCurrentDateTime(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 80),
                
                // Dismiss button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: ElevatedButton(
                      onPressed: _stopAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2B5BA6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                      ),
                      child: const Text(
                        'DISMISS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Snooze button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: _snoozeAlarm,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'SNOOZE (5 MIN)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}