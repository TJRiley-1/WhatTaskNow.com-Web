import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../datasources/local/hive_datasource.dart';
import '../../core/constants/app_constants.dart';

class SubscriptionRepository {
  final HiveDatasource _local;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  SubscriptionRepository(this._local);

  bool get isPremium => _local.isPremium;

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate);

    // Restore purchases on init
    await restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<List<ProductDetails>> getProducts() async {
    final response = await _iap.queryProductDetails({
      kPremiumMonthlyId,
      kPremiumLifetimeId,
    });
    return response.productDetails;
  }

  Future<void> purchaseMonthly(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> purchaseLifetime(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _local.setPremium(true);
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }
}
