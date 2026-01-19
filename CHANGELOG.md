## 1.0.0

Initial release of Flutter Route Refresh.

### Features

* **FlutterRouteRefresh** — Singleton for package initialization with `RouteObserver`
* **DirtyKeysRefresher** — Mixin for `State` classes enabling automatic data refresh on route pop
  * `registerRefresher()` / `unregisterRefresher()` — Manage refresh callbacks for data keys
  * `markStaleKey()` / `markStaleKeys()` — Mark data as stale programmatically
  * `staleEventMap` — Declarative mapping of events to refreshable keys
* **GlobalMessenger** — Lightweight event bus for posting stale data events across screens
