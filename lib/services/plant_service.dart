import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/plant_model.dart';

class PlantService {
  static final String _baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:80';
  static final client = Supabase.instance.client;

  // Get authentication token for API requests
  static Future<String?> _getAuthToken() async {
    return client.auth.currentSession?.accessToken;
  }

  static Future<PlantModel> getPlantById(int plantId) async {
    try {
      final response =
          await client
              .from('plants')
              .select('*, watering_history(*), diary_entries(*)')
              .eq('id', plantId)
              .single();
      return PlantModel.fromJson(response);
    } catch (e) {
      log('Error fetching plant: $e');
      throw Exception('Failed to fetch plant details');
    }
  }

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch all plants for current user
  static Future<List<PlantModel>> getUserPlants() async {
    try {
      // First try direct Supabase query
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await client
          .from('plants')
          .select('*, diary_entries(*), watering_history(watered_at)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((plant) => PlantModel.fromJson(plant))
          .toList();
    } catch (e) {
      // If Supabase query fails, try the backend API
      try {
        final headers = await _getHeaders();
        final response = await http.get(
          Uri.parse('$_baseUrl/plants/'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return data.map((plant) => PlantModel.fromJson(plant)).toList();
        } else {
          throw Exception('Failed to load plants: ${response.statusCode}');
        }
      } catch (e) {
        rethrow;
      }
    }
  }

  static Future<PlantModel> createPlant(Map<String, dynamic> plantData) async {
    try {
      // First try with direct Supabase query
      final response =
          await client.from('plants').insert(plantData).select().single();
      return PlantModel.fromJson(response);
    } catch (e) {
      log('Supabase error: $e');
      // If Supabase operation fails, try the backend API
      try {
        final headers = await _getHeaders();

        // Make sure user_id is included (common source of issues)
        if (!plantData.containsKey('user_id')) {
          final userId = client.auth.currentUser?.id;
          if (userId == null) {
            throw Exception('User not logged in');
          }
          plantData['user_id'] = userId;
        }

        final response = await http.post(
          Uri.parse('$_baseUrl/plants/'),
          headers: headers,
          body: json.encode(plantData),
        );

        log('Response status: ${response.statusCode}');
        log('Response body: ${response.body}');

        if (response.statusCode == 201) {
          // API returns success but not the plant object
          final newPlant = Map<String, dynamic>.from(plantData);

          // ALWAYS include a valid integer ID - never set to null
          // Use milliseconds for a unique temporary ID
          newPlant['id'] = DateTime.now().millisecondsSinceEpoch;
          newPlant['created_at'] = DateTime.now().toIso8601String();

          // Only use ID from response if it's not null
          try {
            final responseData = json.decode(response.body);
            if (responseData is Map &&
                responseData.containsKey('id') &&
                responseData['id'] != null) {
              // Check for null!
              newPlant['id'] = responseData['id'];
            }
          } catch (e) {
            log('Error parsing response ID: $e');
            // Keep using our temporary ID
          }

          log('Creating plant model with data: ${json.encode(newPlant)}');
          return PlantModel.fromJson(newPlant);
        } else {
          throw Exception('Failed to create plant: ${response.statusCode}');
        }
      } catch (e) {
        log('API error: $e');
        rethrow;
      }
    }
  }

  // Add watering record for a plant
  static Future<void> waterPlant(int plantId, [DateTime? date]) async {
    final waterDate = date ?? DateTime.now();

    try {
      // Try direct Supabase query first
      await client.from('watering_history').insert({
        'plant_id': plantId,
        'watered_at': waterDate.toIso8601String(),
      });
    } catch (e) {
      // If Supabase operation fails, try the backend API
      try {
        final headers = await _getHeaders();
        final response = await http.post(
          Uri.parse('$_baseUrl/watering/'),
          headers: headers,
          body: json.encode({
            'plant_id': plantId,
            'watered_at': waterDate.toIso8601String(),
          }),
        );

        if (response.statusCode != 201) {
          throw Exception('Failed to record watering: ${response.statusCode}');
        }
      } catch (e) {
        rethrow;
      }
    }
  }

  // Add diary entry for a plant
  static Future<void> addDiaryEntry({
    required int plantId,
    required String note,
    double? height,
    DateTime? date,
  }) async {
    final entryDate = date ?? DateTime.now();

    try {
      // First try with Supabase query
      await client.from('diary_entries').insert({
        'plant_id': plantId,
        'note': note,
        'height': height,
        'date': entryDate.toIso8601String(),
      });
    } catch (e) {
      // If Supabase operation fails, try the backend API
      try {
        final headers = await _getHeaders();
        final response = await http.post(
          Uri.parse('$_baseUrl/diary/'),
          headers: headers,
          body: json.encode({
            'plant_id': plantId,
            'note': note,
            'height': height,
            'date': entryDate.toIso8601String(),
          }),
        );

        if (response.statusCode != 201) {
          throw Exception('Failed to add diary entry: ${response.statusCode}');
        }
      } catch (e) {
        rethrow;
      }
    }
  }
}
