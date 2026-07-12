import 'dart:convert';
import 'package:http/http.dart' as http;

// 1. Unser Datenmodell: So sieht ein einzelner Sensor-Wert für uns aus
class SensorData {
  final String id; // <-- NEU: Die eindeutige ID des Sensors
  final String title;
  final String value;
  final String unit;

  SensorData({
    required this.id, // <-- NEU
    required this.title,
    required this.value,
    required this.unit,
  });

  // Diese Fabrik-Methode baut aus dem OpenSenseMap-JSON unser Dart-Objekt
  factory SensorData.fromJson(Map<String, dynamic> json) {
    // Falls ein Sensor gerade offline ist und keinen aktuellen Wert hat, fangen wir das ab
    final measurement = json['lastMeasurement'];
    final value = measurement != null ? measurement['value'] : '--';

    return SensorData(
      id: json['_id'].toString(), // <-- NEU: Wir lesen die kryptische ID mit aus
      title: json['title'] ?? 'Unbekannt',
      value: value.toString(),
      unit: json['unit'] ?? '',
    );
  }
}

// 2. Unser API-Dienst: Holt die Daten ab
class SenseBoxApi {
  // Die fetch-Methode verlangt nun zwingend eine Box-ID als Parameter
  static Future<List<SensorData>> fetchSensorData(String boxId) async {
    final String apiUrl = 'https://api.opensensemap.org/boxes/$boxId';
    
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> sensorsJson = jsonData['sensors'];

        return sensorsJson.map((json) => SensorData.fromJson(json)).toList();
      } else {
        throw Exception('Fehler beim Laden der Sensordaten');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }
}