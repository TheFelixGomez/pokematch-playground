import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'router.dart';
import 'models/pokemon.dart';
import 'services/pokemon_service.dart';
import 'widgets/pokemon_card.dart';

// Service Provider
final pokemonServiceProvider = Provider((ref) => PokemonService());

// Pokemon List Notifier (Replaces DeckNotifier)
final pokemonListProvider = AsyncNotifierProvider<PokemonListNotifier, List<Pokemon>>(() {
  return PokemonListNotifier();
});

class PokemonListNotifier extends AsyncNotifier<List<Pokemon>> {
  int _offset = 0;
  final int _limit = 20;

  @override
  Future<List<Pokemon>> build() async {
    _offset = 0;
    return _fetch();
  }

  Future<List<Pokemon>> _fetch() async {
    final service = ref.read(pokemonServiceProvider);
    final basicList = await service.fetchPokemon(offset: _offset, limit: _limit);
    
    // Fetch full details for each Pokemon
    final detailedList = await Future.wait(
      basicList.map((p) => service.fetchPokemonDetails(p.name)),
    );
    
    // Filter out nulls (failed fetches)
    return detailedList.whereType<Pokemon>().toList();
  }

  Future<void> loadMore() async {
    // Avoid loading if already loading
    if (state.isLoading) return;

    final currentList = state.value ?? [];
    _offset += _limit;
    
    // We want to keep displaying the current list while loading more
    // So we don't set state to loading directly effectively clearing the screen
    // Instead we just append when done.
    // However, AsyncNotifier handles this gracefully if we handle it right.
    
    try {
      final newItems = await _fetch();
      state = AsyncValue.data([...currentList, ...newItems]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void removeTopPokemon() {
    final currentList = state.value;
    if (currentList != null && currentList.isNotEmpty) {
      final newList = currentList.sublist(1);
      state = AsyncValue.data(newList);

      // Prefetch when running low
      if (newList.length < 5) {
        loadMore();
      }
    }
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Pokemon>>(
  () {
    return FavoritesNotifier();
  },
);

class FavoritesNotifier extends Notifier<List<Pokemon>> {
  late Box _box;

  @override
  List<Pokemon> build() {
    _box = Hive.box('favorites');
    // Using values since we will store the Map
    final stored = _box.values.map((e) {
      try {
        if (e is Map) {
             return Pokemon.fromJson(Map<String, dynamic>.from(e));
        }
        // Fallback or ignore invalid data from previous versions (WordPair)
        return null;
      } catch (_) {
        return null;
      }
    }).whereType<Pokemon>().toList();
    
    return stored;
  }

  void toggleFavorite(Pokemon current) {
    if (state.contains(current)) {
      removeFavorite(current);
    } else {
      addFavorite(current);
    }
  }
  
  void addFavorite(Pokemon p) {
    if (!state.contains(p)) {
      _box.put(p.name, p.toJson());
      state = [...state, p];
    }
  }

  void removeFavorite(Pokemon p) {
    _box.delete(p.name);
    state = state.where((item) => item != p).toList();
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  () => ThemeModeNotifier(),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeModeKey);
    if (themeName != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('favorites');
  
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions(); 

  runApp(ProviderScope(child: MyApp()));
}

final swiperControllerProvider = Provider.autoDispose((ref) => AppinioSwiperController());

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Namer App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class GeneratorPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemonListAsync = ref.watch(pokemonListProvider);
    final favorites = ref.watch(favoritesProvider);

    return pokemonListAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (pokemonList) {
        if (pokemonList.isEmpty) {
             return Center(child: Text('No Pokemon found!'));
        }
        
        // We consider the first one as "Current" for the buttons below, 
        // effectively syncing with the top card of the swiper.
        final currentPokemon = pokemonList.first;
        final controller = ref.watch(swiperControllerProvider);

        IconData icon;
        if (favorites.contains(currentPokemon)) {
          icon = Icons.favorite;
        } else {
          icon = Icons.favorite_border;
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(child: SwipePage(pokemonList: pokemonList)),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}



class SwipePage extends ConsumerWidget {
  final List<Pokemon> pokemonList;
  
  const SwipePage({Key? key, required this.pokemonList}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(swiperControllerProvider);

    return AppinioSwiper(
      key: ValueKey(pokemonList.first.name),
      controller: controller,
      backgroundCardCount: 1,
      backgroundCardScale: 1.0,
      backgroundCardOffset: Offset.zero,
      cardCount: pokemonList.length,
      cardBuilder: (BuildContext context, int index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                PokemonCard(pokemon: pokemonList[index]),
                SwipeFeedback(controller: controller, index: index),
              ],
            );
          },
      onSwipeEnd: (int previousIndex, int targetIndex, SwiperActivity activity) {
        final swipedPokemon = pokemonList[previousIndex];

        if (activity.direction == AxisDirection.right) {
          ref.read(favoritesProvider.notifier).addFavorite(swipedPokemon);
        }

        // Remove the card from our state to keep the lists synced
        ref.read(pokemonListProvider.notifier).removeTopPokemon();
      },
    );
  }
}

class SwipeFeedback extends StatelessWidget {
  final AppinioSwiperController controller;
  final int index;

  const SwipeFeedback({
    super.key,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final position = controller.position;
        // Only show feedback for the top card being swiped
        if (position == null || controller.cardIndex != index) {
          return const SizedBox.shrink();
        }

        final offset = position.offset;
        // Simple threshold for opacity (e.g. 100 pixels)
        final double opacity = (offset.dx.abs() / 100).clamp(0.0, 1.0);

        if (offset.dx > 0) {
          // Swipe Right - Like
          return Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20), // Match card radius if possible
                ),
                child: const Center(
                  child: Icon(
                    Icons.favorite,
                    color: Colors.green,
                    size: 100,
                  ),
                ),
              ),
            ),
          );
        } else if (offset.dx < 0) {
          // Swipe Left - Discard
          return Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                   color: Colors.red.withOpacity(0.2),
                   borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 100,
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}