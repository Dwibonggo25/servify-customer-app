import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

final class NotificationPage extends StatefulWidget {
  const NotificationPage({
    required this.repository,
    required this.staffMode,
    super.key,
  });

  final NotificationRepository repository;
  final bool staffMode;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

final class _NotificationPageState extends State<NotificationPage> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = widget.repository.getNotifications();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => setState(_reload),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            );
          }
          final items = snapshot.data ?? const <AppNotification>[];
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada notifikasi.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _NotificationTile(
                item: items[index],
                onTap: () => _open(items[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) await widget.repository.markAsRead(item.id);
    if (!mounted) return;
    final bookingId = item.bookingId;
    if (bookingId != null) {
      context.push(
        widget.staffMode ? '/staff/bookings/$bookingId' : '/orders/$bookingId',
      );
    } else {
      setState(_reload);
    }
  }
}

final class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: item.isRead ? AppColors.surface : const Color(0xFFEDEBFF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(Icons.notifications_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(item.body, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.date(item.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              const CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
          ],
        ),
      ),
    ),
  );
}
