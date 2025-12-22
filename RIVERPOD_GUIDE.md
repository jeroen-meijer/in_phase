# Riverpod Architecture Guide: Building Maintainable Flutter Applications

## Table of Contents

1. [Introduction to Riverpod](#introduction-to-riverpod)
2. [Core Concepts](#core-concepts)
3. [Provider Types](#provider-types)
4. [API-Repository-Riverpod-UI Architecture](#api-repository-riverpod-ui-architecture)
5. [Ref Methods: watch, read, and listen](#ref-methods-watch-read-and-listen)
6. [Modifiers and Advanced Features](#modifiers-and-advanced-features)
7. [Code Organization for Large Applications](#code-organization-for-large-applications)
8. [Performance Optimization](#performance-optimization)
9. [Error Handling and AsyncValue](#error-handling-and-asyncvalue)
10. [Testing Strategies](#testing-strategies)
11. [Code Generation with riverpod_generator](#code-generation-with-riverpod_generator)
12. [Real-World Patterns and Best Practices](#real-world-patterns-and-best-practices)

---

## Introduction to Riverpod

Riverpod is a modern, compile-time safe state management and dependency injection framework for Flutter. It serves as a complete replacement for patterns like singletons, service locators, dependency injection containers, and `InheritedWidget`s.

### Key Characteristics

- **Compile-Time Safety**: Catches errors at compile-time rather than runtime, reducing bugs and improving developer experience
- **No BuildContext Dependency**: Unlike Provider, Riverpod doesn't require `BuildContext` to access providers, enabling more flexible and modular code
- **Dependency Injection**: Built-in dependency injection system that makes testing and mocking straightforward
- **Performance**: Optimized to rebuild only necessary parts of the widget tree
- **Scalability**: Designed for large applications with complex state management needs

### Why Riverpod Over Alternatives?

- **vs Provider**: Riverpod is Provider's successor, offering better scalability, compile-time safety, and no BuildContext requirement
- **vs BLoC**: Less boilerplate, simpler API, better integration with Flutter's reactive model, while maintaining separation of concerns
- **vs GetX**: More structured approach suitable for large applications, better testability, and stronger type safety

---

## Core Concepts

### Providers

A **provider** is an object that encapsulates a piece of state and allows other parts of the application to listen to and interact with that state. Providers are immutable and can depend on other providers, creating a dependency graph.

```dart
// Simple provider
final greetingProvider = Provider<String>((ref) => 'Hello, World!');

// Provider depending on another provider
final userNameProvider = Provider<String>((ref) => 'John Doe');
final personalizedGreetingProvider = Provider<String>((ref) {
  final name = ref.watch(userNameProvider);
  return 'Hello, $name!';
});
```

### Ref Object

The `Ref` object is passed to provider functions and provides access to:

- `ref.watch()` - Subscribe to a provider and rebuild when it changes
- `ref.read()` - Read a provider's value without subscribing
- `ref.listen()` - Listen to changes for side effects
- `ref.refresh()` - Force a provider to recompute
- `ref.invalidate()` - Dispose of a provider

### ProviderScope

`ProviderScope` is a widget that must wrap your application to enable Riverpod. It creates a container for all providers.

```dart
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

---

## Provider Types

### 1. Provider

For read-only values or services that don't change. Ideal for dependency injection.

```dart
final httpClientProvider = Provider<http.Client>((ref) => http.Client());
final loggerProvider = Provider<Logger>((ref) => Logger());
```

**Use Cases:**

- Dependency injection (services, repositories, API clients)
- Constants or configuration values
- Computed values derived from other providers

### 2. StateProvider

For simple, mutable state (booleans, integers, strings, enums). Minimal boilerplate.

```dart
final counterProvider = StateProvider<int>((ref) => 0);
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// Usage
ref.read(counterProvider.notifier).state++; // Increment
ref.read(isDarkModeProvider.notifier).state = true; // Toggle
```

**Use Cases:**

- Simple UI state (toggles, counters, form fields)
- Filter states
- Simple flags

**Limitations:**

- Not suitable for complex state with business logic
- No built-in methods for state mutations

### 3. FutureProvider

For asynchronous operations that return a single value (API calls, file reads, etc.).

```dart
final userProvider = FutureProvider<User>((ref) async {
  final response = await http.get('https://api.example.com/user/123');
  return User.fromJson(jsonDecode(response.body));
});
```

**Use Cases:**

- API calls
- File I/O operations
- One-time data fetching
- Initialization logic

**State Management:**

- Returns `AsyncValue<T>` which handles loading, data, and error states automatically

### 4. StreamProvider

For real-time data streams (WebSockets, Firebase, periodic updates).

```dart
final messagesProvider = StreamProvider<List<Message>>((ref) {
  return chatService.messagesStream();
});

final timerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(Duration(seconds: 1), (i) => i);
});
```

**Use Cases:**

- WebSocket connections
- Firebase Realtime Database
- Periodic updates
- Real-time chat applications

### 5. NotifierProvider (Riverpod 2.0+)

For complex mutable state with business logic. Replaces `StateNotifierProvider`.

```dart
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

final counterNotifierProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);
```

**Use Cases:**

- Complex state with multiple methods
- State machines
- Form validation logic
- Business logic encapsulation

### 6. AsyncNotifierProvider

For asynchronous operations that need to be modifiable from the UI. Combines `FutureProvider` with `NotifierProvider`.

```dart
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    return await fetchUser();
  }

  Future<void> updateUser(User user) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => updateUserOnServer(user));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchUser());
  }
}

final userNotifierProvider = AsyncNotifierProvider<UserNotifier, User>(
  UserNotifier.new,
);
```

**Use Cases:**

- Fetchable and updatable data
- CRUD operations
- Data that needs refresh capability
- Complex async state management

---

## API-Repository-Riverpod-UI Architecture

This architecture pattern separates concerns into distinct layers, promoting maintainability, testability, and scalability.

### Architecture Layers

```
┌─────────────────────────────────────────┐
│           UI Layer (Widgets)            │
│  - ConsumerWidget / ConsumerStateful    │
│  - ref.watch() for reactive updates     │
│  - ref.read() for one-time actions      │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      Riverpod Layer (Providers)         │
│  - NotifierProvider / AsyncNotifier     │
│  - Business logic orchestration         │
│  - State management                     │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      Repository Layer                   │
│  - Data abstraction                     │
│  - Combines multiple data sources       │
│  - Caching logic                        │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      API / Data Source Layer            │
│  - HTTP clients                         │
│  - Local databases                      │
│  - External services                    │
└─────────────────────────────────────────┘
```

**Note on DataSources:** The Data Source layer is typically split into:
- **Remote DataSource**: Handles API calls, network requests, serialization
- **Local DataSource**: Handles caching, offline storage, persistence

In Dart, classes can act as interfaces, so we use concrete classes directly. For testing, we use `mocktail` to create mocks from these concrete classes, eliminating the need for separate interface/implementation classes.

### Implementation Example

#### 1. Data Models

```dart
// lib/features/users/domain/user.dart
class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
  };
}
```

#### 2. API Service

```dart
// lib/features/users/data/api/user_api.dart
class UserApi {
  final http.Client _client;

  UserApi(this._client);

  Future<User> getUser(String id) async {
    final response = await _client.get(
      Uri.parse('https://api.example.com/users/$id'),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<User> updateUser(User user) async {
    final response = await _client.put(
      Uri.parse('https://api.example.com/users/${user.id}'),
      body: jsonEncode(user.toJson()),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user');
    }
  }
}
```

#### 3. Repository

```dart
// lib/features/users/data/repositories/user_repository.dart
class UserRepository {
  final UserApi _api;
  final UserCache _cache;

  UserRepository(this._api, this._cache);

  Future<User> getUser(String id) async {
    // Check cache first
    final cachedUser = await _cache.getUser(id);
    if (cachedUser != null) {
      return cachedUser;
    }

    // Fetch from API
    final user = await _api.getUser(id);

    // Cache the result
    await _cache.saveUser(user);

    return user;
  }

  Future<User> updateUser(User user) async {
    // Update via API
    final updatedUser = await _api.updateUser(user);

    // Update cache
    await _cache.saveUser(updatedUser);

    return updatedUser;
  }

  Future<void> clearCache() async {
    await _cache.clear();
  }
}
```

#### 4. Riverpod Providers

```dart
// lib/features/users/presentation/providers/user_providers.dart

// API Provider
final userApiProvider = Provider<UserApi>((ref) {
  final client = ref.watch(httpClientProvider);
  return UserApi(client);
});

// Cache Provider
final userCacheProvider = Provider<UserCache>((ref) {
  return UserCache();
});

// Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final api = ref.watch(userApiProvider);
  final cache = ref.watch(userCacheProvider);
  return UserRepository(api, cache);
});

// Notifier Provider
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    final userId = ref.watch(currentUserIdProvider);
    final repository = ref.watch(userRepositoryProvider);
    return await repository.getUser(userId);
  }

  Future<void> updateUser(User user) async {
    final repository = ref.read(userRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedUser = await repository.updateUser(user);
      // Invalidate cache to force refresh
      ref.invalidate(userRepositoryProvider);
      return updatedUser;
    });
  }

  Future<void> refresh() async {
    final repository = ref.read(userRepositoryProvider);
    await repository.clearCache();
    ref.invalidateSelf();
  }
}

