import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/purchase_service.dart';
import '../../../../core/services/storage_service.dart';
import 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  final PurchaseService _purchaseService;
  bool get purchasesAvailable => _purchaseService.purchasesAvailable;

  ShopCubit(this._purchaseService) : super(const ShopState()) {
    loadProducts();
  }

  void loadProducts() {
    final products = _purchaseService.availableProducts;
    final purchased = <String>{};
    for (final p in products) {
      if (_purchaseService.isProductPurchased(p.id)) {
        purchased.add(p.id);
      }
    }
    emit(state.copyWith(products: products, purchasedIds: purchased));
  }

  Future<bool> buy(String productId) async {
    emit(state.copyWith(isBusy: true, messageFa: null));
    try {
      final success = await _purchaseService.buyProduct(productId);
      if (success) {
        final updated = Set<String>.from(state.purchasedIds)..add(productId);
        if (productId == 'season_1_bundle') {
          for (final p in state.products) {
            updated.add(p.id);
          }
          updated.add('heist');
          updated.addAll(StorageService.seasonOnePackIds);
        }
        emit(
          state.copyWith(
            isBusy: false,
            purchasedIds: updated,
            messageFa: 'خرید شما با موفقیت فعال شد!',
          ),
        );
        return true;
      } else {
        emit(
          state.copyWith(
            isBusy: false,
            messageFa: 'خرید انجام نشد یا لغو گردید.',
          ),
        );
        return false;
      }
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          messageFa: 'خطا در ارتباط با سرور پرداخت بازار.',
        ),
      );
      return false;
    }
  }

  Future<void> restore() async {
    emit(state.copyWith(isBusy: true, messageFa: null));
    try {
      final restored = await _purchaseService.restorePurchases();
      if (!restored) {
        emit(
          state.copyWith(
            isBusy: false,
            messageFa:
                'بازیابی خریدها انجام نشد. اتصال به بازار را بررسی کنید.',
          ),
        );
        return;
      }
      loadProducts();
      emit(
        state.copyWith(isBusy: false, messageFa: 'خریدهای قبلی بازیابی شدند.'),
      );
    } catch (e) {
      emit(state.copyWith(isBusy: false, messageFa: 'خطا در بازیابی خریدها.'));
    }
  }
}
