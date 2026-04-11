import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:polarity/core/constants.dart';

typedef ServerReceiptValidator = Future<bool> Function(PurchaseDetails purchase);

/// In-App Purchase service with receipt validation structure.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  bool isPremium = false;
  Function(bool)? onPurchaseUpdated;

  // Secure-by-default: entitlement is granted only when a server validator
  // confirms the purchase token/receipt.
  bool requireServerVerification = true;
  ServerReceiptValidator? serverReceiptValidator;

  bool get isServerVerificationConfigured => serverReceiptValidator != null;

  void configureServerVerification(
    ServerReceiptValidator validator, {
    bool enforce = true,
  }) {
    serverReceiptValidator = validator;
    requireServerVerification = enforce;
  }

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    _subscription = _iap.purchaseStream.listen(
      (purchases) => unawaited(_onPurchaseUpdate(purchases)),
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );

    // Restore previous purchases silently
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != GameConstants.iapProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (await _verifyPurchase(purchase)) {
            isPremium = true;
            onPurchaseUpdated?.call(true);
          }
          break;
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
        case PurchaseStatus.error:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    if (!_validateReceipt(purchase)) return false;
    if (!requireServerVerification) return true;

    final validator = serverReceiptValidator;
    if (validator == null) return false;

    try {
      return await validator(
        purchase,
      ).timeout(const Duration(seconds: 10), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  /// Local structural check only.
  /// In production, validate server-side with Google/Apple APIs.
  bool _validateReceipt(PurchaseDetails purchase) {
    try {
      final verification = purchase.verificationData;
      if (verification.serverVerificationData.isEmpty) return false;
      if (verification.source.isEmpty) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> buyRemoveAds() async {
    if (!_available) return false;
    if (requireServerVerification && serverReceiptValidator == null) {
      return false;
    }

    try {
      final response = await _iap.queryProductDetails({GameConstants.iapProductId});
      if (response.productDetails.isEmpty) return false;

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      return _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (_) {
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  void dispose() {
    _subscription?.cancel();
  }
}
