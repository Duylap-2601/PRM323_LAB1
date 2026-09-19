import 'package:flutter/material.dart';

import 'controllers/audit_controller.dart';
import 'screens/home_screen.dart';

/// MaterialApp + theme + controller dùng chung (plan §4).
class AuditApp extends StatefulWidget {
  const AuditApp({super.key});

  @override
  State<AuditApp> createState() => _AuditAppState();
}

class _AuditAppState extends State<AuditApp> {
  late final AuditController controller;

  @override
  void initState() {
    super.initState();
    controller = AuditController();
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citation Audit Desktop',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          surface: Color(0xFF1E293B),
          surfaceContainerHighest: Color(0xFF162032),
          outline: Color(0xFF334155),
          onSurface: Color(0xFFF8FAFC),
          onSurfaceVariant: Color(0xFF94A3B8),
        ),
        useMaterial3: true,
        dividerColor: const Color(0xFF334155),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            side: BorderSide(color: Color(0xFF334155)),
          ),
        ),
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
