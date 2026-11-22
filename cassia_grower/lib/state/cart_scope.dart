import 'package:flutter/widgets.dart';

import 'cart_controller.dart';

/// Makes the one [CartController] available to every screen.
///
/// It sits above the app's navigator, so pages opened on top of the tabs
/// (product details, the cart, checkout) all see the same cart.
class CartScope extends InheritedNotifier<CartController> {
  const CartScope({
    super.key,
    required CartController cart,
    required super.child,
  }) : super(notifier: cart);

  /// The cart; the calling widget rebuilds whenever the cart changes.
  static CartController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CartScope>()!.notifier!;
  }

  /// The cart, without rebuilding on changes — for `initState` and callbacks.
  static CartController read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<CartScope>()!.notifier!;
  }
}