final userNotifierProvider = AsyncNotifierProvider<UserNotifier, User>(
  UserNotifier.new,
);
```

#### 5. UI Layer

```dart
// lib/features/users/presentation/screens/user_profile_screen.dart
class UserProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text('User Profile')),
      body: userAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(userNotifierProvider),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
        data: (user) => Column(
          children: [
            Text('Name: ${user.name}'),
            Text('Email: ${user.email}'),
            ElevatedButton(
              onPressed: () async {
                final updatedUser = user.copyWith(name: 'New Name');
                await ref.read(userNotifierProvider.notifier)
                  .updateUser(updatedUser);
              },
              child: Text('Update'),
            ),
            ElevatedButton(
              onPressed: () => ref.read(userNotifierProvider.notifier).refresh(),
              child: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Benefits of This Architecture

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Testability**: Easy to mock repositories and API services
3. **Maintainability**: Changes in one layer don't affect others
4. **Reusability**: Repositories can be used across multiple features
5. **Flexibility**: Easy to swap data sources (API, local DB, mock)

---

## Ref Methods: watch, read, and listen

Understanding when and how to use each method is crucial for proper state management.

### ref.watch()

**Purpose**: Subscribe to a provider and rebuild the widget when the provider's state changes.

**Use Cases**:

- In `build()` methods to create reactive UI
- When you need the UI to update automatically when state changes

```dart
class CounterWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Widget rebuilds when counterProvider changes
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}
```

**Important**: Only use in `build()` methods. Using `ref.watch()` in event handlers or lifecycle methods can cause unnecessary rebuilds.

### ref.read()

**Purpose**: Read a provider's value without subscribing to changes. Does not trigger rebuilds.

**Use Cases**:

- In event handlers (onPressed, onTap, etc.)
- In lifecycle methods (initState, dispose, etc.)
- When you need a one-time value access
- To call methods on notifiers

```dart
ElevatedButton(
  onPressed: () {
    // No rebuild triggered
    ref.read(counterProvider.notifier).increment();
  },
  child: Text('Increment'),
)
```

**Important**: Never use `ref.read()` in `build()` methods if you want reactive updates. Use `ref.watch()` instead.

### ref.listen()

**Purpose**: Perform side effects in response to state changes without rebuilding the widget.

**Use Cases**:

- Showing snackbars, dialogs, or navigation
- Logging or analytics
- Any action that should happen on state change but doesn't affect UI directly

```dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for authentication state changes
    ref.listen<AsyncValue<User>>(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          // Navigate on successful login
          Navigator.of(context).pushReplacementNamed('/home');
        },
        error: (error, stack) {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: $error')),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    // UI implementation
  }
}
```

**Important**: `ref.listen()` must be called in lifecycle methods or event handlers, not in `build()`.

### Comparison Table

| Method         | Rebuilds Widget | Use in build() | Use in handlers | Use for side effects |
| -------------- | --------------- | -------------- | --------------- | -------------------- |
| `ref.watch()`  | ✅ Yes          | ✅ Yes         | ❌ No           | ❌ No                |
| `ref.read()`   | ❌ No           | ❌ No          | ✅ Yes          | ❌ No                |
| `ref.listen()` | ❌ No           | ❌ No          | ✅ Yes          | ✅ Yes               |

---

## Modifiers and Advanced Features

### .autoDispose Modifier

Automatically disposes of a provider when it's no longer being watched. Prevents memory leaks and resets state when leaving screens.

```dart
final userProvider = FutureProvider.autoDispose<User>((ref) async {
  return await fetchUser();
});
```

**When to Use**:

- Screen-specific providers
- Providers managing resources (streams, timers, connections)
- Providers that should reset when screen is exited

**When NOT to Use**:

- Global app state (user preferences, theme)
- Shared data that should persist across screens
- Providers that are expensive to recreate

**Combining with ref.keepAlive()**:

```dart
final userProvider = FutureProvider.autoDispose<User>((ref) async {
  final user = await fetchUser();
  // Keep provider alive after successful fetch
  ref.keepAlive();
  return user;
});
```

**Resource Cleanup**:

```dart
final streamProvider = StreamProvider.autoDispose<List<Message>>((ref) {
  final controller = StreamController<List<Message>>();

  // Cleanup when provider is disposed
  ref.onDispose(() {
    controller.close();
  });

  return controller.stream;
});
```

### .family Modifier

Creates parameterized providers. Useful for filtering, searching, or fetching data based on parameters.

```dart
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  return await fetchUser(userId);
});

// Usage
final user = ref.watch(userProvider('123'));
```

**Combining with autoDispose**:

```dart
final filteredProductsProvider = FutureProvider.autoDispose
  .family<List<Product>, String>((ref, query) async {
  final allProducts = await ref.watch(allProductsProvider.future);
  return allProducts.where((p) => p.name.contains(query)).toList();
});
```

**Multiple Parameters**:

```dart
// Using a record (Dart 3.0+)
final userPostsProvider = FutureProvider.autoDispose
  .family<List<Post>, ({String userId, int page})>((ref, params) async {
  return await fetchUserPosts(params.userId, params.page);
});

// Usage
final posts = ref.watch(userPostsProvider((userId: '123', page: 1)));

// Alternative: Using a class
class UserPostsParams {
  final String userId;
  final int page;
  UserPostsParams(this.userId, this.page);
}

final userPostsProvider = FutureProvider.autoDispose
  .family<List<Post>, UserPostsParams>((ref, params) async {
  return await fetchUserPosts(params.userId, params.page);
});
```

### Provider Overrides

Override providers for testing, different environments, or feature flags.

```dart
// Production
final apiBaseUrlProvider = Provider<String>((ref) => 'https://api.prod.com');

// Testing
void main() {
  testWidgets('Test with mock API', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('https://api.test.com'),
          userRepositoryProvider.overrideWithValue(MockUserRepository()),
        ],
        child: MyApp(),
      ),
    );
  });
}
```

**Scoped Overrides**:

```dart
// Override only for a specific feature
class AdminFeature extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        permissionsProvider.overrideWithValue(AdminPermissions()),
      ],
      child: AdminScreen(),
    );
  }
}
```

---

## Code Organization for Large Applications

### Feature-Based Structure

Organize code by features rather than by technical layers. Each feature is self-contained.

```
lib/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── datasources/
│   │   │       ├── auth_remote_datasource.dart
│   │   │       └── auth_local_datasource.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       └── logout_usecase.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_providers.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── register_screen.dart
│   │       └── widgets/
│   │           └── login_form.dart
│   ├── products/
│   │   └── ... (same structure)
│   └── cart/
│       └── ... (same structure)
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── providers/
│       └── core_providers.dart
└── main.dart
```

### Provider Organization Strategies

#### Strategy 1: By Provider Type

```
lib/features/products/presentation/providers/
├── state_notifiers/
│   └── product_notifier.dart
├── future_providers/
│   └── product_list_provider.dart
└── stream_providers/
    └── product_updates_provider.dart
```

#### Strategy 2: By Feature (Recommended)

```
lib/features/products/presentation/providers/
├── product_providers.dart      # All product-related providers
├── cart_providers.dart         # Cart-related providers
└── favorites_providers.dart    # Favorites-related providers
```

#### Strategy 3: Single File per Provider

```
lib/features/products/presentation/providers/
├── product_list_provider.dart
├── product_detail_provider.dart
└── product_search_provider.dart
```

**Recommendation**: Use Strategy 2 for most cases. Group related providers together, but split into separate files if a file becomes too large (>300 lines).

### Global Providers

Place app-wide providers in a central location:

```dart
// lib/core/providers/core_providers.dart
final httpClientProvider = Provider<http.Client>((ref) => http.Client());
final loggerProvider = Provider<Logger>((ref) => Logger());
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier();
});
```

### Provider Naming Conventions

- **Providers**: `nounProvider` (e.g., `userProvider`, `productListProvider`)
- **Notifiers**: `NounNotifier` (e.g., `UserNotifier`, `ProductListNotifier`)
- **Notifier Providers**: `nounNotifierProvider` (e.g., `userNotifierProvider`)
- **Repositories**: `nounRepositoryProvider` (e.g., `userRepositoryProvider`)
- **Services**: `nounServiceProvider` (e.g., `authServiceProvider`)

---

## Performance Optimization

### Using select() to Minimize Rebuilds

Watch only specific parts of a provider's state to prevent unnecessary rebuilds.

```dart
class User {
  final String firstName;
  final String lastName;
  final String email;
  final int age;
}

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  return UserNotifier();
});

// ❌ Bad: Rebuilds when ANY property changes
class UserDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return Text(user.firstName); // Rebuilds even if lastName changes
  }
}

// ✅ Good: Only rebuilds when firstName changes
class UserDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = ref.watch(
      userProvider.select((user) => user.firstName),
    );
    return Text(firstName);
  }
}
```

**Important**: The selected property must be immutable. Use `freezed` or `copyWith` for updates.

### Extracting Widgets

Break down large widgets into smaller, focused widgets to limit rebuild scope.

```dart
// ❌ Bad: Entire widget rebuilds when any part changes
class ProductScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider);
    final reviews = ref.watch(reviewsProvider);
    final relatedProducts = ref.watch(relatedProductsProvider);

    return Column(
      children: [
        ProductHeader(product: product),
        ReviewsList(reviews: reviews),
        RelatedProducts(products: relatedProducts),
      ],
    );
  }
}

// ✅ Good: Each section rebuilds independently
class ProductScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ProductHeader(),
        ReviewsList(),
        RelatedProducts(),
      ],
    );
  }
}

class ProductHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider);
    return Text(product.name);
  }
}

class ReviewsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewsProvider);
    return ListView(children: reviews.map((r) => ReviewTile(r)).toList());
  }
}
```

### Debouncing and Throttling

For search or filter providers, debounce to avoid excessive API calls.

```dart
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose
  .family<List<Product>, String>((ref, query) async {
  // Debounce: Wait 500ms after last change
  await Future.delayed(Duration(milliseconds: 500));
  if (ref.read(searchQueryProvider) != query) {
    throw AbortException(); // Cancel if query changed
  }
  return await searchProducts(query);
});

// Usage
class SearchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider(query));
    // ...
  }
}
```

### Caching Strategies

Use providers to cache expensive computations or API responses.

```dart
final expensiveComputationProvider = Provider.autoDispose<String>((ref) {
  // This computation is cached while provider is alive
  return performExpensiveComputation();
});

// Share cache across multiple widgets
final sharedCacheProvider = Provider<String>((ref) {
  return performExpensiveComputation();
});
```

---

## Error Handling and AsyncValue

`AsyncValue` is Riverpod's way of handling asynchronous operations. It encapsulates three states: loading, data, and error.

### Understanding AsyncValue

```dart
// AsyncValue has three states:
AsyncValue<T> {
  AsyncLoading<T>    // Loading state
  AsyncData<T>       // Success state with data
  AsyncError<T>      // Error state with error and stack trace
}
```

### Using AsyncValue in UI

```dart
class UserProfile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userNotifierProvider);

    return userAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => ErrorWidget(error: error),
      data: (user) => UserDetails(user: user),
    );
  }
}
```

### Advanced AsyncValue Patterns

#### Preserving Previous Data During Refresh

```dart
class ProductList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsNotifierProvider);

    return productsAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error: error),
      data: (products) {
        // Show previous data while refreshing
        if (productsAsync.isRefreshing) {
          return Stack(
            children: [
              ProductsList(products: products),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          );
        }
        return ProductsList(products: products);
      },
    );
  }
}
```

#### Handling Partial Errors

```dart
final userAsync = ref.watch(userNotifierProvider);

userAsync.whenOrNull(
  error: (error, stack) {
    if (error is NetworkException) {
      return NetworkErrorWidget();
    } else if (error is AuthenticationException) {
      return LoginRequiredWidget();
    } else {
      return GenericErrorWidget(error: error);
    }
  },
);
```

#### Retry Logic

```dart
class RetryableFutureProvider extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataProvider);

    return dataAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Column(
        children: [
          Text('Error: $error'),
          ElevatedButton(
            onPressed: () => ref.refresh(dataProvider),
            child: Text('Retry'),
          ),
        ],
      ),
      data: (data) => DataDisplay(data: data),
    );
  }
}
```

### Global Error Handling

```dart
// lib/core/providers/error_handler_provider.dart
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});

class ErrorHandler {
  void handleError(BuildContext context, Object error, StackTrace stack) {
    // Log error
    logger.error('Error occurred', error, stack);

    // Show user-friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getUserFriendlyMessage(error)),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      ),
    );
  }

  String _getUserFriendlyMessage(Object error) {
    if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else if (error is AuthenticationException) {
      return 'Please log in to continue.';
    } else {
      return 'An unexpected error occurred.';
    }
  }
}

// Usage in providers
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    try {
      return await fetchUser();
    } catch (e, stack) {
      ref.read(errorHandlerProvider).handleError(context, e, stack);
      rethrow;
    }
  }
}
```

---

## Testing Strategies

### Unit Testing Providers

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('counter increments correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(counterNotifierProvider.notifier);
    expect(container.read(counterNotifierProvider), 0);

    notifier.increment();
    expect(container.read(counterNotifierProvider), 1);
  });
}
```

### Mocking Dependencies

```dart
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  test('user notifier fetches user correctly', () async {
    final mockRepository = MockUserRepository();
    when(mockRepository.getUser('123')).thenAnswer(
      (_) async => User(id: '123', name: 'Test User'),
    );

    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final userAsync = await container.read(userNotifierProvider.future);
    expect(userAsync.id, '123');
    expect(userAsync.name, 'Test User');
  });
}
```

### Widget Testing

```dart
testWidgets('UserProfile displays user data', (tester) async {
  final mockUser = User(id: '123', name: 'Test User', email: 'test@example.com');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userNotifierProvider.overrideWith(
          (ref) => UserNotifier()..state = AsyncData(mockUser),
        ),
      ],
      child: MaterialApp(
        home: UserProfileScreen(),
      ),
    ),
  );

  expect(find.text('Test User'), findsOneWidget);
  expect(find.text('test@example.com'), findsOneWidget);
});
```

### Testing Async Operations

```dart
test('user notifier handles errors correctly', () async {
  final mockRepository = MockUserRepository();
  when(mockRepository.getUser(any)).thenThrow(Exception('Network error'));

  final container = ProviderContainer(
    overrides: [
      userRepositoryProvider.overrideWithValue(mockRepository),
    ],
  );
  addTearDown(container.dispose);

  final userAsync = container.read(userNotifierProvider);

  expect(userAsync.isLoading, true);

  await container.read(userNotifierProvider.future).catchError((e) {
    expect(e, isA<Exception>());
  });
});
```

### Testing with ref.listen()

```dart
test('listener is called on state change', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  var lastValue = 0;
  container.listen(
    counterNotifierProvider,
    (previous, next) {
      lastValue = next;
    },
  );

  container.read(counterNotifierProvider.notifier).increment();
  expect(lastValue, 1);
});
```

---

## Code Generation with riverpod_generator

Riverpod's code generation reduces boilerplate and improves type safety. It's especially beneficial for large applications.

### Setup

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
```

