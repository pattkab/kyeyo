import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // Logging package
import 'package:permission_handler/permission_handler.dart';
import 'second_screen.dart';

// Initialize a logger instance
final logger = Logger();

Future<void> _setPreferredOrientations() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

void _setSystemUIOverlayStyle() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
  );
}

Future<void> _requestPermissions() async {
  try {
    // Request storage and location permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.location
    ].request();

    // Log the status of each permission
    statuses.forEach((permission, status) {
      logger.i('Permission: $permission, Status: $status');
    });

    // Check if permissions are granted and handle denied permissions
    if (statuses[Permission.storage]?.isGranted == false) {
      _showPermissionDeniedDialog('Storage');
    }
    if (statuses[Permission.location]?.isGranted == false) {
      _showPermissionDeniedDialog('Location');
    }
  } catch (e) {
    logger.e("Permission request error: $e");
  }
}

void _showPermissionDeniedDialog(String permission) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permission Permission Denied'),
          content: Text(
              'The $permission permission is required for the app to function properly. Please enable it in the app settings.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setPreferredOrientations();
  _setSystemUIOverlayStyle();
  await _requestPermissions();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kyeyo',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.pinkAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/secondScreen': (context) => const SecondScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacementNamed(context, '/secondScreen');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: MediaQuery.of(context).platformBrightness == Brightness.light
            ? Colors.white
            : Colors.black,
        child: Center(
          child: Image.asset(
            MediaQuery.of(context).platformBrightness == Brightness.light
                ? 'assets/kyeyo_white.png'
                : 'assets/kyeyo_black.png',
            height: 400,
          ),
        ),
      ),
    );
  }
}
