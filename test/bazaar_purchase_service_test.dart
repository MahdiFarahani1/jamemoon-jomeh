import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_poolakey/flutter_poolakey.dart';
import 'package:flutter_application_1/core/services/bazaar_purchase_service.dart';
import 'package:flutter_application_1/core/services/storage_service.dart';

class FakeBilling implements BazaarBillingGateway {
  PurchaseInfo? receipt;
  List<PurchaseInfo> inventory = [];
  String? connectedKey;
  @override
  Future<void> connect(String publicKey) async => connectedKey = publicKey;
  @override
  Future<PurchaseInfo> purchase(String productId) async => receipt!;
  @override
  Future<List<PurchaseInfo>> purchased() async => inventory;
}

PurchaseInfo receipt({
  String product = 'season_1_bundle',
  String package = 'com.denver.jam',
  PurchaseState state = PurchaseState.PURCHASED,
  String signature = 'signed',
}) => PurchaseInfo(
  'order',
  'token',
  '',
  package,
  state,
  1,
  product,
  '{}',
  signature,
);

void main() {
  test('payment requires configured key and valid purchased receipt', () async {
    final storage = StorageService();
    final gateway = FakeBilling()..receipt = receipt();
    final disabled = BazaarPurchaseService(
      storage,
      publicKey: '',
      billing: gateway,
    );
    expect(await disabled.buyProduct('season_1_bundle'), isFalse);
    expect(gateway.connectedKey, isNull);
    final service = BazaarPurchaseService(
      storage,
      publicKey: 'key',
      billing: gateway,
    );
    gateway.receipt = receipt(state: PurchaseState.REFUNDED);
    expect(await service.buyProduct('season_1_bundle'), isFalse);
    gateway.receipt = receipt(package: 'other.package');
    expect(await service.buyProduct('season_1_bundle'), isFalse);
    gateway.receipt = receipt(signature: '');
    expect(await service.buyProduct('season_1_bundle'), isFalse);
    expect(storage.isSubscribed, isFalse);
    gateway.receipt = receipt();
    expect(await service.buyProduct('season_1_bundle'), isTrue);
    expect(storage.isSubscribed, isTrue);
  });
  test('restore only grants access to a matching purchased receipt', () async {
    final storage = StorageService();
    final gateway = FakeBilling()..inventory = [receipt(product: 'other')];
    final service = BazaarPurchaseService(
      storage,
      publicKey: 'key',
      billing: gateway,
    );
    expect(await service.restorePurchases(), isTrue);
    expect(storage.isSubscribed, isFalse);
    gateway.inventory = [receipt()];
    expect(await service.restorePurchases(), isTrue);
    expect(storage.isSubscribed, isTrue);
  });
}
