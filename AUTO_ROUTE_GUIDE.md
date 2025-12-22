# Auto Route Guide: Complete Handbook for Flutter Navigation

## Table of Contents
1. [Introduction](#introduction)
2. [Core Concepts](#core-concepts)
3. [Setup and Configuration](#setup-and-configuration)
4. [Basic Navigation](#basic-navigation)
5. [Route Parameters](#route-parameters)
6. [Nested Navigation](#nested-navigation)
7. [Route Guards](#route-guards)
8. [Advanced Features](#advanced-features)
9. [Best Practices](#best-practices)
10. [Real-World Example](#real-world-example)

---

## Introduction

**Auto Route** is a powerful, declarative routing solution for Flutter that leverages code generation to create strongly-typed, maintainable navigation systems. It eliminates boilerplate code, provides compile-time safety, and scales elegantly from small apps to large, complex applications.

### Why Auto Route?

- **Type Safety**: Compile-time route checking prevents runtime navigation errors
- **Code Generation**: Automatically generates route classes, reducing manual work
- **Deep Linking**: Built-in support for URL-based navigation and deep links
- **Nested Navigation**: Handles complex navigation structures (tabs, nested stacks)
- **Route Guards**: Middleware-like protection for authentication and permissions
- **Declarative & Imperative**: Supports both navigation paradigms
- **Maintainability**: Centralized route definitions make large apps manageable

### Key Philosophy

Auto Route follows Flutter's declarative paradigm while providing imperative navigation APIs when needed. Routes are defined once, generated automatically, and used throughout the app with full type safety.

---

## Core Concepts

### 1. Route Definition

Routes are defined declaratively in a router class using annotations. Each route maps a path pattern to a page widget.

```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomePage, initial: true),
    AutoRoute(path: '/books', page: BooksPage),
    AutoRoute(path: '/books/:id', page: BookDetailsPage),
  ];
}
```

### 2. Code Generation

Auto Route uses `build_runner` to generate:
- Route classes (e.g., `HomeRoute`, `BooksRoute`, `BookDetailsRoute`)
- Router implementation with navigation methods
- Type-safe argument passing

**Generated Files**: After running `dart run build_runner build`, you'll get `app_router.gr.dart` containing all generated code.

### 3. Router Types

- **RootStackRouter**: Main app router managing the root navigation stack
- **StackRouter**: Manages a navigation stack (can be nested)
- **TabsRouter**: Manages tab-based navigation

### 4. Route Annotations

- `@RoutePage()`: Marks a widget as a routable page
- `@AutoRouterConfig()`: Marks the router configuration class
- `@CustomRoute()`: Customizes route behavior (transitions, fullscreen, etc.)
- `@PathParam()`: Extracts path parameters
- `@QueryParam()`: Extracts query parameters

---

## Setup and Configuration

### Step 1: Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  auto_route: ^9.3.0
  auto_route_annotations: ^9.3.0

dev_dependencies:
  auto_route_generator: ^9.3.0
  build_runner: ^2.4.8
```

### Step 2: Create Router Configuration

Create `lib/core/router/app_router.dart`:

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../features/home/home_page.dart';
import '../../features/books/books_page.dart';
import '../../features/books/book_details_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomePage, initial: true),
    AutoRoute(path: '/books', page: BooksPage),
    AutoRoute(path: '/books/:id', page: BookDetailsPage),
  ];
}
```

### Step 3: Annotate Pages

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome')),
    );
  }
}
```

### Step 4: Generate Routes

```bash
dart run build_runner build --delete-conflicting-outputs
```

For development with watch mode:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Step 5: Integrate with MaterialApp

```dart
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _appRouter.config(),
      title: 'My App',
    );
  }
}
```

---

## Basic Navigation

### Navigation Methods

Auto Route provides several navigation methods through the generated router:

```dart
// Get router from context
final router = context.router;

// Push a new route
router.push(const BooksRoute());

// Push and replace current route
router.pushAndPopUntil(
  const LoginRoute(),
  predicate: (route) => false, // Remove all previous routes
);

// Pop current route
router.pop();

// Pop with result
router.pop('result data');

// Replace current route
router.replace(const BooksRoute());

// Push and remove until condition
router.pushAndPopUntil(
  const DashboardRoute(),
  predicate: (route) => route.name == HomeRoute.name,
);
```

### Context Extensions

Auto Route extends `BuildContext` with convenient methods:

```dart
// Push route
context.pushRoute(const BooksRoute());

// Push and replace
context.router.replace(const BooksRoute());

// Pop
context.popRoute();

// Pop with result
context.popRoute('result');
```

### Type-Safe Navigation

Always use generated route classes instead of strings:

```dart
// ✅ Good - Type-safe
context.pushRoute(BookDetailsRoute(bookId: 123));

// ❌ Bad - Runtime errors possible
Navigator.pushNamed(context, '/books/123');
```

---

## Route Parameters

### Path Parameters

Extract dynamic segments from the URL path:

**Route Definition:**
```dart
AutoRoute(path: '/books/:id', page: BookDetailsPage),
```

**Page Widget:**
```dart
@RoutePage()
class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({
    @PathParam('id') required this.bookId,
    super.key,
  });

  final int bookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book $bookId')),
      body: Center(child: Text('Details for book $bookId')),
    );
  }
}
```

**Navigation:**
```dart
context.pushRoute(BookDetailsRoute(bookId: 123));
```

### Query Parameters

Access query parameters from the URL:

**Route Definition:**
```dart
AutoRoute(path: '/search', page: SearchPage),
```

**Page Widget:**
```dart
@RoutePage()
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final queryParams = context.routeData.queryParams;
    final query = queryParams.getString('q');
    final category = queryParams.getString('category');

    return Scaffold(
      appBar: AppBar(title: Text('Search: $query')),
      body: Text('Category: $category'),
    );
  }
}
```

**Navigation:**
```dart
context.pushRoute(SearchRoute());
// URL: /search?q=flutter&category=books
```

### Constructor Parameters

Pass complex objects directly to routes:

**Page Widget:**
```dart
@RoutePage()
class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({
    required this.book,
    super.key,
  });

  final Book book; // Must be serializable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: Text(book.description),
    );
  }
}
```

**Navigation:**
```dart
context.pushRoute(BookDetailsRoute(book: myBook));
```

**Note**: For constructor parameters, the type must implement `JsonSerializable` or be a primitive type.

---

## Nested Navigation

### Tab Navigation

Auto Route excels at managing tab-based navigation with independent navigation stacks.

**Route Definition:**
```dart
AutoRoute(
  path: '/dashboard',
  page: DashboardPage,
  children: [
    AutoRoute(path: '/home', page: HomeTabPage, initial: true),
    AutoRoute(path: '/profile', page: ProfileTabPage),
    AutoRoute(path: '/settings', page: SettingsTabPage),
  ],
),
```

**Dashboard Page with AutoTabsRouter:**
```dart
@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        HomeTabRoute(),
        ProfileTabRoute(),
        SettingsTabRoute(),
      ],
      builder: (context, child, animation) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          body: FadeTransition(
            opacity: animation,
            child: child,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
```

**Alternative: AutoTabsScaffold**

For simpler tab navigation:

```dart
@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [
        HomeTabRoute(),
        ProfileTabRoute(),
        SettingsTabRoute(),
      ],
      bottomNavigationBuilder: (_, tabsRouter) {
        return BottomNavigationBar(
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        );
      },
    );
  }
}
```

### Nested Stack Navigation

For complex navigation hierarchies:

```dart
AutoRoute(
  path: '/shop',
  page: ShopPage,
  children: [
    AutoRoute(path: '/products', page: ProductsPage, initial: true),
    AutoRoute(path: '/products/:id', page: ProductDetailsPage),
    AutoRoute(path: '/cart', page: CartPage),
  ],
),
```

Each nested router maintains its own navigation stack independently.

---

## Route Guards

Route guards act as middleware, intercepting navigation to enforce conditions before allowing access.

### Creating a Guard

```dart
import 'package:auto_route/auto_route.dart';

