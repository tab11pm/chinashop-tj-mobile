import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ref
import 'package:flutter_riverpod/legacy.dart'; // StateNotifier/StateNotifierProvider (Riverpod 3)
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/error_messages.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_lang.dart';
import '../../payment_receipts/providers/payment_receipt_provider.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class CartItem {
  final String id;
  final String productId;
  final String? variantId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final String unitPriceTjs; // Money string — never parse to float (D-07)
  final String subtotalTjs;
  final String?
      compareAtPriceTjs; // Struck-through "was" price from API (nullable)
  final int? discountPercent; // Discount percentage 0–100 (nullable)

  const CartItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    this.imageUrl,
    required this.quantity,
    required this.unitPriceTjs,
    required this.subtotalTjs,
    this.compareAtPriceTjs,
    this.discountPercent,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString(),
      productName: json['productName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      quantity: (json['qty'] as num?)?.toInt() ?? 1,
      unitPriceTjs: json['unitPriceTjs']?.toString() ?? '0.00',
      subtotalTjs: json['subtotalTjs']?.toString() ?? '0.00',
      compareAtPriceTjs: json['compareAtPriceTjs']?.toString(),
      discountPercent: (json['discountPercent'] as num?)?.toInt(),
    );
  }
}

class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;
  final String? lastOrderId; // Set after successful checkout
  final String? discountTotalTjs; // Cart-level discount sum from API (nullable)
  final String fxRate; // Raw FX rate string e.g. '1.5'; '0' when not available

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.lastOrderId,
    this.discountTotalTjs,
    this.fxRate = '0',
  });

  /// Cart total as a MoneyString — sum of line subtotals in integer tiins
  /// (D-07: no float arithmetic; reuses the same tiins helpers as the notifier).
  String get totalTjs {
    final tiins =
        items.fold<int>(0, (sum, i) => sum + _parseTiins(i.subtotalTjs));
    return _tiinsToString(tiins);
  }

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
    String? lastOrderId,
    String? discountTotalTjs,
    String? fxRate,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastOrderId: lastOrderId ?? this.lastOrderId,
      discountTotalTjs: discountTotalTjs ?? this.discountTotalTjs,
      fxRate: fxRate ?? this.fxRate,
    );
  }
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
// Notifier
// ---------------------------------------------------------------------------

class CartNotifier extends StateNotifier<CartState> {
  final DioClient _client;
  final Ref _ref;

  /// Per-item debounce timers keyed by variantId.
  final Map<String, Timer> _debounceTimers = {};

  /// Latest pending qty per variantId (written on each tap, read when timer fires).
  final Map<String, int> _pendingQty = {};

  CartNotifier({required DioClient client, required Ref ref})
      : _client = client,
        _ref = ref,
        super(const CartState());

  String get _lang => apiLang(_ref.read(authProvider).locale);

