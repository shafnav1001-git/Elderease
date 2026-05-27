import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() => _isAuthenticating = true);

    try {
      bool canCheckBiometrics = false;
      bool isDeviceSupported = false;
      
      try {
        canCheckBiometrics = await _localAuth.canCheckBiometrics;
        isDeviceSupported = await _localAuth.isDeviceSupported();
      } catch (e) {
        print('Error checking biometric support: $e');
      }

      if (!canCheckBiometrics && !isDeviceSupported) {
        print('⚠️ No biometric support - going to home');
        if (mounted) {
          _navigateToHome();
        }
        return;
      }

      List<BiometricType> availableBiometrics = [];
      try {
        availableBiometrics = await _localAuth.getAvailableBiometrics();
        print('Available biometrics: $availableBiometrics');
      } catch (e) {
        print('Error getting available biometrics: $e');
      }

      if (availableBiometrics.isEmpty) {
        print('⚠️ No biometrics enrolled - going to home');
        if (mounted) {
          _navigateToHome();
        }
        return;
      }

      // Simple authenticate call without any optional parameters
      bool authenticated = false;
      try {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access Elder Ease',
        );
        print('Authentication result: $authenticated');
      } catch (e) {
        print('Authentication exception: $e');
        if (mounted) {
          _navigateToHome();
        }
        return;
      }

      if (mounted) {
        if (authenticated) {
          print('✅ Biometric authentication successful');
          _navigateToHome();
        } else {
          _failedAttempts++;
          
          if (_failedAttempts >= 3) {
            final shouldLogin = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Too Many Attempts'),
                content: const Text('Would you like to login with your email and password instead?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Try Again'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B5BA6),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
            
            if (shouldLogin == true && mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            } else {
              _failedAttempts = 0;
            }
          }
        }
      }
    } catch (e) {
      print('Unexpected error in _authenticate: $e');
      if (mounted) {
        _navigateToHome();
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Set flag in main app to prevent immediate re-authentication
        final navigator = Navigator.of(context);
        navigator.pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFD3D3D3),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 60),

                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B5BA6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Please authenticate to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isAuthenticating ? null : _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B5BA6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: _isAuthenticating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.fingerprint, color: Colors.white, size: 28),
                      label: Text(
                        _isAuthenticating ? 'Authenticating...' : 'Authenticate',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      'Login with different account',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2B5BA6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}