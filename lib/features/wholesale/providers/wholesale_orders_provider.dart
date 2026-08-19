import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_lang.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_exception.dart';

// ---------------------------------------------------------------------------
// Data models — money as strings; never parse to float (D-07 / T-14-18)
// ---------------------------------------------------------------------------

class WholesaleOrderItem {
  final String id;
  final String factoryProductId;
  final String productName;
  final int qty;
  final int appliedTierMinQty;
  final String unitPriceTjsSnapshot; // MoneyString — never parse to float
  final String subtotalTjs; // MoneyString — never parse to float
  // Item photo (factory product image), if the API enriches it. Null today —
  // _ItemThumb (Zone-2 layout) renders the token fallback until the backend
  // enriches this field (mirrors B2C Order.items[].imageUrl, Phase 21).
  final String? imageUrl;

  const WholesaleOrderItem({
    required this.id,
    required this.factoryProductId,
    required this.productName,
    required this.qty,
    required this.appliedTierMinQty,
    required this.unitPriceTjsSnapshot,
    required this.subtotalTjs,
    this.imageUrl,
  });

  factory WholesaleOrderItem.fromJson(Map<String, dynamic> json) {
    return WholesaleOrderItem(
      id: json['id']?.toString() ?? '',
      factoryProductId: json['factoryProductId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      appliedTierMinQty: (json['appliedTierMinQty'] as num?)?.toInt() ?? 1,
      unitPriceTjsSnapshot: json['unitPriceTjsSnapshot']?.toString() ?? '0.00',
      subtotalTjs: json['subtotalTjs']?.toString() ?? '0.00',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class WholesaleOrder {
  final String id;
  final String factoryName;
  final String status;
  final String totalTjs; // MoneyString — never parse to float
  final String createdAt;
  final List<WholesaleOrderItem> items;
  final WholesaleShipment? shipment;
  // Phase 14 (D-03): the PaymentGroup this order was checked out under. Needed to
  // re-initiate payment for an unpaid (created) order — B2B pay is group-scoped
  // (/api/wholesale/payment-groups/:groupId/pay). Null for legacy/orphaned orders.
  final String? paymentGroupId;
  // Status of the latest uploaded receipt for this order's payment (null when no
  // receipt yet). Drives "pay" vs "receipt under review": the order stays `created`
  // until the payment confirms, so status alone can't reveal an in-flight receipt.
  // Values: checking | needs_review | awaiting_ai | approved_by_ai |
  //         approved_manually | rejected | duplicate | null.
  final String? latestReceiptStatus;
  // Normalized payment-review state from the API. B2B mirrors retail orders:
  // none -> show pay CTA, under_review -> suppress pay CTA, rejected -> show
  // rejection message and allow re-upload through the payment flow.
  final String receiptReviewStatus; // 'none' | 'under_review' | 'rejected'
  final String? receiptRejectionReason;
  // Coarse rejection category for an AI-only reject (no operator note):
  // 'amount_mismatch' | 'reference_missing' | 'duplicate' | 'generic' | null.
  final String? receiptRejectionCategory;

  const WholesaleOrder({
    required this.id,
    required this.factoryName,
    required this.status,
    required this.totalTjs,
    required this.createdAt,
    required this.items,
    this.shipment,
    this.paymentGroupId,
    this.latestReceiptStatus,
    this.receiptReviewStatus = 'none',
    this.receiptRejectionReason,
    this.receiptRejectionCategory,
  });

  /// True when a receipt is uploaded and not in a re-uploadable terminal state
  /// (rejected/duplicate). While true, the "continue payment" CTA is suppressed
  /// in favour of a "receipt under review" indicator.
  bool get hasReceiptInFlight {
    return receiptReviewStatus == 'under_review';
  }

  bool get hasRejectedReceipt => receiptReviewStatus == 'rejected';

  factory WholesaleOrder.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>?) ?? [];
    final shipmentJson = json['shipment'] as Map<String, dynamic>?;
    final latestReceiptStatus = json['latestReceiptStatus']?.toString();
    final rawReason = json['receiptRejectionReason']?.toString();
    final reason =
        (rawReason != null && rawReason.trim().isNotEmpty) ? rawReason : null;
    return WholesaleOrder(
      id: json['id']?.toString() ?? '',
      factoryName: json['factoryName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'created',
      totalTjs: json['totalTjs']?.toString() ?? '0.00',
      createdAt: json['createdAt']?.toString() ?? '',
      paymentGroupId: json['paymentGroupId']?.toString(),
      latestReceiptStatus: latestReceiptStatus,
      receiptReviewStatus: json['receiptReviewStatus']?.toString() ??
          _receiptReviewStatusFromLatest(latestReceiptStatus),
      receiptRejectionReason: reason,
      receiptRejectionCategory: json['receiptRejectionCategory']?.toString(),
      items: itemsJson
          .map((e) => WholesaleOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shipment: shipmentJson != null
          ? WholesaleShipment.fromJson(shipmentJson)
          : null,
    );
  }
}

String _receiptReviewStatusFromLatest(String? status) {
  switch (status) {
    case 'awaiting_ai':
    case 'checking':
    case 'needs_review':
    case 'approved_by_ai':
    case 'approved_manually':
      return 'under_review';
    case 'rejected':
    case 'duplicate':
      return 'rejected';
    default:
      return 'none';
  }
}

class WholesaleShipment {
  final String id;
  final String stage;
  final String? trackingCode;
  final List<WholesaleShipmentStage> stages;

  const WholesaleShipment({
    required this.id,
    required this.stage,
    this.trackingCode,
    this.stages = const [],
  });

  factory WholesaleShipment.fromJson(Map<String, dynamic> json) {
    final stagesJson = (json['stages'] as List<dynamic>?) ?? [];
    return WholesaleShipment(
      id: json['id']?.toString() ?? '',
      stage: json['stage']?.toString() ?? 'awaiting',
      // API serializes the field as `trackingNo` (Shipment.trackingNo); keep the
      // legacy `trackingCode` key as a fallback.
      trackingCode:
          json['trackingNo']?.toString() ?? json['trackingCode']?.toString(),
      stages: stagesJson
          .map(
              (e) => WholesaleShipmentStage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WholesaleShipmentStage {
  final String stage;
  final String reachedAt;

  const WholesaleShipmentStage({
    required this.stage,
    required this.reachedAt,
  });

  factory WholesaleShipmentStage.fromJson(Map<String, dynamic> json) {
    return WholesaleShipmentStage(
      stage: json['stage']?.toString() ?? '',
      reachedAt: json['reachedAt']?.toString() ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// WholesaleOrdersNotifier — list of own orders
// ---------------------------------------------------------------------------

class WholesaleOrdersNotifier
    extends StateNotifier<AsyncValue<List<WholesaleOrder>>> {
  final DioClient _client;
  final Ref _ref;

  WholesaleOrdersNotifier({required DioClient client, required Ref ref})
      : _client = client,
        _ref = ref,
        super(const AsyncValue.loading());

  String get _apiLang => apiLang(_ref.read(authProvider).locale);

  /// GET /api/wholesale/orders?lang=
  Future<void> fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get(
        '/api/wholesale/orders',
        queryParameters: {'lang': _apiLang},
      );
      final data = res.data;
      List<dynamic> list;
      if (data is Map && data.containsKey('items')) {
        list = data['items'] as List<dynamic>;
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      final orders = list
          .map((e) => WholesaleOrder.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(orders);
    } on DioException catch (e) {
      final err =
          e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load wholesale orders'),
        StackTrace.current,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// WholesaleOrderDetailNotifier — single order detail, family by id
// ---------------------------------------------------------------------------

class WholesaleOrderDetailNotifier
    extends StateNotifier<AsyncValue<WholesaleOrder>> {
  final DioClient _client;
  final String _locale;

  WholesaleOrderDetailNotifier(
      {required DioClient client, required String locale})
      : _client = client,
        _locale = locale,
        super(const AsyncValue.loading());

  Future<void> fetch(String orderId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.get(
        '/api/wholesale/orders/$orderId',
        queryParameters: {'lang': apiLang(_locale)},
      );
      state = AsyncValue.data(
        WholesaleOrder.fromJson(res.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final err =
          e.error is DomainException ? e.error as DomainException : null;
      state = AsyncValue.error(
        err ?? Exception('Failed to load wholesale order'),
        StackTrace.current,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Wholesale orders list. autoDispose so 403-gate state clears on pop.
final wholesaleOrdersProvider = StateNotifierProvider.autoDispose<
    WholesaleOrdersNotifier, AsyncValue<List<WholesaleOrder>>>((ref) {
  final client = ref.watch(dioClientProvider);
  return WholesaleOrdersNotifier(client: client, ref: ref)..fetchOrders();
});

/// Wholesale order detail — family by orderId.
final wholesaleOrderDetailProvider = StateNotifierProvider.autoDispose
    .family<WholesaleOrderDetailNotifier, AsyncValue<WholesaleOrder>, String>(
        (ref, orderId) {
  final client = ref.watch(dioClientProvider);
  final locale = ref.watch(authProvider).locale;
  return WholesaleOrderDetailNotifier(client: client, locale: locale)
    ..fetch(orderId);
});
