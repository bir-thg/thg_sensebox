import 'dart:convert';
import 'package:http/http.dart' as http;

// 1. Unser Datenmodell: So sieht ein einzelner Sensor-Wert für uns aus
class SensorData {
  final String title;
  final String value;
  final String unit;

  SensorData({
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
      title: json['title'] ?? 'Unbekannt',
      value: value.toString(),
      unit: json['unit'] ?? '',
    );
  }
}

// 2. Unser API-Dienst: Holt die Daten ab
class SenseBoxApi {
  // Deine spezifische SenseBox-ID vom THG
  static const String boxId = '69bd6ceb867a8a00078d3c3f';
  static const String apiUrl = 'https://api.opensensemap.org/boxes/$boxId';

  static Future<List<SensorData>> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // JSON decodieren
        final jsonData = json.decode(response.body);
        final List<dynamic> sensorsJson = jsonData['sensors'];

        // Aus der JSON-Liste eine Liste von SensorData-Objekten machen
        return sensorsJson.map((json) => SensorData.fromJson(json)).toList();
      } else {
        throw Exception('Fehler beim Laden der Daten (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }
}