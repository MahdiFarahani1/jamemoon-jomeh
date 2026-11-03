import 'package:equatable/equatable.dart';

import '../../../../core/services/purchase_service.dart';

class ShopState extends Equatable {
  final List<GameProduct> products;
  final Set<String> purchasedIds;
  final bool isBusy;
  final String? messageFa;

  const ShopState({
    this.products = const [],
    this.purchasedIds = const {},
    this.isBusy = false,
    this.messageFa,
  });

  ShopState copyWith({
    List<GameProduct>? products,
    Set<String>? purchasedIds,
    bool? isBusy,
    String? messageFa,
  }) {
    return ShopState(
      products: products ?? this.products,
      purchasedIds: purchasedIds ?? this.purchasedIds,
      isBusy: isBusy ?? this.isBusy,
      messageFa: messageFa,
    );
  }

  @override
  List<Object?> get props => [products, purchasedIds, isBusy, messageFa];
}
