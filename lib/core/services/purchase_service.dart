import 'storage_service.dart';

// Product catalog entry for Cafe Bazaar In-App Billing
class GameProduct {
  final String id;
  final String titleFa;
  final String descriptionFa;
  final int priceToman;
  final String iconKey;

  const GameProduct({
    required this.id,
    required this.titleFa,
    required this.descriptionFa,
    required this.priceToman,
    required this.iconKey,
  });
}

abstract class PurchaseService {
  bool get purchasesAvailable => false;
  List<GameProduct> get availableProducts;
  bool isProductPurchased(String productId);
  Future<bool> buyProduct(String productId);
  Future<bool> restorePurchases();
}

// Development and Offline Mock purchase service with Cafe Bazaar compatibility
class MockPurchaseService implements PurchaseService {
  final StorageService _storageService;

  MockPurchaseService(this._storageService);

  @override
  bool get purchasesAvailable => true;

  static const List<GameProduct> products = [
    GameProduct(
      id: 'season_1_bundle',
      titleFa: 'اشتراک طلایی جمعمون جمعه',
      descriptionFa:
          'دسترسی کامل و نامحدود به بازی جذاب «سرقت بزرگ» و بیش از ۲٬۰۰۰ کارت و کلمه جدید در تمام بازی‌ها (پانتومیم، حرف نزن بفهمون، بمب ساعتی، سه‌تا در ۵ ثانیه و نقاشی)',
      priceToman: 99000,
      iconKey: 'bundle',
    ),
  ];

  @override
  List<GameProduct> get availableProducts => products;

  @override
  bool isProductPurchased(String productId) {
    return _storageService.isPackPurchased(productId);
  }

  @override
  Future<bool> buyProduct(String productId) async {
    if (!products.any((product) => product.id == productId)) return false;
    // Simulate real Cafe Bazaar purchase flow delay
    await Future.delayed(const Duration(milliseconds: 600));
    await _storageService.addPurchasedPack(productId);
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Entitlements are preserved locally in offline-first architecture
    return true;
  }
}

/// Production-safe local entitlement library. Real checkout must be supplied
/// by a configured billing adapter; this service never fabricates a payment.
class LocalPurchaseService implements PurchaseService {
  final StorageService storage;
  LocalPurchaseService(this.storage);
  @override
  bool get purchasesAvailable => false;
  @override
  List<GameProduct> get availableProducts => MockPurchaseService.products;
  @override
  bool isProductPurchased(String productId) =>
      storage.isPackPurchased(productId);
  @override
  Future<bool> buyProduct(String productId) async => false;
  @override
  Future<bool> restorePurchases() async => false;
}
