import 'package:flutter/material.dart';

class FlutterRouteRefresh {
  static RouteObserver<ModalRoute<dynamic>>? _routeObserver;

  static void init({
    required RouteObserver<ModalRoute<dynamic>> routeObserver,
  }) {
    _routeObserver = routeObserver;
  }

  static RouteObserver<ModalRoute<dynamic>>? get routeObserver {
    assert(
      _routeObserver != null,
      'FlutterRouteRefresh has not been initialized. '
      'Call FlutterRouteRefresh.init(routeObserver: yourRouteObserver) '
      'before using DirtyKeysRefresher.',
    );
    return _routeObserver;
  }

  static bool get isInitialized => _routeObserver != null;
}
