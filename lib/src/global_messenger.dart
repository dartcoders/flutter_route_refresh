typedef GMCallback = void Function(Object? data);

class GlobalMessenger<E> {
  static GlobalMessenger<dynamic>? _instance;

  static GlobalMessenger<E> instance<E>() {
    _instance ??= GlobalMessenger<E>._internal();
    return _instance! as GlobalMessenger<E>;
  }

  final Map<E, List<GMCallback>> _listeners;

  GlobalMessenger._internal() : _listeners = {};

  void addListener(E event, GMCallback callback) {
    _listeners[event] = _listeners[event] ?? [];
    _listeners[event]!.add(callback);
  }

  void removeListener(E event, GMCallback callback) {
    _listeners[event]?.remove(callback);
    if (_listeners[event]?.isEmpty == true) {
      _listeners.remove(event);
    }
  }

  void postMessage(E event, [Object? data]) {
    void post(GMCallback callback) => callback(data);
    _listeners[event]?.forEach(post);
  }
}
