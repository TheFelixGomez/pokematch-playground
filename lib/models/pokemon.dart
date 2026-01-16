class Pokemon {
  final String name;
  final String url;

  Pokemon({required this.name, required this.url});

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }

  // Extract ID from URL for potential future use (e.g., image fetching)
  // URL format: https://pokeapi.co/api/v2/pokemon/1/
  int get id {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    // pathSegments splits by /, so "pokemon/1/" gives ["api", "v2", "pokemon", "1", ""]
    // We want the one before the last empty one, or the last non-empty one.
    return int.parse(segments[segments.length - 2]); 
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pokemon && other.name == name && other.url == url;
  }

  @override
  int get hashCode => name.hashCode ^ url.hashCode;
}
