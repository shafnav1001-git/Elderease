import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alarm/alarm.dart';
import 'package:intl/intl.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

import 'login_page.dart';
import 'signup_page.dart';
import 'mainnavigation.dart';
import 'alarm_ring.dart';
import 'biometric_auth_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before running the app
  await Firebase.initializeApp();

  // Initialize Alarm package
  await Alarm.init();
  
  await AlarmService().initialize();
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _authService = AuthService();
  String _initialRoute = '/login';
  bool _isInitialized = false;
  bool _justAuthenticated = false;
  DateTime? _lastAuthTime; // Track when authentication happened

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _determineInitialRoute();
    
    // Listen for alarm triggers
    Alarm.ringStream.stream.listen((alarmSettings) {
      print('🔔 ALARM RINGING! ID: ${alarmSettings.id}, Title: ${alarmSettings.notificationTitle}');
      
      final time = DateFormat('h:mm a').format(alarmSettings.dateTime);
      
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AlarmRingScreen(
            alarmId: alarmSettings.id.toString(),
            alarmTitle: alarmSettings.notificationTitle ?? 'Alarm',
            alarmTime: time,
          ),
          fullscreenDialog: true,
        ),
      );
    });
  }

  Future<void> _determineInitialRoute() async {
    // CRITICAL: Check in the right order
    final hasLoggedIn = await _authService.hasEverLoggedIn();
    final isLoggedIn = _authService.isUserLoggedIn;
    final biometricEnabled = await _authService.isBiometricEnabled();

    print('🔍 Auth Check: hasLoggedIn=$hasLoggedIn, isLoggedIn=$isLoggedIn, biometric=$biometricEnabled');

    setState(() {
      if (hasLoggedIn && isLoggedIn && biometricEnabled) {
        // User was logged in before and has valid session -> show biometric
        _initialRoute = '/biometric';
        print('✅ Routing to: BIOMETRIC');
      } else if (hasLoggedIn && isLoggedIn) {
        // User is logged in but no biometric -> go to home
        _initialRoute = '/home';
        print('✅ Routing to: HOME (no biometric)');
      } else {
        // User needs to login
        _initialRoute = '/login';
        print('✅ Routing to: LOGIN');
      }
      _isInitialized = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed - checking biometric');
      
      // Don't show biometric if we just authenticated in the last 5 seconds
      if (_lastAuthTime != null) {
        final timeSinceAuth = DateTime.now().difference(_lastAuthTime!);
        if (timeSinceAuth.inSeconds < 5) {
          print('⏭️ Skipping biometric (just authenticated ${timeSinceAuth.inSeconds}s ago)');
          return;
        }
      }
      
      if (_justAuthenticated) {
        print('⏭️ Skipping biometric (just authenticated flag)');
        _justAuthenticated = false;
        return;
      }
      
      _checkBiometricOnResume();
    } else if (state == AppLifecycleState.paused) {
      print('⏸️ App paused');
    } else if (state == AppLifecycleState.inactive) {
      print('⏸️ App inactive');
      // Don't trigger anything on inactive state
    }
  }

  Future<void> _checkBiometricOnResume() async {
    final isLoggedIn = _authService.isUserLoggedIn;
    final biometricEnabled = await _authService.isBiometricEnabled();
    
    print('🔐 Resume check: isLoggedIn=$isLoggedIn, biometric=$biometricEnabled');
    
    if (isLoggedIn && biometricEnabled) {
      // Only show biometric if we're not already on biometric or alarm screen
      final currentContext = navigatorKey.currentContext;
      if (currentContext == null) return;
      
      final currentRoute = ModalRoute.of(currentContext)?.settings.name;
      print('📍 Current route: $currentRoute');
      
      // Don't show biometric if already on these screens
      if (currentRoute == '/biometric' || 
          currentRoute == '/alarm_ring' || 
          currentRoute == '/login' ||
          currentRoute == '/signup') {
        print('⏭️ Skipping biometric (on excluded screen)');
        return;
      }
      
      // Set the auth time to prevent immediate re-trigger
      _lastAuthTime = DateTime.now();
      
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/biometric',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    NotificationService.navigatorKey = navigatorKey;
    
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFD3D3D3),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  color: Color(0xFF2B5BA6),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Elder Ease',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2B5BA6),
        scaffoldBackgroundColor: const Color(0xFFD3D3D3),
        fontFamily: 'Roboto',
      ),
      initialRoute: _initialRoute,
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const MainNavigation(),
        '/biometric': (context) => const BiometricAuthScreen(),
      },
    );
  }
}