### Basic Usage

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_providers.g.dart';

@riverpod
Future<User> fetchUser(FetchUserRef ref, {required String userId}) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUser(userId);
}

// Generated: fetchUserProvider
```

### AutoDispose by Default

With code generation, providers are `autoDispose` by default. Use `keepAlive: true` to prevent disposal.

```dart
@Riverpod(keepAlive: true)
Future<User> fetchUser(FetchUserRef ref, {required String userId}) async {
  // This provider won't auto-dispose
  return await repository.getUser(userId);
}
```

### Family Providers

```dart
@riverpod
Future<List<Product>> searchProducts(
  SearchProductsRef ref,
  String query,
) async {
  return await productRepository.search(query);
}

// Usage: ref.watch(searchProductsProvider('laptop'))
```

### Notifiers with Code Generation

```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}

// Generated: counterProvider
```

### AsyncNotifiers

```dart
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<User> build({required String userId}) async {
    final repository = ref.watch(userRepositoryProvider);
    return await repository.getUser(userId);
  }

  Future<void> updateUser(User user) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userRepositoryProvider);
      return await repository.updateUser(user);
    });
  }
}
```

### Running Code Generation

```bash
# Generate once
dart run build_runner build

# Watch for changes
dart run build_runner watch

# Clean and rebuild
dart run build_runner build --delete-conflicting-outputs
```

### Benefits of Code Generation

1. **Less Boilerplate**: No need to manually define provider variables
2. **Type Safety**: Better IDE support and compile-time checks
3. **Consistency**: Enforces naming conventions
4. **Refactoring**: Easier to rename and refactor providers
5. **Documentation**: Generated code is self-documenting

---

## Real-World Patterns and Best Practices

### Pattern 1: Pagination

```dart
@riverpod
class ProductList extends _$ProductList {
  @override
  Future<List<Product>> build() async {
    return await _loadPage(1);
  }

