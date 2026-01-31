import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pokemon.name.toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '#${pokemon.id}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            if (pokemon.imageUrl != null)
              Image.network(
                pokemon.imageUrl!,
                height: 150,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            if (pokemon.types != null && pokemon.types!.isNotEmpty)
              Wrap(
                spacing: 8,
                children: pokemon.types!
                    .map((t) => Chip(
                          label: Text(t.toUpperCase()),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 16),
            if (pokemon.stats != null) ...[
              const Divider(),
              const Text('Stats', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...pokemon.stats!.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          (s['name'] as String).toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: (s['value'] as int) / 200,
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${s['value']}'),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
