# Flutter Route Refresh

[![pub package](https://img.shields.io/pub/v/flutter_route_refresh.svg)](https://pub.dev/packages/flutter_route_refresh)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**Automatically refresh stale data when users navigate back to a screen.**

Flutter Route Refresh solves a common problem in Flutter apps: keeping screen data fresh after navigation. When users navigate away and return, this package automatically refreshes only the data that changed — no manual refresh logic needed.

---

## The Problem

```
Screen A (Product List)  →  Screen B (Edit Product)  →  Back to Screen A
        ↓                                                      ↓
   Shows products                                    Still shows OLD data! 😞
```

Typically, you'd need to manually track state changes, pass callbacks, or use complex state management just to refresh data when returning to a screen.

## The Solution

```
Screen A (Product List)  →  Screen B (Edit Product)  →  Back to Screen A
        ↓                         ↓                           ↓
   Shows products          Posts "updateProducts"      Auto-refreshes! ✨
                               event
```

Flutter Route Refresh handles this automatically with a simple event-based system.

---

## Features

- **Automatic Refresh** — Data refreshes automatically when returning to a screen
- **Event-Driven** — Mark data as stale via events from anywhere in your app
- **Selective Updates** — Only refresh the specific data that changed
- **Type-Safe** — Generic types for events and keys prevent runtime errors
- **Lightweight** — No external dependencies, minimal footprint
- **Easy Integration** — Just add a mixin to your existing StatefulWidgets

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_route_refresh: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

### 1. Initialize the Package

In your `main.dart`, create a `RouteObserver` and initialize the package:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_route_refresh/flutter_route_refresh.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() {
  FlutterRouteRefresh.init(routeObserver: routeObserver);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver], // Don't forget this!
      home: const HomeScreen(),
    );
  }
}
```

### 2. Define Your Events and Keys

Create enums for your events and refresh keys:

```dart
// Events that can trigger data refresh
enum AppEvent {
  productUpdated,
  cartModified,
  userProfileChanged,
}

// Keys identifying refreshable data
enum RefreshKey {
  productList,
  cartItems,
  userProfile,
}
```

### 3. Add the Mixin to Your Screen

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with DirtyKeysRefresher<HomeScreen, AppEvent, RefreshKey> {

  List<Product> products = [];

  @override
  void initState() {
    super.initState();

    // Register refresh callbacks
    registerRefresher(RefreshKey.productList, _fetchProducts);

    // Initial load
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final data = await api.getProducts();
    setState(() => products = data);
  }

  // Map events to the keys that should refresh
  @override
  Map<AppEvent, List<RefreshKey>> get staleEventMap => {
    AppEvent.productUpdated: [RefreshKey.productList],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) => ProductTile(
          product: products[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProductScreen(product: products[index]),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 4. Post Events When Data Changes

From any screen, post an event when data is modified:

```dart
class EditProductScreen extends StatelessWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  Future<void> _saveProduct(BuildContext context) async {
    await api.updateProduct(product);

    // Notify that product data changed
    GlobalMessenger.instance<AppEvent>().postMessage(AppEvent.productUpdated);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // ... your edit form UI
  }
}
```

That's it! When the user saves and navigates back, the product list automatically refreshes.

---

## API Reference

### FlutterRouteRefresh

Initialize the package with your route observer.

```dart
// Initialize (call once at app startup)
FlutterRouteRefresh.init(routeObserver: yourRouteObserver);

// Check initialization status
bool ready = FlutterRouteRefresh.isInitialized;

// Access the route observer
RouteObserver observer = FlutterRouteRefresh.routeObserver;
```

### DirtyKeysRefresher Mixin

Add to any `State` class to enable automatic refresh.

| Method | Description |
|--------|-------------|
| `registerRefresher(key, callback)` | Register a refresh callback for a key |
| `unregisterRefresher(key)` | Remove a registered callback |
| `markStaleKey(key)` | Manually mark a key as stale |
| `markStaleKeys(keys)` | Mark multiple keys as stale |
| `unmarkStaleKey(key)` | Remove a key from the stale set |
| `clearAllStale()` | Clear all stale keys |

| Property | Description |
|----------|-------------|
| `staleEventMap` | Override to map events → keys to refresh |

### GlobalMessenger

A lightweight event bus for posting events.

```dart
// Get the singleton instance for your event type
final messenger = GlobalMessenger.instance<AppEvent>();

// Post an event (notifies all listeners)
messenger.postMessage(AppEvent.productUpdated);

// Manual listener management (usually not needed)
messenger.addListener(AppEvent.productUpdated, myCallback);
messenger.removeListener(AppEvent.productUpdated, myCallback);
```

---

## Advanced Usage

### Multiple Keys per Event

Refresh multiple data sources when a single event occurs:

```dart
@override
Map<AppEvent, List<RefreshKey>> get staleEventMap => {
  AppEvent.orderPlaced: [
    RefreshKey.cartItems,      // Clear the cart
    RefreshKey.orderHistory,   // Update order list
    RefreshKey.userPoints,     // Update loyalty points
  ],
};
```

### Multiple Events per Key

The same data can be refreshed by different events:

```dart
@override
Map<AppEvent, List<RefreshKey>> get staleEventMap => {
  AppEvent.productUpdated: [RefreshKey.productList],
  AppEvent.productDeleted: [RefreshKey.productList],
  AppEvent.categoryChanged: [RefreshKey.productList],
};
```

### Manual Stale Marking

Mark data as stale without using events:

```dart
// Mark a single key
markStaleKey(RefreshKey.productList);

// Mark multiple keys
markStaleKeys([RefreshKey.productList, RefreshKey.cartItems]);
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your App                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────┐    posts event    ┌──────────────────────┐   │
│   │  Screen B    │ ───────────────── │   GlobalMessenger    │   │
│   │  (Editor)    │                   │   (Event Bus)        │   │
│   └──────────────┘                   └──────────┬───────────┘   │
│                                                  │               │
│                                        notifies  │               │
│                                                  ▼               │
│   ┌──────────────┐    route change   ┌──────────────────────┐   │
│   │  Screen A    │ ◄──────────────── │   RouteObserver      │   │
│   │  (List)      │                   │   (Flutter)          │   │
│   │              │                   └──────────────────────┘   │
│   │  with        │                                              │
│   │  DirtyKeys   │ ─── checks stale keys ──┐                    │
│   │  Refresher   │                         │                    │
│   │              │ ◄── executes callbacks ─┘                    │
│   └──────────────┘                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Example Use Cases

| Scenario | Event | Refreshed Data |
|----------|-------|----------------|
| User edits profile | `profileUpdated` | User info, avatar |
| Item added to cart | `cartModified` | Cart count, cart items |
| New comment posted | `commentAdded` | Comments list |
| Order placed | `orderPlaced` | Cart, order history, points |
| Settings changed | `settingsChanged` | Theme, locale, preferences |

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