class AuthGuard extends AutoRouteGuard {
  final AuthService authService;

  AuthGuard(this.authService);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (authService.isAuthenticated) {
      // Allow navigation
      resolver.next(true);
    } else {
      // Redirect to login
      resolver.redirectUntil(
        LoginRoute(
          onResult: (didLogin) {
            if (didLogin) {
              resolver.next(true);
            } else {
              resolver.next(false);
            }
          },
        ),
      );
    }
  }
}
```

### Applying Guards to Routes

**Single Route:**
```dart
AutoRoute(
  path: '/profile',
  page: ProfilePage,
  guards: [AuthGuard],
),
```

**Multiple Guards:**
```dart
AutoRoute(
  path: '/admin',
  page: AdminPage,
  guards: [AuthGuard, AdminGuard],
),
```

Guards execute in order. All must call `resolver.next()` for navigation to proceed.

### Global Guards

Apply guards to all routes:

```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  late final List<AutoRouteGuard> guards = [
    AuthGuard(authService),
  ];

  @override
  List<AutoRoute> get routes => [
    // All routes protected by AuthGuard
  ];
}
```

### Simple Guard Factory

For simpler cases:

```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  late final List<AutoRouteGuard> guards = [
    AutoRouteGuard.simple((resolver, router) {
      if (isAuthenticated || resolver.routeName == LoginRoute.name) {
        resolver.next();
      } else {
        resolver.redirectUntil(LoginRoute());
      }
    }),
  ];
}
```

---

## Advanced Features

### Custom Transitions

Define custom page transitions:

```dart
@CustomRoute(
  page: BooksPage,
  transitionsBuilder: TransitionsBuilders.slideTop,
  durationInMilliseconds: 400,
)
class BooksRoute extends PageRouteInfo {}
```

**Predefined Transitions:**
- `TransitionsBuilders.fadeIn`
- `TransitionsBuilders.slideLeft`
- `TransitionsBuilders.slideRight`
- `TransitionsBuilders.slideTop`
- `TransitionsBuilders.slideBottom`
- `TransitionsBuilders.slideLeftWithFade`

**Custom Transition Builder:**
```dart
Widget zoomTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return ScaleTransition(
    scale: CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    ),
    child: child,
  );
}