  /// GET /api/cart/items?lang= → { id, userId, items: [...] }
  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client
          .get('/api/cart/items', queryParameters: {'lang': _lang});
      // API returns an object { id, userId, items: [...] }, not a bare list.
      final data = res.data as Map<String, dynamic>;
      final list = (data['items'] as List<dynamic>?) ?? const [];
      state = state.copyWith(
        isLoading: false,
        items: list
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        discountTotalTjs: data['discountTotalTjs']?.toString(),
        fxRate: data['fxRate']?.toString() ?? '0',
      );
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  /// POST /api/cart/items { productId, variantId, qty }
  /// variantId is REQUIRED by the API (cart is keyed by variant).
  Future<void> addItem({
    required String productId,
    required String variantId,
    int quantity = 1,
  }) async {
    // Flush any pending debounce before structural changes.
    await flushPending();
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.post('/api/cart/items', data: {
        'productId': productId,
        'variantId': variantId,
        'qty': quantity,
      });
      await fetchCart();
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoading: false, error: msg);
      rethrow;
    }
  }

  /// PATCH /api/cart/items/{variantId} { qty } — optimistic update with 800ms debounce.
  ///
  /// Updates UI instantly; the actual PATCH fires 800ms after the last tap.
  /// This is fire-and-forget from the UI — no await needed at the call site.
  void updateItem({required String variantId, required int quantity}) {
    // Snapshot prev items for revert on server error.
    final prevItems = state.items;

    // Compute optimistic subtotalTjs using integer tiins (D-07 — no float).
    final item = state.items.firstWhere(
      (i) => i.variantId == variantId,
      orElse: () => CartItem(
        id: '',
        productId: '',
        variantId: variantId,
        productName: '',
        quantity: quantity,
        unitPriceTjs: '0.00',
        subtotalTjs: '0.00',
      ),
    );
    final unitTiins = _parseTiins(item.unitPriceTjs);
    final newSubtotalTjs = _tiinsToString(unitTiins * quantity);

    // Apply optimistic update.
    final optimisticItems = state.items.map((i) {
      if (i.variantId == variantId) {
        return CartItem(
          id: i.id,
          productId: i.productId,
          variantId: i.variantId,
          productName: i.productName,
          imageUrl: i.imageUrl,
          quantity: quantity,
          unitPriceTjs: i.unitPriceTjs,
          subtotalTjs: newSubtotalTjs,
          compareAtPriceTjs: i.compareAtPriceTjs,
          discountPercent: i.discountPercent,
        );
      }
      return i;
    }).toList();
    state = state.copyWith(items: optimisticItems, error: null);

    // Record latest pending qty and (re)start the debounce timer.
    _pendingQty[variantId] = quantity;
    _debounceTimers[variantId]?.cancel();
    _debounceTimers[variantId] =
        Timer(const Duration(milliseconds: 800), () async {
      final latestQty = _pendingQty[variantId];
      _debounceTimers.remove(variantId);
      _pendingQty.remove(variantId);
      if (latestQty == null) return;
      try {
        await _client
            .patch('/api/cart/items/$variantId', data: {'qty': latestQty});
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
    final variantIds = _debounceTimers.keys.toList();
    // Cancel all pending timers.
    for (final id in variantIds) {
      _debounceTimers[id]?.cancel();
      _debounceTimers.remove(id);
    }
    // Snapshot prev items once for potential revert.
    final prevItems = state.items;
    bool hasError = false;
    String? lastError;
    // Fire PATCHes serially (one per pending item).
    for (final variantId in variantIds) {
      final qty = _pendingQty.remove(variantId);
      if (qty == null) continue;
      try {
        await _client.patch('/api/cart/items/$variantId', data: {'qty': qty});
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

  /// DELETE /api/cart/items/{variantId}
  Future<void> removeItem(String variantId) async {
    // Flush any pending debounce before structural changes.
    await flushPending();
    try {
      await _client.delete('/api/cart/items/$variantId');
      await fetchCart();
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(error: msg);
    }
  }

  /// POST /api/orders {} → returns order { id }; staff assigns retail pickup later.
  Future<String> checkout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(
        '/api/orders',
        data: const <String, dynamic>{},
      );
      final data = res.data as Map<String, dynamic>;
      final orderId = data['id']?.toString() ?? '';
      state = state.copyWith(isLoading: false, lastOrderId: orderId, items: []);
      return orderId;
    } on DioException catch (e) {
      final msg = errorCodeOf(e);
      state = state.copyWith(isLoading: false, error: msg);
      rethrow;
    }
  }

  /// POST /api/payments/{orderId}/pay → initiates payment.
  ///
  /// Returns the [PaymentInitiation] (paymentId + pay.dc.tj redirectUrl + status)
  /// so the checkout screen can open the payment link and then collect a receipt.
  /// The response is NO LONGER discarded — opening the link is not confirmation;
  /// the uploaded receipt (against this paymentId) is the next explicit step.
  Future<PaymentInitiation> initiatePayment(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post('/api/payments/$orderId/pay');
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
// Provider
// ---------------------------------------------------------------------------

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final client = ref.watch(dioClientProvider);
  return CartNotifier(client: client, ref: ref);
});