  Future<List<Product>> _loadPage(int page) async {
    final repository = ref.read(productRepositoryProvider);
    return await repository.getProducts(page: page, limit: 20);
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState.isLoading) return;

    final currentProducts = currentState.value ?? [];
    final nextPage = (currentProducts.length ~/ 20) + 1;

    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newProducts = await _loadPage(nextPage);
      return [...currentProducts, ...newProducts];
    });
  }
}
```

### Pattern 2: Optimistic Updates

```dart
@riverpod
class TodoList extends _$TodoList {
  @override
  Future<List<Todo>> build() async {
    return await ref.read(todoRepositoryProvider).getTodos();
  }

  Future<void> addTodo(Todo todo) async {
    // Optimistically update UI
    final currentTodos = state.value ?? [];
    state = AsyncData([...currentTodos, todo]);

    // Then sync with server
    try {
      final savedTodo = await ref.read(todoRepositoryProvider).addTodo(todo);
      final updatedTodos = [...currentTodos, savedTodo];
      state = AsyncData(updatedTodos);
    } catch (e, stack) {
      // Revert on error
      state = AsyncData(currentTodos);
      state = AsyncError(e, stack);
    }
  }
}
```

### Pattern 3: Form Validation

```dart
@riverpod
class LoginForm extends _$LoginForm {
  @override
  LoginFormState build() => LoginFormState();

  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      emailError: _validateEmail(email),
    );
  }

  void updatePassword(String password) {
    state = state.copyWith(
      password: password,
      passwordError: _validatePassword(password),
    );
  }

  Future<void> submit() async {
    if (!state.isValid) return;

    state = state.copyWith(isSubmitting: true);
    try {
      await ref.read(authRepositoryProvider).login(
        email: state.email,
        password: state.password,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }
}

class LoginFormState {
  final String email;
  final String password;
  final String? emailError;
  final String? passwordError;
  final bool isSubmitting;
  final String? submitError;

  LoginFormState({
    this.email = '',
    this.password = '',
    this.emailError,
    this.passwordError,
    this.isSubmitting = false,
    this.submitError,
  });

  bool get isValid =>
      emailError == null &&
      passwordError == null &&
      email.isNotEmpty &&
      password.isNotEmpty;

  LoginFormState copyWith({
    String? email,
    String? password,
    String? emailError,
    String? passwordError,
    bool? isSubmitting,
    String? submitError,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError ?? this.submitError,
    );
  }
}
```

### Pattern 4: State Machines

```dart
enum AuthState { initial, loading, authenticated, unauthenticated, error }

@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() => AuthState.initial;

  Future<void> login(String email, String password) async {
    state = AuthState.loading;
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      await ref.read(userStorageProvider).saveUser(user);
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      // Handle error
    }
  }

  Future<void> logout() async {
    state = AuthState.loading;
    await ref.read(authRepositoryProvider).logout();
    await ref.read(userStorageProvider).clearUser();
    state = AuthState.unauthenticated;
  }

  void checkAuthStatus() {
    final user = ref.read(userStorageProvider).getUser();
    state = user != null
        ? AuthState.authenticated
        : AuthState.unauthenticated;
  }
}
```

### Pattern 5: Dependency Injection Container

```dart
// lib/core/providers/di_providers.dart