@CustomRoute(
  page: ZoomPage,
  transitionsBuilder: zoomTransition,
  durationInMilliseconds: 300,
)
class ZoomRoute extends PageRouteInfo {}
```

### Route Wrappers

Wrap routes with providers or other widgets:

```dart
@RoutePage()
class BookDetailsPage extends StatelessWidget implements AutoRouteWrapper {
  const BookDetailsPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return Provider(
      create: (_) => BookDetailsBloc(),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Page content
  }
}
```

### Fullscreen Dialogs

```dart
@CustomRoute(
  page: LoginPage,
  fullscreenDialog: true,
)
class LoginRoute extends PageRouteInfo {}
```

### Redirect Routes

Handle path redirects:

```dart
AutoRoute(
  path: '/home',
  page: HomePage,
),
RedirectRoute(
  path: '/',
  redirectTo: '/home',
),
```

### Route Observers

Track navigation for analytics:

```dart
class AnalyticsObserver extends AutoRouterObserver {
  final AnalyticsService analytics;

  AnalyticsObserver(this.analytics);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    analytics.logScreenView(route.settings.name ?? 'unknown');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    analytics.logScreenExit(route.settings.name ?? 'unknown');
  }
}

// In MaterialApp.router:
MaterialApp.router(
  routerConfig: _appRouter.config(
    navigatorObservers: () => [AnalyticsObserver(analytics)],
  ),
);
```

### Declarative Routing

Define routes based on app state:

```dart
AutoRouter.declarative(
  routes: (context) => [
    BookListRoute(),
    if (_selectedBook != null)
      BookDetailsRoute(bookId: _selectedBook!.id),
  ],
);
```

**Important**: Don't mix declarative and imperative navigation in the same router.

### Deep Linking

Auto Route automatically handles deep links. Configure URL schemes in platform-specific files:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="myapp" />
</intent-filter>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

Navigate via URL:
```dart
// myapp://books/123
context.router.pushNamed('/books/123');
```

---

## Best Practices

### 1. Project Structure

Organize routes in a dedicated directory:

```
lib/
├── core/
│   ├── router/
│   │   ├── app_router.dart
│   │   └── guards/
│   │       ├── auth_guard.dart
│   │       └── admin_guard.dart
│   └── ...
├── features/
│   ├── home/
│   │   └── home_page.dart
│   ├── books/
│   │   ├── books_page.dart
│   │   └── book_details_page.dart
│   └── ...
└── main.dart
```

### 2. Use Type-Safe Routes

Always use generated route classes:

```dart
// ✅ Good
context.pushRoute(BookDetailsRoute(bookId: 123));

