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
  List<GameProduct> get availableProducts;
  bool isProductPurchased(String productId);
  Future<bool> buyProduct(String productId);
  Future<bool> restorePurchases();
}

// Development and Offline Mock purchase service with Cafe Bazaar compatibility
class MockPurchaseService implements PurchaseService {
  final StorageService _storageService;

  MockPurchaseService(this._storageService);

  static const List<GameProduct> products = [
    GameProduct(
      id: 'pack_taboo_full',
      titleFa: 'بسته طلایی «حرف نزن، بفهمون!»',
      descriptionFa: 'بیش از ۲۰۰ کارت جذاب، دسته‌بندی‌های هیجان‌انگیز و اصطلاحات خاص',
      priceToman: 29000,
      iconKey: 'taboo',
    ),
    GameProduct(
      id: 'pack_bomb_full',
      titleFa: 'بسته طلایی «بمب دست کیه؟»',
      descriptionFa: '۱۵۰ موضوع چالش‌برانگیز، خنده‌دار و سوالات غیرمنتظره',
      priceToman: 29000,
      iconKey: 'bomb',
    ),
    GameProduct(
      id: 'pack_charades_full',
      titleFa: 'بسته طلایی «پانتومیم انفجاری»',
      descriptionFa: '۲۵۰ سوژه خنده‌دار، موقعیت‌های روزمره و ضرب‌المثل‌های دشوار',
      priceToman: 29000,
      iconKey: 'charades',
    ),
    GameProduct(
      id: 'pack_five_full',
      titleFa: 'بسته طلایی «سه‌تا بگو!»',
      descriptionFa: '۲۰۰ سوال سرعتی پر از هیجان برای به چالش کشیدن حضور ذهن',
      priceToman: 29000,
      iconKey: 'five',
    ),
    GameProduct(
      id: 'pack_drawing_full',
      titleFa: 'بسته طلایی «نقاشی افتضاح!»',
      descriptionFa: '۱۸۰ سوژه تصویری خلاقانه و طنزآمیز برای کشیدن با انگشت',
      priceToman: 29000,
      iconKey: 'drawing',
    ),
    GameProduct(
      id: 'season_1_bundle',
      titleFa: 'بسته جامع فصل اول (همه بازی‌ها)',
      descriptionFa: 'دسترسی نامحدود و مادام‌العمر به تمام کارت‌های ویژه هر ۵ بازی با ۵۰٪ تخفیف ویژه',
      priceToman: 69000,
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
