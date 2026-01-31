import 'package:dio/dio.dart';
import '../models/pokemon.dart';

class PokemonService {
  final Dio _dio;

  PokemonService({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<Pokemon>> fetchPokemon({int limit = 20, int offset = 0}) async {
    try {
      final response = await _dio.get(
        'https://pokeapi.co/api/v2/pokemon',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data;
      final results = data['results'] as List;

      return results.map((json) => Pokemon.fromJson(json)).toList();
    } catch (e) {
      // Simple error handling for now. In a real app, we'd want custom exceptions.
      print('Error fetching pokemon: $e');
      throw Exception('Failed to load pokemon');
    }
  }

  Future<Pokemon?> fetchPokemonDetails(String name) async {
    try {
      final response = await _dio.get('https://pokeapi.co/api/v2/pokemon/${name.toLowerCase()}');
      return Pokemon.fromDetailJson(response.data);
    } catch (e) {
      print('Error fetching pokemon details: $e');
      return null;
    }
  }
}
