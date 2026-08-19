import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/error_messages.dart';
import '../../auth/providers/auth_provider.dart';

class CustomerNotification {
  final String id;
  final String type;
  final String? orderId;
  final String? orderItemId;
  final Map<String, dynamic> payload;
  final String? readAt;
  final String createdAt;

  const CustomerNotification({
    required this.id,
    required this.type,
    this.orderId,
    this.orderItemId,
    required this.payload,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory CustomerNotification.fromJson(Map<String, dynamic> json) =>
      CustomerNotification(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        orderId: json['orderId']?.toString(),
        orderItemId: json['orderItemId']?.toString(),
        payload: json['payload'] is Map
            ? Map<String, dynamic>.from(json['payload'] as Map)
            : const {},
        readAt: json['readAt']?.toString(),
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class NotificationsState {
  final List<CustomerNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<CustomerNotification>? notifications,
    bool? isLoading,
    String? error,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final DioClient _client;

  NotificationsNotifier({required DioClient client})
      : _client = client,
        super(const NotificationsState());

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _client.get('/api/notifications');
      final rows = response.data is List ? response.data as List<dynamic> : const [];
      state = state.copyWith(
        isLoading: false,
        notifications: rows
            .map((row) => CustomerNotification.fromJson(
                  Map<String, dynamic>.from(row as Map),
                ))
            .toList(),
      );
    } on DioException catch (error) {
      state = state.copyWith(isLoading: false, error: errorCodeOf(error));
    }
  }

  Future<void> markRead(String id) async {
    final current = state.notifications;
    try {
      await _client.patch('/api/notifications/$id/read');
      state = state.copyWith(
        notifications: current
            .map((notification) => notification.id == id
                ? CustomerNotification(
                    id: notification.id,
                    type: notification.type,
                    orderId: notification.orderId,
                    orderItemId: notification.orderItemId,
                    payload: notification.payload,
                    readAt: DateTime.now().toUtc().toIso8601String(),
                    createdAt: notification.createdAt,
                  )
                : notification)
            .toList(),
      );
    } on DioException catch (error) {
      state = state.copyWith(error: errorCodeOf(error));
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(client: ref.watch(dioClientProvider));
});