// ❌ Bad
context.router.pushNamed('/books/123');
```

### 3. Centralize Route Definitions

Keep all routes in one or a few router files. Don't scatter route definitions across the codebase.

### 4. Separate Navigation Logic

Don't embed navigation logic in widgets. Use services or view models:

```dart
// ✅ Good
class BookListViewModel {
  void navigateToDetails(BuildContext context, int bookId) {
    context.pushRoute(BookDetailsRoute(bookId: bookId));
  }
}

// ❌ Bad
class BookListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.pushRoute(BookDetailsRoute(bookId: 123)),
      // ...
    );
  }
}
```

### 5. Use Route Guards for Authentication

Protect routes at the router level, not in widgets:

```dart
// ✅ Good
AutoRoute(
  path: '/profile',
  page: ProfilePage,
  guards: [AuthGuard],
),

// ❌ Bad
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return LoginPage();
    }
    // ...
  }
}
```

### 6. Handle Navigation Results

Use results for data flow:

```dart
// Navigate and wait for result
final result = await context.pushRoute(EditBookRoute(book: book));
if (result == true) {
  // Refresh book list
}

// In EditBookPage:
context.popRoute(true); // Return result
```

### 7. Test Navigation

Mock routers in tests:

```dart
class MockStackRouter extends Mock implements StackRouter {}

void main() {
  test('navigates to book details', () {
    final router = MockStackRouter();
    router.push(BookDetailsRoute(bookId: 123));
    verify(() => router.push(any(that: isA<BookDetailsRoute>()))).called(1);
  });
}
```

### 8. Use Build Runner Watch in Development

```bash
dart run build_runner watch --delete-conflicting-outputs
```

This regenerates routes automatically when you change route definitions.

### 9. Handle Route Parameters Safely

Always validate path parameters:

```dart
@RoutePage()
class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({
    @PathParam('id') required this.bookId,
    super.key,
  });

  final int bookId;

  @override
  Widget build(BuildContext context) {
    // Validate bookId exists before using
    return FutureBuilder<Book?>(
      future: bookRepository.getBook(bookId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorWidget(snapshot.error!);
        }
        // ...
      },
    );
  }
}
```

### 10. Organize Nested Routes Logically

Group related routes under parent routes:

```dart
// ✅ Good - Logical grouping
AutoRoute(
  path: '/shop',
  page: ShopPage,
  children: [
    AutoRoute(path: '/products', page: ProductsPage),
    AutoRoute(path: '/cart', page: CartPage),
    AutoRoute(path: '/checkout', page: CheckoutPage),
  ],
),
```

---

## Real-World Example

This example demonstrates a complete feature implementation using auto_route in a production-style Flutter app: a **Book Library** feature with authentication, nested navigation, and route guards.

### Project Structure

```
lib/
├── core/
│   ├── router/
│   │   ├── app_router.dart
│   │   └── guards/
│   │       └── auth_guard.dart
│   ├── services/
│   │   └── auth_service.dart
│   └── models/
│       └── book.dart
├── features/
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── login_bloc.dart
│   ├── home/
│   │   └── home_page.dart
│   └── books/
│       ├── books_list_page.dart
│       ├── book_details_page.dart
│       ├── book_edit_page.dart
│       └── books_bloc.dart
└── main.dart
```

### Models

```dart
// lib/core/models/book.dart
class Book {
  final int id;
  final String title;
  final String author;
  final String? description;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
  });

  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? description,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
    );
  }
}
```

### Auth Service

```dart
// lib/core/services/auth_service.dart
class AuthService {
  bool _isAuthenticated = false;
  
