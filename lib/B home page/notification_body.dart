import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:learn_n/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBody extends StatefulWidget {
  const NotificationBody({super.key});

  @override
  State<NotificationBody> createState() => _NotificationBodyState();
}

class _NotificationBodyState extends State<NotificationBody>
    with WidgetsBindingObserver {
  TimeOfDay? selectedTime;
  Timer? _timer;
  String? timeText;
  bool isNotificationSet = false;
  bool _isDisposed = false;

  List<int> timeIntervals = [5, 10, 15, 20, 25, 30];
  int? selectedInterval;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.init();
    _loadPreferences();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cancelNotification();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _cancelNotification();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isDisposed) return; // Check if the widget is disposed
    setState(() {
      selectedInterval = prefs.getInt('selectedInterval');
      if (selectedInterval != null &&
          !timeIntervals.contains(selectedInterval)) {
        selectedInterval = null;
      }
      timeText = prefs.getString('timeText');
      isNotificationSet = prefs.getBool('isNotificationSet') ?? false;
    });

    if (isNotificationSet) {
      final int? remainingTime = prefs.getInt('remainingTime');
      if (remainingTime != null && remainingTime > 0) {
        _timer = Timer(Duration(seconds: remainingTime), _sendNotification);
      }
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedInterval', selectedInterval ?? 0);
    await prefs.setString('timeText', timeText ?? '');
    await prefs.setBool('isNotificationSet', isNotificationSet);
    if (_timer != null && _timer!.isActive) {
      final remainingTime = _timer!.tick;
      await prefs.setInt('remainingTime', remainingTime);
    } else {
      await prefs.remove('remainingTime');
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && picked != selectedTime) {
      final now = DateTime.now();
      final notificationTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      if (notificationTime.isAfter(now)) {
        setState(() {
          selectedTime = picked;
          timeText = "Time selected: ${picked.format(context)}";
          isNotificationSet = true;
        });
        _savePreferences();
        _scheduleNotification(picked);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please pick a future time!")),
        );
      }
    }
  }

  void _scheduleNotification(TimeOfDay time) {
    final now = DateTime.now();
    final notificationTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    final delay = notificationTime.difference(now).inSeconds;

    if (delay > 0) {
      _timer = Timer(Duration(seconds: delay), _sendNotification);
      _savePreferences();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a future time!")),
      );
    }
  }

  void _sendNotification() {
    NotificationService.showInstantNotification(
      'Time to Study!',
      'Keep pushing forward — your future self will thank you!',
    );

    setState(() {
      isNotificationSet = false;
      timeText = "Please choose a time interval or select a time.";
      selectedTime = null;
    });
    _savePreferences();
  }

  void _cancelNotification() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      if (_isDisposed) return;
      setState(() {
        isNotificationSet = false;
        timeText = "Please choose a time interval or select a time.";
        selectedTime = null;
      });
      _savePreferences();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification cancelled.")),
      );
    } else {
      if (_isDisposed) return;
      setState(() {
        timeText = "Please choose a time interval or select a time.";
        isNotificationSet = false;
      });
    }
  }

  Widget _buildTimeIntervalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            "⏰ Time Interval",
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<int>(
            value: selectedInterval,
            hint: const Text(
              "Select Interval",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            icon: const Icon(
              Icons.access_time,
              color: Colors.black,
            ),
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 11,
              color: Colors.black,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            items: timeIntervals.map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value minutes'),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                selectedInterval = newValue;
              });
              if (newValue != null) {
                _scheduleIntervalNotification(newValue);
              }
              _savePreferences();
            },
          ),
        ),
      ],
    );
  }

  void _scheduleIntervalNotification(int interval) {
    final now = DateTime.now();
    final notificationTime = now.add(Duration(minutes: interval));

    final delay = notificationTime.difference(now).inSeconds;

    if (delay > 0) {
      _timer = Timer(Duration(seconds: delay), _sendNotification);
      setState(() {
        timeText = "Notification set for $interval minutes from now.";
        isNotificationSet = true;
      });
      _savePreferences();
    }
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            "📅 Time Selection",
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        Center(
          child: buildRetroButton(
            "Select Time",
            Colors.black,
            _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationDetails() {
    return Column(
      children: [
        Text(
          timeText ?? "Please choose a time interval or select a time.",
          style: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        if (isNotificationSet)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: buildRetroButton(
              "Cancel Notification",
              Colors.red,
              _cancelNotification,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _buildTimeIntervalSelector(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _buildNotificationSettings(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _buildNotificationDetails(),
            ),
            const Text(
                'dipato gumagana sa website pero sa mobile oks na hehehe'),
          ],
        ),
      ),
    );
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String customChannelId = 'custom_sound_channel_id';

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('logo');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      const customSoundChannel = AndroidNotificationChannel(
        customChannelId,
        'Custom Sound Notifications',
        description: 'Channel for custom sound notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(customSoundChannel);

      print("Notifications initialized successfully!");
    } catch (e) {
      print("Notification initialization error: $e");
    }
  }

  static Future<void> showInstantNotification(String title, String body) async {
    try {
      const platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails(
          customChannelId,
          'Custom Sound Notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: 'instant_notification',
      );

      print("Notification sent!");
    } catch (e) {
      print("Failed to show notification: $e");
    }
  }
}
