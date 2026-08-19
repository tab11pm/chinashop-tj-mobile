import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/error_messages.dart';
import '../../auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class UserAddress {
  final String id;
  final String region;
  final String city;
  final String line;
  final String phone;
  final String? comment;
  final bool isDefault;

  const UserAddress({
    required this.id,
    required this.region,
    required this.city,
    required this.line,
    required this.phone,
    this.comment,
    this.isDefault = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      line: json['line']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      comment: json['comment']?.toString(),
      isDefault: (json['isDefault'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'region': region,
        'city': city,
        'line': line,
        'phone': phone,
        if (comment != null) 'comment': comment,
        'isDefault': isDefault,
      };

  String get displayLine => '$region, $city, $line';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ProfileState {
  final List<UserAddress> addresses;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    List<UserAddress>? addresses,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProfileNotifier extends StateNotifier<ProfileState> {
  final DioClient _client;

  ProfileNotifier({required DioClient client})
      : _client = client,
        super(const ProfileState());

  /// GET /api/addresses (Phase 5 ADDR-01 endpoint)
  Future<void> fetchAddresses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get('/api/addresses');
      final data = res.data;
      List<dynamic> list;
      if (data is Map && data.containsKey('items')) {
        list = data['items'] as List<dynamic>;
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      state = state.copyWith(
        isLoading: false,
        addresses: list
            .map((e) => UserAddress.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  /// POST /api/addresses
  Future<void> createAddress(Map<String, dynamic> body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.post('/api/addresses', data: body);
      await fetchAddresses();
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoading: false, error: msg);
      rethrow;
    }
  }

  /// PATCH /api/addresses/{id}
  Future<void> updateAddress(String id, Map<String, dynamic> body) async {
    try {
      await _client.patch('/api/addresses/$id', data: body);
      await fetchAddresses();
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(error: msg);
      rethrow;
    }
  }

  /// DELETE /api/addresses/{id}
  Future<void> deleteAddress(String id) async {
    try {
      await _client.delete('/api/addresses/$id');
      state = state.copyWith(
        addresses: state.addresses.where((a) => a.id != id).toList(),
      );
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(error: msg);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final client = ref.watch(dioClientProvider);
  return ProfileNotifier(client: client);
});
