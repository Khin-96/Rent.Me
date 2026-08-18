import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../data/message_model.dart';

class InboxState {
  final List<ThreadSummary> threads;
  final bool isLoading;
  final String? error;

  const InboxState({this.threads = const [], this.isLoading = false, this.error});

  InboxState copyWith({List<ThreadSummary>? threads, bool? isLoading, String? error}) {
    return InboxState(
        threads: threads ?? this.threads,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error);
  }
}

class InboxNotifier extends StateNotifier<InboxState> {
  final Ref _ref;
  InboxNotifier(this._ref) : super(const InboxState()) {
    fetchInbox();
  }

  Future<void> fetchInbox() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = _ref.read(prefsProvider);
      final userId = prefs.getString('user_id');
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'Not logged in');
        return;
      }
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/inquiries', queryParameters: {'userId': userId});
      if (response.statusCode == 200) {
        final inquiries = response.data['inquiries'] as List<dynamic>;
        final Map<String, ThreadSummary> threadMap = {};
        for (final inquiry in inquiries) {
          final inq = inquiry as Map<String, dynamic>;
          final tenantId = inq['tenantId'] as String?;
          final tenant = inq['tenant'] as Map<String, dynamic>?;
          if (tenantId == null) continue;
          final messages = (inq['messages'] as List<dynamic>?) ?? [];
          final lastMsg = messages.isNotEmpty
              ? messages.last as Map<String, dynamic>
              : {'content': inq['message'] ?? '', 'createdAt': inq['createdAt']};
          final key = '$tenantId-${inq['propertyId']}';
          threadMap[key] = ThreadSummary(
            otherUserId: tenantId,
            otherUserName: tenant?['name'] as String? ?? 'Tenant',
            propertyId: inq['propertyId'] as String?,
            propertyTitle: (inq['property'] as Map<String, dynamic>?)?['title'] as String?,
            lastMessage: lastMsg['content'] as String? ?? '',
            lastMessageAt:
                DateTime.tryParse(lastMsg['createdAt'] as String? ?? '') ?? DateTime.now(),
          );
        }
        final threads = threadMap.values.toList()
          ..sort((ThreadSummary a, ThreadSummary b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        state = InboxState(threads: threads);
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data['error']?.toString() ?? 'Failed');
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error');
    }
  }
}

class ThreadState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const ThreadState({this.messages = const [], this.isLoading = false, this.isSending = false, this.error});

  ThreadState copyWith({List<MessageModel>? messages, bool? isLoading, bool? isSending, String? error}) {
    return ThreadState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        error: error ?? this.error);
  }
}

class ThreadNotifier extends StateNotifier<ThreadState> {
  final Ref _ref;
  final String otherUserId;
  final String? propertyId;

  ThreadNotifier(this._ref, this.otherUserId, this.propertyId) : super(const ThreadState()) {
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = _ref.read(prefsProvider);
      final userId = prefs.getString('user_id');
      if (userId == null) return;
      final dio = _ref.read(dioProvider);
      final params = <String, dynamic>{'withUser': otherUserId};
      if (propertyId != null) params['propertyId'] = propertyId;
      final response = await dio.get('/inquiries/thread', queryParameters: params);
      if (response.statusCode == 200) {
        final msgs = (response.data['messages'] as List<dynamic>)
            .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
            .toList();
        state = ThreadState(messages: msgs);
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data['error']?.toString() ?? 'Failed');
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error');
    }
  }

  Future<bool> sendMessage(String content) async {
    state = state.copyWith(isSending: true);
    try {
      final prefs = _ref.read(prefsProvider);
      final userId = prefs.getString('user_id');
      if (userId == null) return false;
      final dio = _ref.read(dioProvider);
      final response = await dio.post('/inquiries/message', data: {
        'receiverId': otherUserId,
        'content': content,
        if (propertyId != null) 'propertyId': propertyId,
      });
      if (response.statusCode == 201) {
        final msg = MessageModel.fromJson(response.data['message'] as Map<String, dynamic>);
        state = state.copyWith(messages: [...state.messages, msg], isSending: false);
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isSending: false);
    return false;
  }
}

final inboxProvider = StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  return InboxNotifier(ref);
});

final threadProviderFamily =
    StateNotifierProvider.family<ThreadNotifier, ThreadState, ({String userId, String? propertyId})>(
  (ref, args) => ThreadNotifier(ref, args.userId, args.propertyId),
);
