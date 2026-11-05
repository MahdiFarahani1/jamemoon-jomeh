import 'dart:async';

import 'package:flutter_poolakey/flutter_poolakey.dart';

import 'purchase_service.dart';
import 'storage_service.dart';

/// A non-consumable, one-time purchase: the current app promises permanent access.
class BazaarPurchaseService implements PurchaseService {
  static const productId = 'season_1_bundle';
  static const packageName = 'com.denver.jam';
  final StorageService _storage;
  final BazaarBillingGateway _billing;
  final String publicKey;

  BazaarPurchaseService(
    this._storage, {
    required this.publicKey,
    BazaarBillingGateway? billing,
  }) : _billing = billing ?? PoolakeyGateway();

  @override
  bool get purchasesAvailable => publicKey.trim().isNotEmpty;
  @override
  List<GameProduct> get availableProducts => MockPurchaseService.products;
  @override
  bool isProductPurchased(String id) => _storage.isPackPurchased(id);

  bool _valid(PurchaseInfo info) =>
      info.productId == productId &&
      info.packageName == packageName &&
      info.purchaseState == PurchaseState.PURCHASED &&
      info.purchaseToken.isNotEmpty &&
      info.dataSignature.isNotEmpty;

  @override
  Future<bool> buyProduct(String id) async {
    if (!purchasesAvailable || id != productId) return false;
    await _billing.connect(publicKey);
    final info = await _billing.purchase(id);
    if (!_valid(info)) return false;
    await _storage.addPurchasedPack(id);
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    if (!purchasesAvailable) return false;
    await _billing.connect(publicKey);
    final purchases = await _billing.purchased();
    if (purchases.any(_valid)) await _storage.addPurchasedPack(productId);
    return true;
  }
}

abstract class BazaarBillingGateway {
  Future<void> connect(String publicKey);
  Future<PurchaseInfo> purchase(String productId);
  Future<List<PurchaseInfo>> purchased();
}

/// Poolakey verifies Bazaar's signature using the app's RSA public key.
class PoolakeyGateway implements BazaarBillingGateway {
  bool _connected = false;
  Future<void>? _connecting;

  @override
  Future<void> connect(String publicKey) async {
    if (publicKey.trim().isEmpty) throw StateError('Bazaar public key missing');
    if (_connected) return;
    if (_connecting != null) return _connecting;
    final done = Completer<void>();
    void fail() {
      _connected = false;
      if (!done.isCompleted) {
        done.completeError(StateError('Bazaar connection failed'));
      }
    }

    _connecting = Future.wait<void>([
      FlutterPoolakey.connect(
        publicKey,
        onSucceed: () {
          _connected = true;
          if (!done.isCompleted) done.complete();
        },
        onFailed: fail,
        onDisconnected: fail,
      ),
      done.future,
    ]).then((_) {}).timeout(const Duration(seconds: 15));
    try {
      await _connecting;
    } finally {
      _connecting = null;
    }
  }

  @override
  Future<PurchaseInfo> purchase(String productId) =>
      FlutterPoolakey.purchase(productId);
  @override
  Future<List<PurchaseInfo>> purchased() =>
      FlutterPoolakey.getAllPurchasedProducts();
}
