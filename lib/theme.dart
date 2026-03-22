import 'package:flutter/material.dart';

class C {
  static const bg       = Color(0xFF0d1117);
  static const surface  = Color(0xFF161b22);
  static const surface2 = Color(0xFF1c2128);
  static const border   = Color(0xFF30363d);
  static const accent   = Color(0xFFf78166);
  static const accent2  = Color(0xFF79c0ff);
  static const text     = Color(0xFFe6edf3);
  static const muted    = Color(0xFF8b949e);
  static const green    = Color(0xFF4ade80);
  static const red      = Color(0xFFf87171);
  static const yellow   = Color(0xFFfacc15);
}

Color statusColor(String s) {
  switch (s) {
    case 'success':   return C.green;
    case 'failure':   return C.red;
    case 'running':   return C.yellow;
    case 'cancelled': return C.muted;
    case 'skipped':   return C.muted;
    case 'waiting':   return C.muted;
    default:          return C.muted;
  }
}

IconData statusIcon(String s) {
  switch (s) {
    case 'success':   return Icons.check_circle;
    case 'failure':   return Icons.cancel;
    case 'running':   return Icons.pending;
    case 'waiting':   return Icons.hourglass_empty;
    case 'cancelled': return Icons.block;
    case 'skipped':   return Icons.skip_next;
    default:          return Icons.help_outline;
  }
}

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: C.bg,
  colorScheme: const ColorScheme.dark(
    surface: C.surface,
    primary: C.accent,
    secondary: C.accent2,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: C.surface2,
    labelStyle: const TextStyle(color: C.muted),
    hintStyle: const TextStyle(color: C.muted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: C.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: C.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: C.accent2),
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: C.text, fontSize: 14),
    bodySmall:  TextStyle(color: C.muted, fontSize: 12),
  ),
);
