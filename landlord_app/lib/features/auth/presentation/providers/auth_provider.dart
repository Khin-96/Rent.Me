import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../data/user_model.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  void finishLoading() {
    if (state.isLoading) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final secureStorage = _ref.read(secureStorageProvider);
      final token = await secureStorage.read(key: 'auth_token');

      if (token == null) {
        state = const AuthState();
        return;
      }

      final dio = _ref.read(dioProvider);
      final response = await dio
          .get('/auth/me')
          .timeout(const Duration(milliseconds: 700));

      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final user = UserModel.fromJson(userData);
        state = AuthState(user: user, token: token);
      } else {
        state = const AuthState();
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'] as String;
        final userData = response.data['user'];
        final user = UserModel.fromJson(userData);

        if (user.role != 'LANDLORD' && user.role != 'ADMIN') {
          state = state.copyWith(
            isLoading: false,
            error: 'Access denied: not a landlord or admin account',
          );
          return false;
        }

        final secureStorage = _ref.read(secureStorageProvider);
        await secureStorage.write(key: 'auth_token', value: token);
        await _ref.read(prefsProvider).setString('user_id', user.id);

        state = AuthState(user: user, token: token);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Login failed');
      return false;
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Login failed';
      state = state.copyWith(isLoading: false, error: message.toString());
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred');
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'LANDLORD',
        },
      );

      if (response.statusCode == 201) {
        final token = response.data['token'] as String;
        final userData = response.data['user'];
        final user = UserModel.fromJson(userData);

        final secureStorage = _ref.read(secureStorageProvider);
        await secureStorage.write(key: 'auth_token', value: token);
        await _ref.read(prefsProvider).setString('user_id', user.id);

        state = AuthState(user: user, token: token);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Registration failed');
      return false;
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Registration failed';
      state = state.copyWith(isLoading: false, error: message.toString());
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred');
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.delete(key: 'auth_token');
      final prefs = _ref.read(prefsProvider);
      await prefs.remove('user_id');
    } catch (_) {}
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
