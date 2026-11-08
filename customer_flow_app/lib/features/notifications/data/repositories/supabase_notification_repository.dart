import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

final class SupabaseNotificationRepository implements NotificationRepository {
  const SupabaseNotificationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AppNotification>> getNotifications() async {
    final rows = await _client
        .from('notifications')
        .select('id, booking_id, title, body, type, read_at, created_at')
        .order('created_at', ascending: false);
    return rows.map(_mapNotification).toList(growable: false);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  AppNotification _mapNotification(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      bookingId: row['booking_id'] as String?,
      title: row['title'] as String,
      body: row['body'] as String,
      type: row['type'] as String,
      readAt: row['read_at'] == null
          ? null
          : DateTime.parse(row['read_at'] as String).toLocal(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
