// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// 🐦 Flutter imports:
import 'package:flutter/material.dart';

// 📦 Package imports:
import 'package:go_router/go_router.dart';

/// This sample app shows an app with two screens.
///
/// The first route '/' is mapped to [HomeScreen], and the second route
/// '/details' is mapped to [DetailsScreen].
///
/// The buttons use context.go() to navigate to each destination. On mobile
/// devices, each destination is deep-linkable and on the web, can be navigated
/// to using the address bar.
void main() => runApp(const MyApp());

/// The main app.
class MyApp extends StatelessWidget {
  /// Constructs a [MyApp]
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      /// The route configuration.
      routerConfig: GoRouter(
        routes: <RouteBase>[
          // expect_lint: missing_go_route_name_property
          GoRoute(
            // expect_lint: avoid_hardcoded_routes
            path: '/',
            builder: (BuildContext context, GoRouterState state) {
              return const HomeScreen();
            },
            routes: <RouteBase>[
              // ! GoRoute definition should include a `name` property. Add a `name` property to this GoRoute.
              // expect_lint: missing_go_route_name_property
              GoRoute(
                // ! Avoid hardcoded route paths. Use constants or enums for routes.
                // ! Use a constant, enum, or a variable instead of a hardcoded string.
                // expect_lint: avoid_hardcoded_routes
                path: 'details',
                builder: (BuildContext context, GoRouterState state) {
                  return const DetailsScreen();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The home screen
class HomeScreen extends StatelessWidget {
  /// Constructs a [HomeScreen]
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: ElevatedButton(
          // ! Use context.push instead of GoRouter.of(context).push.
          // expect_lint: use_context_directly_for_go_router
          onPressed: () => GoRouter.of(context).push('/details'),
          child: const Text('Go to the Details screen'),
        ),
      ),
    );
  }
}

/// The details screen
class DetailsScreen extends StatelessWidget {
  /// Constructs a [DetailsScreen]
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details Screen')),
      body: Center(
        child: ElevatedButton(
          // ! Use context.go instead of GoRouter.of(context).go.
          // expect_lint: use_context_directly_for_go_router
          onPressed: () => GoRouter.of(context).go('/'),
          child: const Text('Go back to the Home screen'),
        ),
      ),
    );
  }
}
