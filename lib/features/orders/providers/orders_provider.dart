import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/error_messages.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_lang.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final String unitPriceTjs; // Money string — never parse to float (D-07)
  final String status;
  final OrderItemCancellation? cancellation;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.quantity,
    required this.unitPriceTjs,
    this.status = 'active',
    this.cancellation,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      quantity: (json['qty'] as num?)?.toInt() ?? 1,
      unitPriceTjs: json['unitPriceTjs']?.toString() ?? '0.00',
      status: json['status']?.toString() ?? 'active',
      cancellation: json['cancellation'] is Map<String, dynamic>
          ? OrderItemCancellation.fromJson(
              json['cancellation'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ItemRefund {
  final String id;
  final String amountTjs;
  final String currency;
  final String status;
  final int attemptCount;
  final String? completedAt;

  const ItemRefund({
    required this.id,
    required this.amountTjs,
    required this.currency,
    required this.status,
    required this.attemptCount,
    this.completedAt,
  });

  factory ItemRefund.fromJson(Map<String, dynamic> json) => ItemRefund(
        id: json['id']?.toString() ?? '',
        amountTjs: json['amountTjs']?.toString() ?? '0.00',
        currency: json['currency']?.toString() ?? 'TJS',
        status: json['status']?.toString() ?? 'pending',
        attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
        completedAt: json['completedAt']?.toString(),
      );
}

class OrderItemCancellation {
  final String reason;
  final String customerMessage;
  final String? cancelledAt;
  final ItemRefund? refund;

  const OrderItemCancellation({
    required this.reason,
    required this.customerMessage,
    this.cancelledAt,
    this.refund,
  });

  factory OrderItemCancellation.fromJson(Map<String, dynamic> json) =>
      OrderItemCancellation(
        reason: json['reason']?.toString() ?? 'other',
        customerMessage: json['customerMessage']?.toString() ?? '',
        cancelledAt: json['cancelledAt']?.toString(),
        refund: json['refund'] is Map<String, dynamic>
            ? ItemRefund.fromJson(json['refund'] as Map<String, dynamic>)
            : null,
      );
}

class ShipmentStageEntry {
  final String stage;
  final String? note;
  final String? createdAt;

  const ShipmentStageEntry({required this.stage, this.note, this.createdAt});

  factory ShipmentStageEntry.fromJson(Map<String, dynamic> json) {
    return ShipmentStageEntry(
      stage: json['stage']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class Shipment {
  final String id;
  final String stage;
  final String? trackingCode;
  final List<ShipmentStageEntry> stageHistory;

  const Shipment({
    required this.id,
    required this.stage,
    this.trackingCode,
    required this.stageHistory,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    final history = (json['stageHistory'] as List<dynamic>?)
            ?.map((e) => ShipmentStageEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return Shipment(
      id: json['id']?.toString() ?? '',
      stage: json['stage']?.toString() ?? 'pending',
      trackingCode: json['trackingNo']?.toString(),
      stageHistory: history,
    );
  }
}

class Order {
  final String id;
  final String status;
  final String totalTjs; // Money string — never parse to float (D-07)
  final String currentTotalTjs;
  final String cancelledTotalTjs;
  final String refundedTotalTjs;
  final String createdAt;
  final List<OrderItem> items;
  final Shipment? shipment;
  final String receiptReviewStatus; // 'none' | 'under_review' | 'rejected'
  // Operator's free-text rejection note when the receipt was MANUALLY rejected.
  // null for AI-only rejections (client shows a localized category message instead).
  final String? receiptRejectionReason;
  // Coarse rejection category for an AI-only reject (no operator note):
  // 'amount_mismatch' | 'reference_missing' | 'duplicate' | 'generic' | null.
  final String? receiptRejectionCategory;

  const Order({
    required this.id,
    required this.status,
    required this.totalTjs,
    required this.currentTotalTjs,
    required this.cancelledTotalTjs,
    required this.refundedTotalTjs,
    required this.createdAt,
    required this.items,
    this.shipment,
    this.receiptReviewStatus = 'none',
    this.receiptRejectionReason,
    this.receiptRejectionCategory,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final shipmentJson = json['shipment'] as Map<String, dynamic>?;
    // Normalize empty/whitespace reason to null so the UI can rely on a simple
    // null-check before showing the operator note.
    final rawReason = json['receiptRejectionReason']?.toString();
    final reason = (rawReason != null && rawReason.trim().isNotEmpty) ? rawReason : null;
    return Order(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'created',
      totalTjs: json['totalTjs']?.toString() ?? '0.00',
      currentTotalTjs:
          json['currentTotalTjs']?.toString() ?? json['totalTjs']?.toString() ?? '0.00',
      cancelledTotalTjs: json['cancelledTotalTjs']?.toString() ?? '0.00',
      refundedTotalTjs: json['refundedTotalTjs']?.toString() ?? '0.00',
      createdAt: json['createdAt']?.toString() ?? '',
      items: items,
      shipment: shipmentJson != null ? Shipment.fromJson(shipmentJson) : null,
      receiptReviewStatus: json['receiptReviewStatus']?.toString() ?? 'none',
      receiptRejectionReason: reason,
      receiptRejectionCategory: json['receiptRejectionCategory']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifiers
// ---------------------------------------------------------------------------

class OrdersNotifier extends StateNotifier<OrdersState> {
  final DioClient _client;
  final Ref _ref;

  OrdersNotifier({required DioClient client, required Ref ref})
      : _client = client,
        _ref = ref,
        super(const OrdersState());

  /// GET /api/orders?lang=
  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get('/api/orders', queryParameters: {
        'lang': apiLang(_ref.read(authProvider).locale),
      });
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
        orders: list
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoading: false, error: msg);
    }
  }
}

class OrderDetailNotifier extends StateNotifier<AsyncValue<Order>> {
  final DioClient _client;
  final Ref _ref;

  OrderDetailNotifier({required DioClient client, required Ref ref})
      : _client = client,
        _ref = ref,
        super(const AsyncValue.loading());

  /// GET /api/orders/{id}?lang= — includes shipment tracking
  Future<void> fetchOrder(String orderId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get('/api/orders/$orderId', queryParameters: {
        'lang': apiLang(_ref.read(authProvider).locale),
      });
      state = AsyncValue.data(
        Order.fromJson(res.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final err = e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load order'),
        StackTrace.current,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final client = ref.watch(dioClientProvider);
  return OrdersNotifier(client: client, ref: ref);
});

// autoDispose: when OrderScreen is popped no widget watches this provider, so
// the notifier is disposed. Re-opening the same order rebuilds it and re-runs
// fetchOrder — otherwise the cached notifier keeps the stale status forever.
final orderDetailProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailNotifier, AsyncValue<Order>, String>(
  (ref, orderId) {
    final client = ref.watch(dioClientProvider);
    return OrderDetailNotifier(client: client, ref: ref)..fetchOrder(orderId);
  },
);
