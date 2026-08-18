import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/inbox_provider.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inboxProvider.notifier).fetchInquiries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxProvider);
    final inquiries = inboxState.inquiries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(inboxProvider.notifier).fetchInquiries();
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (inboxState.isLoading && inquiries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (inquiries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.gray400),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Contact a caretaker to start a conversation.', style: TextStyle(color: AppColors.gray500)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(inboxProvider.notifier).fetchInquiries(),
            child: ListView.builder(
              itemCount: inquiries.length,
              itemBuilder: (context, index) {
                final inquiry = inquiries[index];
                final lastMsg = inquiry.messages.isNotEmpty ? inquiry.messages.last : null;
                final isUnread = !inquiry.isReadByTenant;

                return Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.gray100)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    onTap: () {
                      context.go('/messages/${inquiry.id}');
                    },
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.gray200,
                      backgroundImage: inquiry.landlord?.avatarUrl != null
                          ? NetworkImage(inquiry.landlord!.avatarUrl!)
                          : null,
                      child: inquiry.landlord?.avatarUrl == null
                          ? Text(
                              (inquiry.landlord?.name ?? 'C')[0],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            )
                          : null,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          inquiry.landlord?.name ?? 'Caretaker',
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          Formatters.timeAgo(inquiry.updatedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (lastMsg != null)
                          Text(
                            lastMsg.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isUnread ? AppColors.primary : AppColors.gray500,
                              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          inquiry.property?.name ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gray400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: isUnread
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