  bool get isAuthenticated => _isAuthenticated;
  
  Future<bool> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    _isAuthenticated = email.isNotEmpty && password.isNotEmpty;
    return _isAuthenticated;
  }
  
  void logout() {
    _isAuthenticated = false;
  }
}
```

### Auth Guard

```dart
// lib/core/router/guards/auth_guard.dart
import 'package:auto_route/auto_route.dart';
import '../../services/auth_service.dart';
import '../../../features/auth/login_page.dart';

class AuthGuard extends AutoRouteGuard {
  final AuthService authService;

  AuthGuard(this.authService);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (authService.isAuthenticated) {
      resolver.next(true);
    } else {
      resolver.redirectUntil(
        LoginRoute(
          onResult: (didLogin) {
            if (didLogin && authService.isAuthenticated) {
              resolver.next(true);
            } else {
              resolver.next(false);
            }
          },
        ),
      );
    }
  }
}
```

### Router Configuration

```dart
// lib/core/router/app_router.dart
import 'package:auto_route/auto_route.dart';
import '../../features/auth/login_page.dart';
import '../../features/home/home_page.dart';
import '../../features/books/books_list_page.dart';
import '../../features/books/book_details_page.dart';
import '../../features/books/book_edit_page.dart';
import 'guards/auth_guard.dart';
import '../../core/services/auth_service.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  final AuthService authService;

  AppRouter(this.authService);

  @override
  List<AutoRoute> get routes => [
    // Public routes
    AutoRoute(page: LoginPage, initial: true, path: '/login'),
    
    // Protected routes with auth guard
    AutoRoute(
      path: '/home',
      page: HomePage,
      guards: [AuthGuard],
    ),
    
    // Books feature with nested navigation
    AutoRoute(
      path: '/books',
      page: BooksListPage,
      guards: [AuthGuard],
      children: [
        AutoRoute(
          path: '/:id',
          page: BookDetailsPage,
        ),
      ],
    ),
    
    // Book edit (fullscreen dialog)
    AutoRoute(
      path: '/books/:id/edit',
      page: BookEditPage,
      guards: [AuthGuard],
      fullscreenDialog: true,
    ),
  ];
}
```

### Login Page

```dart
// lib/features/auth/login_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  final void Function(bool)? onResult;

  const LoginPage({super.key, this.onResult});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    final success = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (success) {
      widget.onResult?.call(true);
      if (mounted) {
        context.router.replace(const HomeRoute());
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Home Page

```dart
// lib/features/home/home_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../books/books_list_page.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout
              context.router.pushAndPopUntil(
                const LoginRoute(),
                predicate: (_) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Book Library'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.pushRoute(const BooksListRoute());
              },
              child: const Text('Browse Books'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Books List Page

```dart
// lib/features/books/books_list_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../core/models/book.dart';
import 'book_details_page.dart';

@RoutePage()
class BooksListPage extends StatelessWidget {
  const BooksListPage({super.key});

  // Mock data - in real app, fetch from repository
  final List<Book> _books = const [
    Book(id: 1, title: 'Flutter Complete Reference', author: 'Alberto Miola'),
    Book(id: 2, title: 'Dart in Action', author: 'Chris Buckett'),
    Book(id: 3, title: 'Effective Dart', author: 'Dart Team'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popRoute(),
        ),
      ),
      body: ListView.builder(
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return ListTile(
            title: Text(book.title),
            subtitle: Text(book.author),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to book details using nested route
              context.pushRoute(BookDetailsRoute(bookId: book.id));
            },
          );
        },
      ),
    );
  }
}
```

### Book Details Page

```dart
// lib/features/books/book_details_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../core/models/book.dart';
import 'book_edit_page.dart';

