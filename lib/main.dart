import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'router.dart';
import 'models/pokemon.dart';
import 'services/pokemon_service.dart';

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
    return service.fetchPokemon(offset: _offset, limit: _limit);
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
      _box.put(p.name, {'name': p.name, 'url': p.url});
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
          seedColor: Colors.deepPurple,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(currentPokemon);
                    },
                    icon: Icon(icon),
                    label: Text('Like'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                        // "Next" just removes the top card, effectively swiping
                        ref.read(pokemonListProvider.notifier).removeTopPokemon();
                    },
                    child: Text('Next'),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      elevation: 8.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pokemon.name,
          style: style,
          semanticsLabel: pokemon.name,
        ),
      ),
    );
  }
}

class FavoritesPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    if (favorites.isEmpty) {
      return Center(child: Text('No favorites yet.'));
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'You have ${favorites.length} favorites:',
          ),
        ),
        for (var p in favorites)
          Dismissible(
            key: Key(p.name),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              ref.read(favoritesProvider.notifier).removeFavorite(p);
            },
            child: ListTile(
              leading: Icon(Icons.favorite),
              title: Text(p.name),
            ),
          ),
      ],
    );
  }
}

class SwipePage extends ConsumerWidget {
  final List<Pokemon> pokemonList;
  
  const SwipePage({Key? key, required this.pokemonList}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // pokemonList is passed from parent to avoid async issues here?
    // Actually, CardSwiper needs the count.
    
    return SizedBox(
        height: 400, // Constrain the height
        child: CardSwiper(
          cardsCount: pokemonList.length,
          numberOfCardsDisplayed: 2, // Shows the stack effect
          
          // 1. Build the cards
          cardBuilder: (context, index, horizontalOffset, verticalOffset) {
             // Safety check
             if (index >= pokemonList.length) return SizedBox();
             return BigCard(pokemon: pokemonList[index]);
          },

          // 2. Handle Swipes
          onSwipe: (previousIndex, currentIndex, direction) {
            final swipedPokemon = pokemonList[previousIndex];

            if (direction == CardSwiperDirection.right) {
              ref.read(favoritesProvider.notifier).addFavorite(swipedPokemon);
            }

            // Remove the card from our state to keep the lists synced
            // Notes: CardSwiper handles the UI removal animation.
            // We need to update our state so that "Current" (index 0) updates.
            // But we should do it *after* the swipe? 
            // `onSwipe` is called when swipe action is detected/completed?
            // "Returns true if the swipe is allowed".
            // It seems `onSwipe` runs before the animation completes fully?
            // If we remove the item from the list IMMEDIATELY, the CardSwiper might get confused 
            // because the data source changed under its feet while it's animating?
            // Actually `flutter_card_swiper` recommends state updates.
            
            // Let's remove it.
            ref.read(pokemonListProvider.notifier).removeTopPokemon();
            return true;
          },
        ),
    );
  }
}