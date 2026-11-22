import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../data/local_store.dart';

/// The varieties the farmer has saved with "Save to favourites", shared by
/// the whole app through [FavouritesScope].
///
/// They are kept on the phone, so they survive the app being closed. Saving
/// a variety never orders it: a not-available variety can be a favourite and
/// still cannot be put in the cart.
class FavouritesController extends ChangeNotifier {
  FavouritesController({LocalStore? store}) : _store = store ?? MemoryStore() {
    _restore();
  }

  static const _key = 'favourites.v1';

  final LocalStore _store;

  // In the order they were saved.
  final List<String> _ids = [];

  /// The saved varieties' product ids, oldest first.
  List<String> get ids => List.unmodifiable(_ids);

  bool contains(String productId) => _ids.contains(productId);

  /// Saves the variety, or takes it out if it was saved. Returns whether it
  /// is a favourite afterwards.
  bool toggle(String productId) {
    final saved = !_ids.remove(productId);
    if (saved) _ids.add(productId);
    unawaited(_store.write(_key, jsonEncode(_ids)));
    notifyListeners();
    return saved;
  }

  /// Loads what was saved last time. Anything unreadable is dropped rather
  /// than stopping the app from starting.
  void _restore() {
    try {
      final saved = _store.read(_key);
      if (saved == null) return;
      for (final id in jsonDecode(saved) as List) {
        if (id is String && !_ids.contains(id)) _ids.add(id);
      }
    } catch (_) {
      _ids.clear();
    }
  }
}

/// Makes the one [FavouritesController] available to every screen.
class FavouritesScope extends InheritedNotifier<FavouritesController> {
  const FavouritesScope({
    super.key,
    required FavouritesController favourites,
    required super.child,
  }) : super(notifier: favourites);

  /// The favourites; the calling widget rebuilds whenever they change. Null
  /// where the app's scopes are not installed (a widget shown on its own).
  static FavouritesController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FavouritesScope>()
        ?.notifier;
  }
}
