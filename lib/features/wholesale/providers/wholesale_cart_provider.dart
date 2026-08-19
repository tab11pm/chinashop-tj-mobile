import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ref
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/error_messages.dart';
import '../../../core/api/api_lang.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payment_receipts/providers/payment_receipt_provider.dart';

// ---------------------------------------------------------------------------
// Data models — money as strings; never parse to float (D-07 / T-14-18)
// ---------------------------------------------------------------------------

class WholesaleCartItem {
  final String id;
  final String factoryProductId;
  final String factoryName;
  final String productName;
  final int qty;
  final String unitPriceTjs; // MoneyString — never parse to float
  final String subtotalTjs; // MoneyString — never parse to float
  final int moq;
  final int? appliedTierMinQty;

  const WholesaleCartItem({
    required this.id,
    required this.factoryProductId,
    required this.factoryName,
    required this.productName,
    required this.qty,
    required this.unitPriceTjs,
    required this.subtotalTjs,
    required this.moq,
    this.appliedTierMinQty,
  });

  factory WholesaleCartItem.fromJson(Map<String, dynamic> json) {
    return WholesaleCartItem(
      id: json['id']?.toString() ?? '',
      factoryProductId: json['factoryProductId']?.toString() ?? '',
      factoryName: json['factoryName']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      unitPriceTjs: json['unitPriceTjs']?.toString() ?? '0.00',
      subtotalTjs: json['subtotalTjs']?.toString() ?? '0.00',
      moq: (json['moq'] as num?)?.toInt() ?? 1,
      appliedTierMinQty: (json['appliedTierMinQty'] as num?)?.toInt(),
    );
  }
}

class WholesaleCheckoutResult {
  final String paymentGroupId;
  final List<dynamic> orders;
  final String totalTjs; // MoneyString — never parse to float

  const WholesaleCheckoutResult({
    required this.paymentGroupId,
    required this.orders,
    required this.totalTjs,
  });

  factory WholesaleCheckoutResult.fromJson(Map<String, dynamic> json) {
    return WholesaleCheckoutResult(
      paymentGroupId: json['paymentGroupId']?.toString() ?? '',
      orders: (json['orders'] as List<dynamic>?) ?? [],
      totalTjs: json['totalTjs']?.toString() ?? '0.00',
    );
  }
}

class WholesaleCartState {
  final List<WholesaleCartItem> items;
  final bool isLoading;
  final String? error;
  final WholesaleCheckoutResult? lastCheckout;

  const WholesaleCartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.lastCheckout,
  });

  WholesaleCartState copyWith({
    List<WholesaleCartItem>? items,
    bool? isLoading,
    String? error,
    WholesaleCheckoutResult? lastCheckout,
  }) {
    return WholesaleCartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastCheckout: lastCheckout ?? this.lastCheckout,
    );
  }

  bool get hasMoqError => items.any((item) => item.qty < item.moq);
}

// ---------------------------------------------------------------------------
// Integer tiins helpers (D-07 — no float arithmetic)
// ---------------------------------------------------------------------------

/// Parse a MoneyString '123.45' into integer tiins (12345). No float involved.
int _parseTiins(String moneyStr) {
  final parts = moneyStr.split('.');
  final whole = int.tryParse(parts[0]) ?? 0;
  final frac = parts.length > 1
      ? int.tryParse(parts[1].padRight(2, '0').substring(0, 2)) ?? 0
      : 0;
  return whole * 100 + frac;
}

