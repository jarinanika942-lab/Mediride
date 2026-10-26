import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'screens/reset_password_page.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Uri? initialLaunchUri;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Save the incoming link before Supabase processes it.
  if (kIsWeb) {
    initialLaunchUri = Uri.base;
  } else {
    try {
      initialLaunchUri = await AppLinks().getInitialLink();
    } catch (e) {
      debugPrint('Could not read initial app link: $e');
    }
  }

  await Supabase.initialize(
    url: 'https://pdeifxytshbrsicjgcmf.supabase.co',
    // ignore: deprecated_member_use
    anonKey: 'sb_publishable_TcIPimtbmKD0IDjwtECLQQ_tIiVEiNG',
  );

  runApp(const MediRideApp());
}

class MediRideApp extends StatefulWidget {
  const MediRideApp({super.key});

  @override
  State<MediRideApp> createState() => _MediRideAppState();
}

class _MediRideAppState extends State<MediRideApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _recoveryPageOpened = false;

  bool get _isRecoveryLink {
    final uri = initialLaunchUri;
    if (uri == null) return false;

    // Flutter Web callback.
    if (kIsWeb && uri.queryParameters.containsKey('code')) {
      return true;
    }

    // Android custom-scheme callback.
    return uri.scheme == 'mediride' &&
        uri.host == 'reset-password';
  }

  @override
  void initState() {
    super.initState();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        debugPrint('Supabase auth event: ${data.event}');

        if (data.event == AuthChangeEvent.passwordRecovery) {
          _openResetPasswordPage();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Supabase auth error: $error');
      },
    );

    // Supabase may process the recovery link during initialization,
    // before this listener is attached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final session =
          Supabase.instance.client.auth.currentSession;

      if (_isRecoveryLink && session != null) {
        _openResetPasswordPage();
      }
    });
  }

  void _openResetPasswordPage() {
    if (_recoveryPageOpened) return;

    _recoveryPageOpened = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;

      if (!mounted || navigator == null) {
        _recoveryPageOpened = false;
        debugPrint('Navigator is not ready.');
        return;
      }

      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const ResetPasswordPage(),
        ),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRecoverySession =
        _isRecoveryLink &&
        Supabase.instance.client.auth.currentSession != null;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MediRide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
      ),
      home: hasRecoverySession
          ? const ResetPasswordPage()
          : const SplashScreen(),
    );
  }
}