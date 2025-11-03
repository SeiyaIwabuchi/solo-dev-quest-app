// T087: Offline indicator widget for app bar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_status_service.dart';

/// Widget that displays an offline indicator banner
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return connectivityStatus.when(
      data: (isOnline) {
        if (isOnline) {
          // T090: Show sync status when online
          return syncStatus.when(
            data: (status) {
              if (status == SyncStatus.syncing || status == SyncStatus.pending) {
                return Container(
                  color: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '同期中...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink(); // Hide when synced
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        }
        
        // T087: Show offline mode indicator
        return Container(
          color: Colors.orange.shade700,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                color: Colors.white,
                size: 14,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'オフラインモード',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// AppBar with offline indicator
/// This widget wraps a standard AppBar and displays the offline indicator below it
class AppBarWithOfflineIndicator extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const AppBarWithOfflineIndicator({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text(title),
            actions: actions,
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
          ),
          const OfflineIndicator(),
        ],
      ),
    );
  }

  @override
  Size get preferredSize {
    // Fixed size with buffer for indicator
    // AppBar: 56 (kToolbarHeight)
    // Indicator: up to 26 pixels (6 + 14 + 6)
    // Extra buffer: 8 pixels to prevent overflow
    return const Size.fromHeight(kToolbarHeight + 34);
  }
}
