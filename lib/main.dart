import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


final deckProvider = NotifierProvider<DeckNotifier, List<WordPair>>(() {
  return DeckNotifier();
});

class DeckNotifier extends Notifier<List<WordPair>> {
  @override
  List<WordPair> build() {
    // Generate initial batch of 10 words
    return List.generate(10, (_) => WordPair.random());
  }

  void removeTopCard() {
    // Remove the first item and add a new one to the end
    state = [
      ...state.sublist(1),
      WordPair.random(),
    ];
  }
}

final currentWordProvider = NotifierProvider<CurrentWordNotifier, WordPair>(
  () => CurrentWordNotifier(),
);

class CurrentWordNotifier extends Notifier<WordPair> {
  @override
  WordPair build() => WordPair.random();

  void nextWord() {
    state = WordPair.random();
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<WordPair>>(
  () {
    return FavoritesNotifier();
  },
);

class FavoritesNotifier extends Notifier<List<WordPair>> {
  late Box box;

  @override
  List<WordPair> build() {
    box = Hive.box('favorites');
    final stored = box.keys.map((key) {
      final str = key as String;
      final parts = str.split('|');
      return WordPair(parts[0], parts[1]);
    }).toList();
    return stored;
  }

  void toggleFavorite(WordPair current) {
    final key = "${current.first}|${current.second}";
    if (state.contains(current)) {
      box.delete(key);
      state = state.where((p) => p != current).toList();
    } else {
      box.put(key, true);
      state = [...state, current];
    }
  }

  void removeFavorite(WordPair pair) {
    final key = "${pair.first}|${pair.second}";
    box.delete(key);
    state = state.where((p) => p != pair).toList();
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
  await Hive.initFlutter();
  await Hive.openBox('favorites');
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
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
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Namer App'),
              actions: [ThemeSelector()],
            ),
            body: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
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
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Namer App'),
              actions: [ThemeSelector()],
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
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: page,
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

class GeneratorPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWordPair = ref.watch(currentWordProvider);
    final favorites = ref.watch(favoritesProvider);

    IconData icon;
    if (favorites.contains(currentWordPair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: SwipePage()),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(currentWordPair);
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  ref.read(currentWordProvider.notifier).nextWord();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final WordPair pair;

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
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
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
        for (var pair in favorites)
          Dismissible(
            key: Key(pair.asLowerCase),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              ref.read(favoritesProvider.notifier).removeFavorite(pair);
            },
            child: ListTile(
              leading: Icon(Icons.favorite),
              title: Text(pair.asLowerCase),
            ),
          ),
      ],
    );
  }
}

class ThemeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return PopupMenuButton<ThemeMode>(
      initialValue: themeMode,
      onSelected: (ThemeMode mode) {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: ThemeMode.system, child: Text('System')),
        PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
        PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
      ],
      icon: Icon(
        themeMode == ThemeMode.light
            ? Icons.light_mode
            : themeMode == ThemeMode.dark
                ? Icons.dark_mode
                : Icons.settings_brightness,
      ),
    );
  }
}



class SwipePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckProvider);

    return Center(
      child: SizedBox(
        height: 400, // Constrain the height
        child: CardSwiper(
          cardsCount: deck.length,
          numberOfCardsDisplayed: 2, // Shows the stack effect

          // 1. Build the cards
          cardBuilder: (context, index, horizontalOffset, verticalOffset) {
            return BigCard(pair: deck[index]);
          },

          // 2. Handle Swipes
          onSwipe: (previousIndex, currentIndex, direction) {
            final swipedPair = deck[previousIndex];

            if (direction == CardSwiperDirection.right) {
              ref.read(favoritesProvider.notifier).toggleFavorite(swipedPair);
            }

            // Remove the card from our state to keep the lists synced
            ref.read(deckProvider.notifier).removeTopCard();
            return true;
          },
        ),
      ),
    );
  }
}