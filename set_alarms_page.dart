import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';

class SetAlarmsPage extends StatefulWidget {
  const SetAlarmsPage({super.key});

  @override
  State<SetAlarmsPage> createState() => _SetAlarmsPageState();
}

class _SetAlarmsPageState extends State<SetAlarmsPage> {
  final AlarmService _alarmService = AlarmService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _alarmService.initialize();
    await _alarmService.rescheduleAllAlarms();
  }

  // Show add/edit alarm dialog
  void _showAlarmDialog({AlarmReminder? alarm}) {
    final titleController = TextEditingController(text: alarm?.title ?? '');
    TimeOfDay selectedTime = alarm != null
        ? TimeOfDay(
            hour: int.parse(alarm.time.split(':')[0]),
            minute: int.parse(alarm.time.split(':')[1]),
          )
        : TimeOfDay.now();
    String selectedRepeat = alarm?.repeat ?? 'Daily';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(alarm == null ? 'Add Alarm' : 'Edit Alarm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Alarm Title',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Morning Medicine',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: Color(0xFF2B5BA6)),
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRepeat,
                  decoration: const InputDecoration(
                    labelText: 'Repeat',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Daily', 'Weekdays', 'Weekends', 'Once']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRepeat = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter alarm title')),
                  );
                  return;
                }

                // Convert to 24-hour format
                final time24 = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                if (alarm == null) {
                  // Add new alarm
                  final newAlarm = AlarmReminder(
                    id: '',
                    title: titleController.text,
                    time: time24,
                    enabled: true,
                    repeat: selectedRepeat,
                    createdAt: DateTime.now(),
                  );

                  try {
                    await _alarmService.addAlarm(newAlarm);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alarm added successfully!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  // Update existing alarm
                  final updatedAlarm = alarm.copyWith(
                    title: titleController.text,
                    time: time24,
                    repeat: selectedRepeat,
                  );

                  try {
                    await _alarmService.updateAlarm(updatedAlarm);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alarm updated!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B5BA6),
              ),
              child: Text(
                alarm == null ? 'Add' : 'Update',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
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
        title: const Text(
          'Set Alarms',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: () async {
              await _notificationService.showTestNotification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!')),
                );
              }
            },
            tooltip: 'Test Notification',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () async {
              // FIXED: Added async and await here
              final alarms = await Alarm.getAlarms();
              
              if (!mounted) return;
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Scheduled Alarms'),
                  content: SingleChildScrollView(
                    child: Text(
                      alarms.isEmpty
                          ? 'No alarms scheduled'
                          : 'Total: ${alarms.length}\n\n${alarms.map((a) => 'ID: ${a.id}\nTitle: ${a.notificationTitle}\nTime: ${a.dateTime}\n---').join('\n\n')}'
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Reminders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<AlarmReminder>>(
                  stream: _alarmService.getAlarmsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.alarm_off, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No alarms set yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAlarmDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Alarm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2B5BA6),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final alarm = snapshot.data![index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: alarm.enabled
                                          ? const Color(0xFF2B5BA6)
                                          : Colors.grey[400],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.alarm,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showAlarmDialog(alarm: alarm),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            alarm.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            alarm.formattedTime,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            alarm.repeat,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Switch(
                                        value: alarm.enabled,
                                        activeColor: const Color(0xFF2B5BA6),
                                        onChanged: (value) async {
                                          await _alarmService.toggleAlarm(alarm);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          bool? confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Alarm'),
                                              content: Text(
                                                'Are you sure you want to delete "${alarm.title}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              await _alarmService.deleteAlarm(alarm.id);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Alarm deleted')),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAlarmDialog(),
        backgroundColor: const Color(0xFF2B5BA6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Alarm',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}