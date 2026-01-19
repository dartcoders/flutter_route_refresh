import 'package:flutter/material.dart';
import 'package:flutter_route_refresh/src/flutter_route_refresh.dart';
import 'package:flutter_route_refresh/src/global_messenger.dart';


mixin DirtyKeysRefresher<T extends StatefulWidget, E, K> on State<T> implements RouteAware {
  late final RouteObserver<ModalRoute<dynamic>>? _routeObserver;
  final Set<K> _staleKeys = <K>{};
  final Map<K, VoidCallback> _refreshers = <K, VoidCallback>{};
  final Map<E, GMCallback> _gmHandlers = <E, GMCallback>{};

  Map<E, List<K>> get staleEventMap => const {};

  @override
  void initState() {
    super.initState();
    _routeObserver = FlutterRouteRefresh.routeObserver;
    if (staleEventMap.isNotEmpty) {
      for (final entry in staleEventMap.entries) {
        void handler(Object? _) => markStaleKeys(entry.value);
        _gmHandlers[entry.key] = handler;
        GlobalMessenger.instance<E>().addListener(entry.key, handler);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      _routeObserver?.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    for (final entry in _gmHandlers.entries) {
      GlobalMessenger.instance<E>().removeListener(entry.key, entry.value);
    }
    _gmHandlers.clear();
    super.dispose();
  }

  void registerRefresher(K key, VoidCallback refresher) {
    _refreshers[key] = refresher;
  }

  void unregisterRefresher(K key) {
    _refreshers.remove(key);
  }

  void markStaleKey(K key) {
    _staleKeys.add(key);
    try {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _refreshIfRegistered(key);
        _staleKeys.remove(key);
      }
    } catch (_) {
      _staleKeys.remove(key);
    }
  }

  void markStaleKeys(Iterable<K> keys) {
    for (final k in keys) {
      markStaleKey(k);
    }
  }

  void unmarkStaleKey(K key) => _staleKeys.remove(key);

  void clearAllStale() => _staleKeys.clear();

  @override
  void didPopNext() {
    if (!mounted || _staleKeys.isEmpty) return;
    final keys = List<K>.from(_staleKeys);
    _staleKeys.clear();
    for (final k in keys) {
      _refreshIfRegistered(k);
    }
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}

  void _refreshIfRegistered(K key) {
    final cb = _refreshers[key];
    if (cb != null) cb();
  }
}