/// Convert integer tiins back to a '123.45' MoneyString. No float involved.
String _tiinsToString(int tiins) {
  return '${tiins ~/ 100}.${(tiins % 100).toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// WholesaleCartNotifier
// ---------------------------------------------------------------------------

class WholesaleCartNotifier extends StateNotifier<WholesaleCartState> {
  final DioClient _client;
  final Ref _ref;

  /// Per-item debounce timers keyed by factoryProductId.
  final Map<String, Timer> _debounceTimers = {};

  /// Latest pending qty per factoryProductId (written on each tap, read when timer fires).
  final Map<String, int> _pendingQty = {};

  WholesaleCartNotifier({required DioClient client, required Ref ref})
      : _client = client,
        _ref = ref,
        super(const WholesaleCartState());

  String get _lang => apiLang(_ref.read(authProvider).locale);

  /// GET /api/wholesale/cart?lang=
  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(
        '/api/wholesale/cart',
        queryParameters: {'lang': _lang},
      );
      final data = res.data as Map<String, dynamic>;
      final list = (data['items'] as List<dynamic>?) ?? [];
      state = state.copyWith(
        isLoading: false,
        items: list
            .map((e) => WholesaleCartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  /// POST /api/wholesale/cart/items { factoryProductId, qty }
  Future<void> addItem({required String factoryProductId, required int qty}) async {
    // Flush any pending debounce before structural changes.
    await flushPending();
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.post('/api/wholesale/cart/items', data: {
        'factoryProductId': factoryProductId,
        'qty': qty,
      });
      await fetchCart();
    } on DioException catch (e) {
      final msg = errorCodeOf(e); // MOQ_NOT_MET surfaced here
      state = state.copyWith(isLoading: false, error: msg);
      rethrow;
    }
  }

  /// PATCH /api/wholesale/cart/items/{factoryProductId} { qty } — optimistic + 800ms debounce.
  ///
  /// Updates UI instantly; the actual PATCH fires 800ms after the last tap.
  /// This is fire-and-forget from the UI — no await needed at the call site.
  void updateItem({
    required String factoryProductId,
    required int qty,
  }) {
    // Snapshot prev items for revert on server error.
    final prevItems = state.items;

    // Compute optimistic subtotalTjs using integer tiins (D-07 — no float).
    final item = state.items.firstWhere(
      (i) => i.factoryProductId == factoryProductId,
      orElse: () => WholesaleCartItem(
        id: '',
        factoryProductId: factoryProductId,
        factoryName: '',
        productName: '',
        qty: qty,
        unitPriceTjs: '0.00',
        subtotalTjs: '0.00',
        moq: 1,
      ),
    );
    final unitTiins = _parseTiins(item.unitPriceTjs);
    final newSubtotalTjs = _tiinsToString(unitTiins * qty);

    // Apply optimistic update.
    final optimisticItems = state.items.map((i) {
      if (i.factoryProductId == factoryProductId) {
        return WholesaleCartItem(
          id: i.id,
          factoryProductId: i.factoryProductId,
          factoryName: i.factoryName,
          productName: i.productName,
          qty: qty,
          unitPriceTjs: i.unitPriceTjs,
          subtotalTjs: newSubtotalTjs,
          moq: i.moq,
          appliedTierMinQty: i.appliedTierMinQty,
        );
      }
      return i;
    }).toList();
    state = state.copyWith(items: optimisticItems, error: null);

    // Record latest pending qty and (re)start the debounce timer.
    _pendingQty[factoryProductId] = qty;
    _debounceTimers[factoryProductId]?.cancel();
    _debounceTimers[factoryProductId] =
        Timer(const Duration(milliseconds: 800), () async {
      final latestQty = _pendingQty[factoryProductId];
      _debounceTimers.remove(factoryProductId);
      _pendingQty.remove(factoryProductId);
      if (latestQty == null) return;
      try {
        await _client.patch(
          '/api/wholesale/cart/items/$factoryProductId',
          data: {'qty': latestQty},
        );
        await fetchCart();
      } on DioException catch (e) {
        final msg = errorCodeOf(e);
        state = state.copyWith(items: prevItems, error: msg);
      }
    });
  }

  /// Flush all pending debounced qty updates immediately (awaited).
  ///
  /// Call this before placing an order so the server cart is authoritative.
  Future<void> flushPending() async {
    if (_debounceTimers.isEmpty) return;
    final factoryProductIds = _debounceTimers.keys.toList();
    // Cancel all pending timers.
    for (final id in factoryProductIds) {
      _debounceTimers[id]?.cancel();
      _debounceTimers.remove(id);
    }
    // Snapshot prev items once for potential revert.
    final prevItems = state.items;
    bool hasError = false;
    String? lastError;
    // Fire PATCHes serially (one per pending item).
    for (final factoryProductId in factoryProductIds) {
      final qty = _pendingQty.remove(factoryProductId);
      if (qty == null) continue;
      try {
        await _client.patch(
          '/api/wholesale/cart/items/$factoryProductId',
          data: {'qty': qty},
        );
      } on DioException catch (e) {
        hasError = true;
        lastError = errorCodeOf(e);
        state = state.copyWith(items: prevItems, error: lastError);
      }
    }
    _pendingQty.clear();
    // Single fetchCart after all patches (success path).
    if (!hasError) {
      await fetchCart();
    }
  }

  /// DELETE /api/wholesale/cart/items/{factoryProductId}
  Future<void> removeItem(String factoryProductId) async {
    // Flush any pending debounce before structural changes.
    await flushPending();
    try {
      await _client.delete('/api/wholesale/cart/items/$factoryProductId');
      await fetchCart();
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(error: msg);
    }
  }

  /// POST /api/wholesale/orders/checkout { addressId } → { paymentGroupId, orders, totalTjs }
  Future<WholesaleCheckoutResult> checkout(String addressId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        '/api/wholesale/orders/checkout',
        data: {'addressId': addressId},
      );
      final result = WholesaleCheckoutResult.fromJson(
        res.data as Map<String, dynamic>,
      );
      state = state.copyWith(isLoading: false, lastCheckout: result);
      return result;
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoading: false, error: msg);
      rethrow;
    }
  }

  /// POST /api/wholesale/payment-groups/{groupId}/pay
  ///
  /// Returns the [PaymentInitiation] (group paymentId + pay.dc.tj redirectUrl +
  /// status) so the checkout screen can open the payment link and then collect a
  /// receipt. The response is NO LONGER discarded — opening the link is not
  /// confirmation; the uploaded receipt (against this paymentId) is the next step.
  Future<PaymentInitiation> pay(String groupId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res =
          await _client.post('/api/wholesale/payment-groups/$groupId/pay');
      final initiation =
          PaymentInitiation.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(isLoading: false);
      return initiation;
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoading: false, error: msg);
      rethrow;
    }
  }

  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _debounceTimers.clear();
    _pendingQty.clear();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final wholesaleCartProvider =
    StateNotifierProvider<WholesaleCartNotifier, WholesaleCartState>((ref) {
  final client = ref.watch(dioClientProvider);
  return WholesaleCartNotifier(client: client, ref: ref);
});

/// Derived provider — cart item count for badge display.
final wholesaleCartItemCountProvider = Provider<int>((ref) {
  return ref.watch(wholesaleCartProvider).items.length;
});
