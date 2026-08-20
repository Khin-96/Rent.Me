import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../data/inquiry_model.dart';

class InboxState {
  final List<InquiryModel> inquiries;
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final InquiryModel? activeInquiry;

  const InboxState({
    this.inquiries = const [],
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.activeInquiry,
  });

  InboxState copyWith({
    List<InquiryModel>? inquiries,
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    InquiryModel? activeInquiry,
  }) {
    return InboxState(
      inquiries: inquiries ?? this.inquiries,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
      activeInquiry: activeInquiry ?? this.activeInquiry,
    );
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
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/inquiries');
      if (response.statusCode == 200) {
        final list = response.data as List;
        final inquiries = list.map((item) => InquiryModel.fromJson(item as Map<String, dynamic>)).toList();
        state = state.copyWith(inquiries: inquiries, isLoading: false);
      }
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Failed to load inbox';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
    }
  }

  Future<void> fetchMessages(String inquiryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/inquiries/$inquiryId/messages');
      if (response.statusCode == 200) {
        final inquiryData = response.data['inquiry'];
        final messagesData = response.data['messages'] as List;

        final inquiry = InquiryModel.fromJson(inquiryData as Map<String, dynamic>);
        final messages = messagesData
            .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Update read status in the inquiries list locally
        final updatedInquiries = state.inquiries.map((inq) {
          if (inq.id == inquiryId) {
            return InquiryModel(
              id: inq.id,
              tenantId: inq.tenantId,
              landlordId: inq.landlordId,
              propertyId: inq.propertyId,
              subject: inq.subject,
              status: inq.status,
              isReadByLandlord: true,
              isReadByTenant: inq.isReadByTenant,
              createdAt: inq.createdAt,
              updatedAt: inq.updatedAt,
              messages: inq.messages,
              property: inq.property,
              tenant: inq.tenant,
            );
          }
          return inq;
        }).toList();

        state = state.copyWith(
          inquiries: updatedInquiries,
          activeInquiry: inquiry,
          messages: messages,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Failed to load messages';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
    }
  }

  Future<bool> sendMessage(String inquiryId, String body) async {
    state = state.copyWith(isSending: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        '/inquiries/$inquiryId/messages',
        data: {'body': body},
      );
      if (response.statusCode == 201) {
        final newMessage = MessageModel.fromJson(response.data as Map<String, dynamic>);
        final updatedMessages = List<MessageModel>.from(state.messages)..add(newMessage);

        state = state.copyWith(
          messages: updatedMessages,
          isSending: false,
        );
        fetchInbox();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Failed to send message';
      state = state.copyWith(isSending: false, error: msg.toString());
      return false;
    } catch (_) {
      state = state.copyWith(isSending: false, error: 'An unexpected error occurred');
      return false;
    }
  }
}

final inboxProvider = StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  return InboxNotifier(ref);
});