@RoutePage()
class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({
    @PathParam('id') required this.bookId,
    super.key,
  });

  final int bookId;

  // Mock data - in real app, fetch from repository
  Book? _getBook(int id) {
    final books = {
      1: Book(
        id: 1,
        title: 'Flutter Complete Reference',
        author: 'Alberto Miola',
        description: 'A comprehensive guide to Flutter development.',
      ),
      2: Book(
        id: 2,
        title: 'Dart in Action',
        author: 'Chris Buckett',
        description: 'Learn Dart programming language.',
      ),
      3: Book(
        id: 3,
        title: 'Effective Dart',
        author: 'Dart Team',
        description: 'Best practices for Dart development.',
      ),
    };
    return books[id];
  }

  @override
  Widget build(BuildContext context) {
    final book = _getBook(bookId);

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Not Found')),
        body: const Center(child: Text('Book not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigate to edit page as fullscreen dialog
              final result = await context.pushRoute(
                BookEditRoute(book: book),
              );
              
              // Refresh if book was updated
              if (result == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Book updated')),
                );
                // In real app, refresh the book data
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Author: ${book.author}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (book.description != null) ...[
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(book.description!),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Book Edit Page

```dart
// lib/features/books/book_edit_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../core/models/book.dart';

@RoutePage()
class BookEditPage extends StatefulWidget {
  final Book book;

  const BookEditPage({
    required this.book,
    super.key,
  });

  @override
  State<BookEditPage> createState() => _BookEditPageState();
}

class _BookEditPageState extends State<BookEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _descriptionController = TextEditingController(
      text: widget.book.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // In real app, save to repository
    // For now, just return success
    context.popRoute(true);
  }

  void _handleCancel() {
    context.popRoute(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
        ),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Author'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}
```

### Main App

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _authService = AuthService();
  late final _appRouter = AppRouter(_authService);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _appRouter.config(),
      title: 'Book Library',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
```

### Key Features Demonstrated

1. **Authentication Flow**: Login page with route guard protecting authenticated routes
2. **Nested Navigation**: Books list → Book details navigation stack
3. **Route Parameters**: Book ID passed via path parameter
4. **Fullscreen Dialog**: Edit page presented as modal
5. **Navigation Results**: Edit page returns success/failure result
6. **Route Guards**: Auth guard protects all book-related routes
7. **Type Safety**: All navigation uses generated route classes
8. **Clean Architecture**: Separation of concerns with services, models, and pages

### Running the Example

1. Generate routes:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. Run the app:
   ```bash
   flutter run
   ```

3. Test the flow:
   - App starts at login page
   - Login with any credentials (non-empty)
   - Navigate to books list
   - Tap a book to see details
   - Edit book (fullscreen dialog)
   - Save or cancel edit

This example demonstrates production-ready patterns for using auto_route in a maintainable, scalable Flutter application.

---

## Conclusion

Auto Route provides a robust, type-safe navigation solution for Flutter applications. By leveraging code generation, it eliminates boilerplate while maintaining flexibility for complex navigation scenarios. The combination of route guards, nested navigation, and declarative routing makes it ideal for large-scale applications.

Key takeaways:
- **Type safety** prevents runtime navigation errors
- **Code generation** reduces manual work and maintenance
- **Route guards** provide clean authentication/permission handling
- **Nested navigation** handles complex app structures elegantly
- **Best practices** ensure maintainable, scalable codebases

For more information, refer to the [official Auto Route documentation](https://autoroute.vercel.app/).





