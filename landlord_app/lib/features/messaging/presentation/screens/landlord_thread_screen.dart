import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/inbox_provider.dart';

class LandlordThreadScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String? propertyId;
  final String? otherUserName;

  const LandlordThreadScreen({
    super.key,
    required this.otherUserId,
    this.propertyId,
    this.otherUserName,
  });

  @override
  ConsumerState<LandlordThreadScreen> createState() => _LandlordThreadScreenState();
}

class _LandlordThreadScreenState extends ConsumerState<LandlordThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final args = (userId: widget.otherUserId, propertyId: widget.propertyId);
    await ref.read(threadProviderFamily(args).notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final args = (userId: widget.otherUserId, propertyId: widget.propertyId);
    final state = ref.watch(threadProviderFamily(args));
    final currentUserId = ref.read(prefsProvider).getString('user_id');

    _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName ?? 'Tenant',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (widget.propertyId != null)
              Text('Property inquiry',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(threadProviderFamily(args).notifier).fetchMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : state.messages.isEmpty
                    ? Center(
                        child: Text('No messages yet. Start the conversation.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.gray400)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          final isMine = msg.senderId == currentUserId;
                          return _MessageBubble(content: msg.content, isMine: isMine, time: msg.createdAt)
                              .animate(delay: Duration(milliseconds: index * 20))
                              .slideY(begin: 0.1, duration: 250.ms)
                              .fadeIn();
                        },
                      ),
          ),
          _InputBar(
            controller: _messageController,
            isSending: state.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMine;
  final DateTime time;

  const _MessageBubble({required this.content, required this.isMine, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(content,
                    style: TextStyle(
                        fontSize: 14,
                        color: isMine ? AppColors.white : AppColors.gray800,
                        height: 1.4)),
                const SizedBox(height: 4),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 10,
                      color: isMine ? AppColors.white.withOpacity(0.6) : AppColors.gray400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.isSending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.gray200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.gray200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: isSending ? AppColors.gray300 : AppColors.primary, shape: BoxShape.circle),
              child: isSending
                  ? const Center(
                      child: SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)))
                  : const Icon(Icons.send_rounded, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
