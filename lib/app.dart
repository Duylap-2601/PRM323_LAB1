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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF818CF8),
          surface: Color(0xFF0F172A),
          surfaceContainer: Color(0xFF131D31),
          surfaceContainerHighest: Color(0xFF1E293B),
          outline: Color(0xFF24324D),
          outlineVariant: Color(0xFF192438),
          onSurface: Color(0xFFF8FAFC),
          onSurfaceVariant: Color(0xFF94A3B8),
        ),
        useMaterial3: true,
        dividerColor: const Color(0xFF1F2B42),
        cardTheme: const CardThemeData(
          color: Color(0xFF11192C),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: Color(0xFF24324D), width: 1),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF0F172A),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: Color(0xFF24324D), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF0D1424),
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF24324D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF24324D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: const Color(0xFFFFFFFF),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.2),
          ),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          textStyle: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 11),
          waitDuration: const Duration(milliseconds: 300),
        ),
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