// Infrastructure
final httpClientProvider = Provider<http.Client>((ref) => http.Client());
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must override in main');
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(httpClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(client, prefs);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(httpClientProvider);
  return UserRepository(client);
});

// Use cases
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MyApp(),
    ),
  );
}
```

### Best Practices Summary

1. **Use the Right Provider Type**

   - `Provider` for dependencies and constants
   - `StateProvider` for simple mutable state
   - `FutureProvider` for one-time async operations
   - `StreamProvider` for real-time data
   - `NotifierProvider` for complex state with logic
   - `AsyncNotifierProvider` for modifiable async state

2. **Leverage autoDispose**

   - Use for screen-specific providers
   - Use for providers managing resources
   - Don't use for global app state

3. **Separate Concerns**

   - Keep business logic in Notifiers
   - Keep UI logic in widgets
   - Use repositories for data access

4. **Optimize Rebuilds**

   - Use `select()` to watch specific properties
   - Extract widgets to limit rebuild scope
   - Use `ref.read()` in event handlers

5. **Handle Errors Gracefully**

   - Always handle `AsyncValue` states
   - Provide retry mechanisms
   - Show user-friendly error messages

6. **Test Thoroughly**

   - Mock dependencies
   - Test providers in isolation
   - Test error scenarios

7. **Organize Code Well**

   - Use feature-based structure
   - Group related providers
   - Keep providers close to where they're used

8. **Use Code Generation**
   - Reduces boilerplate
   - Improves type safety
   - Enforces consistency

---

## Complete Feature Example: Product Management

This section demonstrates a complete, production-ready feature implementing all four layers of the API-Repository-Riverpod-UI architecture. The example shows a product management system with listing, searching, detail viewing, and CRUD operations.

### Project Structure

```
lib/
├── features/
│   └── products/
│       ├── data/
│       │   ├── models/
│       │   │   └── product_model.dart
│       │   ├── datasources/
│       │   │   ├── product_remote_datasource.dart
│       │   │   └── product_local_datasource.dart
│       │   └── repositories/
│       │       └── product_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── product.dart
│       │   └── repositories/
│       │       └── product_repository.dart
│       └── presentation/
│           ├── providers/
│           │   └── product_providers.dart
│           ├── screens/
│           │   ├── product_list_screen.dart
│           │   ├── product_detail_screen.dart
│           │   └── product_form_screen.dart
│           └── widgets/
│               ├── product_card.dart
│               ├── product_search_bar.dart
│               └── product_list_item.dart
└── core/
    ├── network/
    │   └── api_client.dart
    └── storage/
        └── local_storage.dart
