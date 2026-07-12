import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- 1. NEUER IMPORT

import 'api_service.dart'; // Unsere API-Datei aus Schritt 3
import 'sensor_history_card.dart'; // <-- NEU: Unsere Graphen-Karte

void main() {
  runApp(const ThgSenseBoxApp());
}

class ThgSenseBoxApp extends StatelessWidget {
  const ThgSenseBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Das THG-Blau als Konstante
    const primaryColor = Color(0xFF00427A);

    return MaterialApp(
      title: 'THG Umweltdaten',
      debugShowCheckedModeBanner: false, // Entfernt das "Debug"-Banner oben rechts

// --- 2. HIER KOMMT DIE SPRACH-KONFIGURATION REIN ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'), // Deutsch als unterstützte Sprache festlegen
      ],
      // ----------------------------------------------------
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        // Open Sans global für alle Texte festlegen
        textTheme: GoogleFonts.openSansTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white, // Weißer Text in der Kopfzeile
        ),
      ),
      home: const SenseBoxScreen(),
    );
  }
}

class SenseBoxScreen extends StatefulWidget {
  const SenseBoxScreen({super.key});

  @override
  State<SenseBoxScreen> createState() => _SenseBoxScreenState();
}

class _SenseBoxScreenState extends State<SenseBoxScreen> {
  late Future<List<SensorData>> futureSensorData;

  // 1. Unsere Boxen (Hier trägst Du den Namen und die IDs ein)
  final Map<String, String> myBoxes = {
    'THG Aussenstelle': '69bd6ceb867a8a00078d3c3f',
    'THG Garten': '69bd6c10867a8a00078bedbb', // <-- Hier die neue ID einfügen!
  };

  // 2. Die aktuell ausgewählte Box
  late String selectedBoxId;

  @override
  void initState() {
    super.initState();
    // Beim ersten Start nehmen wir einfach die erste Box aus der Liste
    selectedBoxId = myBoxes.values.first;
    _loadData();
  }

  // 3. Eine kleine Hilfsmethode, um das Laden manuell anzustoßen
  void _loadData() {
    setState(() {
      futureSensorData = SenseBoxApi.fetchSensorData(selectedBoxId);
    });
  }

  // Diese Methode baut das richtige Icon für die Karte (Bleibt unverändert!)
  IconData _getIconForSensor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('temperatur')) return Icons.thermostat;
    if (lowerTitle.contains('luftfeuchtigkeit') || lowerTitle.contains('rel. luftfeuchte')) return Icons.water_drop;
    if (lowerTitle.contains('luftdruck')) return Icons.speed;
    if (lowerTitle.contains('beleuchtungsstärke') || lowerTitle.contains('helligkeit')) return Icons.light_mode;
    if (lowerTitle.contains('uv')) return Icons.wb_sunny;
    if (lowerTitle.contains('feinstaub') || lowerTitle.contains('pm10') || lowerTitle.contains('pm2.5')) return Icons.cloud;
    return Icons.sensors;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THG Umweltdaten'),
        actions: [
          // 4. Das Dropdown-Menü oben rechts in der Leiste
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: selectedBoxId,
              dropdownColor: Theme.of(context).primaryColor, // Dropdown im passenden Blau
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              underline: const SizedBox(), // Versteckt die Standard-Linie unter dem Dropdown
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != selectedBoxId) {
                  // Wenn eine neue Box gewählt wurde: ID aktualisieren und Daten neu laden
                  selectedBoxId = newValue;
                  _loadData();
                }
              },
              // Baut aus unserer Liste (myBoxes) die auswählbaren Elemente
              items: myBoxes.entries.map<DropdownMenuItem<String>>((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<SensorData>>(
        future: futureSensorData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Fehler beim Laden: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          } else if (snapshot.hasData) {
            final sensors = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                return SensorHistoryCard(
                  boxId: selectedBoxId, // <-- 5. WICHTIG: Hier reichen wir die Variable durch!
                  sensorId: sensor.id,
                  title: sensor.title,
                  currentValue: sensor.value,
                  unit: sensor.unit,
                  icon: _getIconForSensor(sensor.title),
                );
              },
            );
          }
          return const Center(child: Text('Keine Daten verfügbar.'));
        },
      ),
    );
  }
}