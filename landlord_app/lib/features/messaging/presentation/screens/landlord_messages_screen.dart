import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/inquiry_model.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(inboxProvider.notifier).fetchInbox(),
          ),
        ],
      ),
      body: state.isLoading && state.inquiries.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null && state.inquiries.isEmpty
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
              : state.inquiries.isEmpty
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
                        itemCount: state.inquiries.length,
                        itemBuilder: (context, index) {
                          final inquiry = state.inquiries[index];
                          return _InquiryCard(inquiry: inquiry)
                              .animate(delay: Duration(milliseconds: index * 40))
                              .slideY(begin: 0.1, duration: 250.ms)
                              .fadeIn();
                        },
                      ),
                    ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final InquiryModel inquiry;
  const _InquiryCard({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final tenantName = inquiry.tenant?.name ?? 'Tenant';
    final initials = tenantName.isNotEmpty
        ? tenantName.trim().split(' ').take(2).map((n) => n[0].toUpperCase()).join()
        : '?';
    final lastMsg = inquiry.messages.isNotEmpty ? inquiry.messages.last : null;
    final isUnread = !inquiry.isReadByLandlord;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isUnread ? AppColors.primary.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isUnread ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isUnread ? AppColors.primary : AppColors.gray200,
          backgroundImage: inquiry.tenant?.avatarUrl != null
              ? NetworkImage(inquiry.tenant!.avatarUrl!)
              : null,
          child: inquiry.tenant?.avatarUrl == null
              ? Text(
                  initials,
                  style: TextStyle(
                    color: isUnread ? AppColors.white : AppColors.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                tenantName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${inquiry.updatedAt.hour.toString().padLeft(2, '0')}:${inquiry.updatedAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: isUnread ? AppColors.primary : AppColors.gray400,
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (inquiry.property != null) ...[
              const SizedBox(height: 3),
              Text(
                inquiry.property!.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              lastMsg?.body ?? inquiry.subject,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isUnread ? AppColors.gray900 : AppColors.gray500,
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : const Icon(Icons.chevron_right_rounded, color: AppColors.gray300, size: 20),
        onTap: () => context.push('/messages/${inquiry.id}'),
      ),
    );
  }
}