```

### Layer 1: Domain Entities

```dart
// lib/features/products/domain/entities/product.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    required String imageUrl,
    @Default(false) bool isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

// Repository interface
abstract class ProductRepository {
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? category,
    int page = 1,
    int limit = 20,
  });

  Future<Product> getProductById(String id);

  Future<Product> createProduct(Product product);

  Future<Product> updateProduct(Product product);

  Future<void> deleteProduct(String id);

  Future<void> toggleFavorite(String productId);
}
```

### Layer 2: Data Layer - Models and Data Sources

**Understanding DataSources:**

DataSources are the lowest-level data access components that directly interact with specific data sources (APIs, databases, files, etc.). They handle the technical details of fetching and storing data.

**Why Separate Local and Remote DataSources?**

1. **Different Technologies**: Remote uses HTTP/REST, local uses SQLite/SharedPreferences/Hive
2. **Different Concerns**: Remote handles network errors, authentication, serialization. Local handles persistence, caching, offline access
3. **Flexibility**: You can swap implementations (e.g., mock remote for testing, different local storage solutions)
4. **Single Responsibility**: Each DataSource has one job - either remote or local data access

**Testing with Mocktail:**

Since Dart classes can act as interfaces, we use concrete classes directly. For testing, `mocktail` can create mocks from these concrete classes without needing separate interface definitions:

```dart
class MockProductRemoteDataSource extends Mock implements ProductRemoteDataSource {}
```

This eliminates boilerplate while maintaining testability.

**The Flow:**
```
Repository → Remote DataSource → API/Network
Repository → Local DataSource → Database/Storage
```

The Repository orchestrates between Remote and Local DataSources, implementing caching strategies, fallback logic, and data synchronization.

```dart
// lib/features/products/data/models/product_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/product.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required String id,
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    required String imageUrl,
    @Default(false) bool isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  // Convert to domain entity
  Product toEntity() => Product(
        id: id,
        name: name,
        description: description,
        price: price,
        category: category,
        stock: stock,
        imageUrl: imageUrl,
        isFavorite: isFavorite,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  // Convert from domain entity
  factory ProductModel.fromEntity(Product product) => ProductModel(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        category: product.category,
        stock: product.stock,
        imageUrl: product.imageUrl,
        isFavorite: product.isFavorite,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
}

// lib/features/products/data/datasources/product_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../../../../core/network/api_client.dart';

class ProductRemoteDataSource {
  final ApiClient apiClient;

  ProductRemoteDataSource(this.apiClient);

  Future<List<ProductModel>> getProducts({
    String? searchQuery,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final response = await apiClient.get(
      '/products',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body)['data'];
      return jsonList
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  Future<ProductModel> getProductById(String id) async {
    final response = await apiClient.get('/products/$id');

    if (response.statusCode == 200) {
      return ProductModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load product: ${response.statusCode}');
    }
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    final response = await apiClient.post(
      '/products',
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 201) {
      return ProductModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to create product: ${response.statusCode}');
    }
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final response = await apiClient.put(
      '/products/${product.id}',
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return ProductModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to update product: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    final response = await apiClient.delete('/products/$id');

    if (response.statusCode != 204) {
      throw Exception('Failed to delete product: ${response.statusCode}');
    }
  }
}

// lib/features/products/data/datasources/product_local_datasource.dart
import '../models/product_model.dart';
import '../../../../core/storage/local_storage.dart';

class ProductLocalDataSource {
  final LocalStorage storage;

  ProductLocalDataSource(this.storage);

  static const String _productsKey = 'cached_products';
  static const String _favoritesKey = 'favorite_products';

  Future<List<ProductModel>> getCachedProducts() async {
    final jsonList = await storage.getList(_productsKey);
    return jsonList
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> cacheProducts(List<ProductModel> products) async {
    final jsonList = products.map((p) => p.toJson()).toList();
    await storage.saveList(_productsKey, jsonList);
  }

  Future<ProductModel?> getCachedProduct(String id) async {
    final products = await getCachedProducts();
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheProduct(ProductModel product) async {
    final products = await getCachedProducts();
    final index = products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.add(product);
    }
    await cacheProducts(products);
  }

  Future<void> clearCache() async {
    await storage.remove(_productsKey);
  }

  Future<List<String>> getFavoriteIds() async {
    return await storage.getList<String>(_favoritesKey);
  }

  Future<void> toggleFavorite(String productId) async {
    final favorites = await getFavoriteIds();
    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }
    await storage.saveList(_favoritesKey, favorites);
  }
}
```

### Layer 3: Repository Implementation

```dart
// lib/features/products/data/repositories/product_repository_impl.dart
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../datasources/product_local_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Try to fetch from remote
      final remoteProducts = await remoteDataSource.getProducts(
        searchQuery: searchQuery,
        category: category,
        page: page,
        limit: limit,
      );

      // Update favorites from local storage
      final favoriteIds = await localDataSource.getFavoriteIds();
      final productsWithFavorites = remoteProducts.map((p) {
        return p.copyWith(isFavorite: favoriteIds.contains(p.id));
      }).toList();

      // Cache first page only
      if (page == 1) {
        await localDataSource.cacheProducts(productsWithFavorites);
      }

      return productsWithFavorites.map((p) => p.toEntity()).toList();
    } catch (e) {
      // On error, try to return cached data (only for first page)
      if (page == 1) {
        try {
          final cachedProducts = await localDataSource.getCachedProducts();
          final favoriteIds = await localDataSource.getFavoriteIds();
          final productsWithFavorites = cachedProducts.map((p) {
            return p.copyWith(isFavorite: favoriteIds.contains(p.id));
          }).toList();
          return productsWithFavorites.map((p) => p.toEntity()).toList();
        } catch (_) {
          // If cache also fails, rethrow original error
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      // Try remote first
      final remoteProduct = await remoteDataSource.getProductById(id);
      final favoriteIds = await localDataSource.getFavoriteIds();
      final productWithFavorite = remoteProduct.copyWith(
        isFavorite: favoriteIds.contains(id),
      );
      await localDataSource.cacheProduct(productWithFavorite);
      return productWithFavorite.toEntity();
    } catch (e) {
      // Fallback to cache
      final cachedProduct = await localDataSource.getCachedProduct(id);
      if (cachedProduct != null) {
        return cachedProduct.toEntity();
      }
      rethrow;
    }
  }

  @override
  Future<Product> createProduct(Product product) async {
    final productModel = ProductModel.fromEntity(product);
    final created = await remoteDataSource.createProduct(productModel);
    await localDataSource.cacheProduct(created);
    return created.toEntity();
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final productModel = ProductModel.fromEntity(product);
    final updated = await remoteDataSource.updateProduct(productModel);
    await localDataSource.cacheProduct(updated);
    return updated.toEntity();
  }

  @override
  Future<void> deleteProduct(String id) async {
    await remoteDataSource.deleteProduct(id);
    // Note: In a real app, you might want to remove from cache too
  }

  @override
  Future<void> toggleFavorite(String productId) async {
    await localDataSource.toggleFavorite(productId);
    // In a real app, you might also sync this to the server
  }
}
```

### Layer 4: Riverpod Providers (with Code Generation)

```dart
// lib/features/products/presentation/providers/product_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';

part 'product_providers.g.dart';

// Infrastructure providers
@riverpod
ApiClient apiClient(ApiClientRef ref) => ApiClient(baseUrl: 'https://api.example.com');

@riverpod
LocalStorage localStorage(LocalStorageRef ref) => LocalStorage();

// Data source providers
@riverpod
ProductRemoteDataSource productRemoteDataSource(
  ProductRemoteDataSourceRef ref,
) {
  return ProductRemoteDataSource(ref.watch(apiClientProvider));
}

@riverpod
ProductLocalDataSource productLocalDataSource(
  ProductLocalDataSourceRef ref,
) {
  return ProductLocalDataSource(ref.watch(localStorageProvider));
}

// Repository provider
@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    localDataSource: ref.watch(productLocalDataSourceProvider),
  );
}

// Search query provider (simple state)
@riverpod
class ProductSearch extends _$ProductSearch {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
}

// Category filter provider
@riverpod
class ProductCategoryFilter extends _$ProductCategoryFilter {
  @override
  String? build() => null;

  void setCategory(String? category) => state = category;
  void clearFilter() => state = null;
}

// Product list notifier with pagination
@riverpod
class ProductList extends _$ProductList {
  @override
  Future<List<Product>> build() async {
    final searchQuery = ref.watch(productSearchProvider);
    final category = ref.watch(productCategoryFilterProvider);

    final repository = ref.watch(productRepositoryProvider);
    return await repository.getProducts(
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      category: category,
      page: 1,
      limit: 20,
    );
  }

  Future<void> refresh() async {
    // Invalidate and rebuild
    ref.invalidateSelf();
  }

  Future<void> loadMore() async {
    final currentProducts = state.value ?? [];
    final searchQuery = ref.read(productSearchProvider);
    final category = ref.read(productCategoryFilterProvider);
    final repository = ref.read(productRepositoryProvider);

    final nextPage = (currentProducts.length ~/ 20) + 1;
    final newProducts = await repository.getProducts(
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      category: category,
      page: nextPage,
      limit: 20,
    );

    state = AsyncData([...currentProducts, ...newProducts]);
  }

  Future<void> toggleFavorite(String productId) async {
    final repository = ref.read(productRepositoryProvider);
    await repository.toggleFavorite(productId);
    // Refresh to update favorite status
    ref.invalidateSelf();
  }
}

// Product detail provider (family for parameterized access)
@riverpod
Future<Product> productDetail(
  ProductDetailRef ref,
  String productId,
) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getProductById(productId);
}

