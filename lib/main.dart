import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/onboarding_screens.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/pin_login_screen.dart';
import 'storage/hive_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (IndexedDB on Web, files on Mobile)
  await Hive.initFlutter();
  await HiveStorage().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mental Wellness Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: false,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  late Future<String> _initialRoute;

  @override
  void initState() {
    super.initState();
    _initialRoute = _determineInitialRoute();
  }

  Future<String> _determineInitialRoute() async {
    final storage = HiveStorage();

    final onboardingCompleted = storage.getOnboardingCompleted();
    final isPinSet = storage.isPINSet();

    if (!onboardingCompleted) {
      return '/onboarding';
    } else if (!isPinSet) {
      return '/pin-setup';
    } else {
      return '/pin-login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _initialRoute,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final route = snapshot.data ?? '/onboarding';

        return Navigator(
          initialRoute: route,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/onboarding':
                return MaterialPageRoute(
                  builder: (_) => const OnboardingScreens(),
                );
              case '/pin-setup':
                return MaterialPageRoute(
                  builder: (_) => const PinSetupScreen(),
                );
              case '/pin-login':
                return MaterialPageRoute(
                  builder: (_) => const PinLoginScreen(),
                );
              default:
                return MaterialPageRoute(
                  builder: (_) => const OnboardingScreens(),
                );
            }
          },
        );
      },
    );
  }
}

// upload to github and update home
// acha update home ke is me All entries aye instead of just recent reflections, readmore icon click pe new page open ho with the journal entry to read it from there, optional edit ka 