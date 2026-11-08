import 'package:flutter/material.dart';

final class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({required this.status, super.key});

  final String status;

  static String label(String status) => switch (status) {
    'pending' => 'Menunggu',
    'confirmed' => 'Dikonfirmasi',
    'assigned' => 'Diterima staff',
    'on_the_way' => 'Dalam perjalanan',
    'in_progress' => 'Dikerjakan',
    'completed' => 'Selesai',
    'cancelled' => 'Dibatalkan',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (status) {
      'completed' => (const Color(0xFF15803D), const Color(0xFFDCFCE7)),
      'cancelled' => (const Color(0xFFB91C1C), const Color(0xFFFEE2E2)),
      'on_the_way' ||
      'in_progress' => (const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
      _ => (const Color(0xFFB45309), const Color(0xFFFEF3C7)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label(status),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
