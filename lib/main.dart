import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final goal = inputData?['goal'] as String? ?? '';
    final taskId = inputData?['taskId'] as String? ?? '';

    // Show a notification reminding the user to execute the task
    final flutterLocalNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    const androidDetails = AndroidNotificationDetails(
      'arcane_flow_scheduler',
      'Scheduled Tasks',
      channelDescription: 'Notifications for scheduled automation tasks',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      taskId.hashCode,
      'Scheduled Task Ready',
      'Time to execute: $goal',
      notificationDetails,
    );

    return true;
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  runApp(const ArcaneFlowApp());
}

class ArcaneFlowApp extends StatelessWidget {
  const ArcaneFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArcaneFlow',
      debugShowCheckedModeBanner: false,
      theme: _auroraTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _auroraTheme() {
    // Deep aurora palette: dark base, neon cyan/purple accents
    const base = Color(0xFF0A0E1A);
    const surface = Color(0xFF111827);
    const card = Color(0xFF1A1F35);
    const accent = Color(0xFF00E5FF);
    const accentPurple = Color(0xFFB388FF);
    const onSurface = Color(0xFFE0E7FF);
    const onSurfaceMuted = Color(0xFF8892B0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: base,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentPurple,
        surface: surface,
        onSurface: onSurface,
        onPrimary: Color(0xFF0A0E1A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: accent),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF151B2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: onSurfaceMuted),
        hintStyle: const TextStyle(color: onSurfaceMuted),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: onSurface),
        bodyMedium: TextStyle(color: onSurface),
        bodySmall: TextStyle(color: onSurfaceMuted),
        titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      ),
      iconTheme: const IconThemeData(color: accent),
      dividerColor: Colors.white.withValues(alpha: 0.06),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? accent : onSurfaceMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
            ? accent.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: const TextStyle(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}