// Product form notifier (for create/update)
@riverpod
class ProductForm extends _$ProductForm {
  @override
  ProductFormState build() => const ProductFormState();

  void updateName(String name) {
    state = state.copyWith(
      name: name,
      nameError: _validateName(name),
    );
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updatePrice(double price) {
    state = state.copyWith(
      price: price,
      priceError: _validatePrice(price),
    );
  }

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void updateStock(int stock) {
    state = state.copyWith(
      stock: stock,
      stockError: _validateStock(stock),
    );
  }

  void updateImageUrl(String imageUrl) {
    state = state.copyWith(imageUrl: imageUrl);
  }

  void loadProduct(Product product) {
    state = ProductFormState(
      productId: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category,
      stock: product.stock,
      imageUrl: product.imageUrl,
    );
  }

  Future<void> submit() async {
    if (!state.isValid) return;

    state = state.copyWith(isSubmitting: true);

    try {
      final repository = ref.read(productRepositoryProvider);
      final product = Product(
        id: state.productId ?? '',
        name: state.name,
        description: state.description,
        price: state.price,
        category: state.category,
        stock: state.stock,
        imageUrl: state.imageUrl,
      );

      if (state.productId == null) {
        await repository.createProduct(product);
      } else {
        await repository.updateProduct(product);
      }

      // Invalidate product list to refresh
      ref.invalidate(productListProvider);
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e, stack) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
    }
  }

  void reset() {
    state = const ProductFormState();
  }

