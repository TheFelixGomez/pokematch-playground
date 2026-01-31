import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'main.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'text_recognition_page.dart';
import 'pages/favorites_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/home', // no place like home
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value ?? false;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => GeneratorPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesPage(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ocr',
                builder: (context, state) => const TextRecognitionPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Pokemon Matching'),
            ),
            body: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: widget.navigationShell,
            ),
            bottomNavigationBar: NavigationBar(
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite),
                  label: 'Favorites',
                ),
                NavigationDestination(
                  icon: Icon(Icons.camera_alt),
                  label: 'OCR',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: (value) {
                widget.navigationShell.goBranch(
                  value,
                  initialLocation: value == widget.navigationShell.currentIndex,
                );
              },
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Pokemon Matching'),
            ),
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite),
                        label: Text('Favorites'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.camera_alt),
                        label: Text('OCR'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings),
                        label: Text('Settings'),
                      ),
                    ],
                    selectedIndex: widget.navigationShell.currentIndex,
                    onDestinationSelected: (value) {
                      widget.navigationShell.goBranch(
                        value,
                        initialLocation: value == widget.navigationShell.currentIndex,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: widget.navigationShell,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
