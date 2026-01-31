class Pokemon {
  final String name;
  final String? url;
  final int? explicitId;
  final String? imageUrl;
  final List<Map<String, dynamic>>? stats;
  final List<String>? types;

  Pokemon({
    required this.name,
    this.url,
    this.explicitId,
    this.imageUrl,
    this.stats,
    this.types,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    // Handle both basic API response and full stored data
    List<Map<String, dynamic>>? statsList;
    if (json['stats'] != null) {
      statsList = (json['stats'] as List)
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
    }

    List<String>? typesList;
    if (json['types'] != null) {
      typesList = (json['types'] as List).cast<String>();
    }

    return Pokemon(
      name: json['name'] as String,
      url: json['url'] as String?,
      explicitId: json['id'] as int?,
      imageUrl: json['imageUrl'] as String?,
      stats: statsList,
      types: typesList,
    );
  }

  factory Pokemon.fromDetailJson(Map<String, dynamic> json) {
    final statsList = (json['stats'] as List)
        .map((s) => {
              'name': s['stat']['name'],
              'value': s['base_stat'],
            })
        .toList();

    final typesList = (json['types'] as List)
        .map((t) => t['type']['name'] as String)
        .toList();

    return Pokemon(
      name: json['name'] as String,
      explicitId: json['id'] as int,
      imageUrl: json['sprites']['front_default'] as String?,
      stats: statsList,
      types: typesList,
    );
  }

  // Extract ID from URL for potential future use (e.g., image fetching)
  // URL format: https://pokeapi.co/api/v2/pokemon/1/
  int get id {
    if (explicitId != null) return explicitId!;
    if (url == null) return 0;
    
    final uri = Uri.parse(url!);
    final segments = uri.pathSegments;
    // pathSegments splits by /, so "pokemon/1/" gives ["api", "v2", "pokemon", "1", ""]
    // We want the one before the last empty one, or the last non-empty one.
    return int.parse(segments[segments.length - 2]); 
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'id': explicitId,
      'imageUrl': imageUrl,
      'stats': stats,
      'types': types,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pokemon && other.name == name && other.url == url;
  }

  @override
  int get hashCode => name.hashCode ^ url.hashCode;
}
