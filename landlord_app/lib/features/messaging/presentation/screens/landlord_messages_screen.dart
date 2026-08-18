import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/message_model.dart';
import '../providers/inbox_provider.dart';

class LandlordMessagesScreen extends ConsumerWidget {
  const LandlordMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inboxProvider);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      OutlinedButton(
                          onPressed: () => ref.read(inboxProvider.notifier).fetchInbox(),
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : state.threads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                                color: AppColors.gray100, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.chat_bubble_outline_rounded,
                                size: 30, color: AppColors.gray400),
                          ),
                          const SizedBox(height: 16),
                          Text('No messages yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('Tenant inquiries will appear here.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.gray400)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref.read(inboxProvider.notifier).fetchInbox(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.threads.length,
                        itemBuilder: (context, index) {
                          final thread = state.threads[index];
                          return _ThreadCard(thread: thread)
                              .animate(delay: Duration(milliseconds: index * 50))
                              .slideY(begin: 0.1, duration: 300.ms)
                              .fadeIn();
                        },
                      ),
                    ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final ThreadSummary thread;
  const _ThreadCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    final initials = thread.otherUserName.isNotEmpty
        ? thread.otherUserName.trim().split(' ').take(2).map((n) => n[0].toUpperCase()).join()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.gray200,
          child: Text(initials, style: const TextStyle(color: AppColors.gray700, fontWeight: FontWeight.w600)),
        ),
        title: Text(thread.otherUserName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thread.propertyTitle != null) ...[
              const SizedBox(height: 2),
              Text(thread.propertyTitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(thread.lastMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        onTap: () => context.push(
            '/messages/${thread.otherUserId}?propertyId=${thread.propertyId ?? ""}'),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray300, size: 20),
      ),
    );
  }
}