  String? _validateName(String name) {
    if (name.isEmpty) return 'Name is required';
    if (name.length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validatePrice(double price) {
    if (price <= 0) return 'Price must be greater than 0';
    return null;
  }

  String? _validateStock(int stock) {
    if (stock < 0) return 'Stock cannot be negative';
    return null;
  }
}

// Form state class
class ProductFormState {
  final String? productId;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stock;
  final String imageUrl;
  final String? nameError;
  final String? priceError;
  final String? stockError;
  final bool isSubmitting;
  final bool isSuccess;
  final String? submitError;

  const ProductFormState({
    this.productId,
    this.name = '',
    this.description = '',
    this.price = 0.0,
    this.category = '',
    this.stock = 0,
    this.imageUrl = '',
    this.nameError,
    this.priceError,
    this.stockError,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.submitError,
  });

  bool get isValid =>
      nameError == null &&
      priceError == null &&
      stockError == null &&
      name.isNotEmpty &&
      category.isNotEmpty;

  ProductFormState copyWith({
    String? productId,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    String? imageUrl,
    String? nameError,
    String? priceError,
    String? stockError,
    bool? isSubmitting,
    bool? isSuccess,
    String? submitError,
  }) {
    return ProductFormState(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      nameError: nameError ?? this.nameError,
      priceError: priceError ?? this.priceError,
      stockError: stockError ?? this.stockError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      submitError: submitError ?? this.submitError,
    );
  }
}
```

### Layer 5: UI Layer

```dart
// lib/features/products/presentation/screens/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_providers.dart';
import '../widgets/product_search_bar.dart';
import '../widgets/product_list_item.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final searchQuery = ref.watch(productSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/products/new');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ProductSearchBar(),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(productListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No products found'
                              : 'No products match "$searchQuery"',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(productListProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductListItem(
                        product: product,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/products/${product.id}',
                          );
                        },
                        onFavoriteToggle: () {
                          ref
                              .read(productListProvider.notifier)
                              .toggleFavorite(product.id);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// lib/features/products/presentation/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/products/$productId/edit');
            },
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(productDetailProvider(productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (product) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(label: Text(product.category)),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('Stock: ${product.stock}'),
                    backgroundColor: product.stock > 0
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(product.description),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(productListProvider.notifier)
                        .toggleFavorite(product.id);
                  },
                  icon: Icon(
                    product.isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text(
                    product.isFavorite
                        ? 'Remove from Favorites'
                        : 'Add to Favorites',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/products/presentation/screens/product_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_providers.dart';
import '../../domain/entities/product.dart';

class ProductFormScreen extends ConsumerWidget {
  final Product? product;

  const ProductFormScreen({
    super.key,
    this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(productFormProvider);
    final isEdit = product != null;

    // Load product data if editing
    ref.listen(productFormProvider, (previous, next) {
      if (product != null && previous?.productId == null) {
        ref.read(productFormProvider.notifier).loadProduct(product!);
      }
    });

    // Navigate back on success
    ref.listen(productFormProvider.select((s) => s.isSuccess), (prev, next) {
      if (next) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Product updated successfully'
                : 'Product created successfully'),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: formState.name,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: formState.nameError,
                ),
                onChanged: (value) =>
                    ref.read(productFormProvider.notifier).updateName(value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: formState.description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onChanged: (value) => ref
                    .read(productFormProvider.notifier)
                    .updateDescription(value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: formState.price.toString(),
                decoration: InputDecoration(
                  labelText: 'Price',
                  errorText: formState.priceError,
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null) {
                    ref.read(productFormProvider.notifier).updatePrice(price);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: formState.category,
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: (value) => ref
                    .read(productFormProvider.notifier)
                    .updateCategory(value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: formState.stock.toString(),
                decoration: InputDecoration(
                  labelText: 'Stock',
                  errorText: formState.stockError,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final stock = int.tryParse(value);
                  if (stock != null) {
                    ref.read(productFormProvider.notifier).updateStock(stock);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: formState.imageUrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
                onChanged: (value) => ref
                    .read(productFormProvider.notifier)
                    .updateImageUrl(value),
              ),
              const SizedBox(height: 24),
              if (formState.submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    formState.submitError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ElevatedButton(
                onPressed: formState.isValid && !formState.isSubmitting
                    ? () => ref.read(productFormProvider.notifier).submit()
                    : null,
                child: formState.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Update Product' : 'Create Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/products/presentation/widgets/product_search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_providers.dart';

class ProductSearchBar extends ConsumerWidget {
  const ProductSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(productSearchProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(productSearchProvider.notifier).updateQuery('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          ref.read(productSearchProvider.notifier).updateQuery(value);
        },
      ),
    );
  }
}

// lib/features/products/presentation/widgets/product_list_item.dart
import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: product.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  product.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.inventory_2),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.category),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            product.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: product.isFavorite ? Colors.red : null,
          ),
          onPressed: onFavoriteToggle,
        ),
        onTap: onTap,
      ),
    );
  }
}
```

### Testing Example

```dart
// test/features/products/presentation/providers/product_providers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:in_phase/features/products/domain/entities/product.dart';
import 'package:in_phase/features/products/domain/repositories/product_repository.dart';
import 'package:in_phase/features/products/presentation/providers/product_providers.dart';

// Mock the concrete class directly - Dart classes act as interfaces
class MockProductRepository extends Mock implements ProductRepository {}

// You can also mock DataSources directly if testing Repository:
// class MockProductRemoteDataSource extends Mock implements ProductRemoteDataSource {}
// class MockProductLocalDataSource extends Mock implements ProductLocalDataSource {}

void main() {
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
  });

  test('ProductList loads products successfully', () async {
    final products = [
      Product(
        id: '1',
        name: 'Test Product',
        description: 'Test Description',
        price: 10.0,
        category: 'Test',
        stock: 5,
        imageUrl: '',
      ),
    ];

    when(() => mockRepository.getProducts(
          searchQuery: any(named: 'searchQuery'),
          category: any(named: 'category'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => products);

    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final productListAsync = await container.read(productListProvider.future);
    expect(productListAsync.length, 1);
    expect(productListAsync.first.name, 'Test Product');
  });

  test('ProductForm validates input correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(productFormProvider.notifier);

    // Test empty name
    notifier.updateName('');
    final state1 = container.read(productFormProvider);
    expect(state1.nameError, isNotNull);
    expect(state1.isValid, false);

    // Test valid name
    notifier.updateName('Valid Product Name');
    final state2 = container.read(productFormProvider);
    expect(state2.nameError, isNull);

    // Test invalid price
    notifier.updatePrice(-1);
    final state3 = container.read(productFormProvider);
    expect(state3.priceError, isNotNull);
    expect(state3.isValid, false);

    // Test valid price
    notifier.updatePrice(10.0);
    final state4 = container.read(productFormProvider);
    expect(state4.priceError, isNull);
  });
}
```

### Key Takeaways from This Example

1. **Clear Layer Separation**: Each layer has a distinct responsibility
2. **Dependency Injection**: All dependencies are injected through providers
3. **Error Handling**: Comprehensive error handling at each layer
4. **Caching Strategy**: Smart caching with fallback to local data
5. **Optimistic Updates**: Favorites update immediately in UI
6. **Form Validation**: Real-time validation with clear error messages
7. **Pagination**: Efficient pagination with load-more functionality
8. **Code Generation**: Uses `@riverpod` for cleaner, type-safe code
9. **Testing**: Easy to test with provider overrides
10. **User Experience**: Loading states, error recovery, pull-to-refresh

This example demonstrates a production-ready implementation following all Riverpod best practices and the API-Repository-Riverpod-UI architecture pattern.

---

## Conclusion

Riverpod provides a powerful, scalable, and maintainable approach to state management in Flutter applications. By following the API-Repository-Riverpod-UI architecture pattern and adhering to best practices, you can build large, complex applications that are easy to test, maintain, and extend.

Key takeaways:

- Choose the right provider type for your use case
- Separate concerns into distinct layers
- Optimize performance with `select()` and widget extraction
- Handle errors gracefully with `AsyncValue`
- Test thoroughly with provider overrides
- Organize code by features
- Leverage code generation for better developer experience

For more information, refer to the official Riverpod documentation: https://riverpod.dev
