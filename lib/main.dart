import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart'; // Unsere API-Datei aus Schritt 3

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
  // Dieses Future hält unsere Sensordaten
  late Future<List<SensorData>> futureSensorData;

  @override
  void initState() {
    super.initState();
    // Beim Start der App die Daten abrufen
    futureSensorData = SenseBoxApi.fetchSensorData();
  }

  // Methode für "Pull-to-Refresh" (Wischen nach unten zum Aktualisieren)
  Future<void> _refreshData() async {
    setState(() {
      futureSensorData = SenseBoxApi.fetchSensorData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('THG SenseBox Live'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        // Der FutureBuilder kümmert sich um das Warten auf die API
        child: FutureBuilder<List<SensorData>>(
          future: futureSensorData,
          builder: (context, snapshot) {
            // Lade-Animation anzeigen, solange Daten geholt werden
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } 
            // Fehlermeldung, falls was schiefgeht
            else if (snapshot.hasError) {
              return Center(child: Text('Fehler: ${snapshot.error}'));
            } 
            // Meldung, falls keine Daten kommen
            else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Keine Sensordaten gefunden.'));
            }

            final sensors = snapshot.data!;

            // Die Liste der Sensoren bauen
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                return _buildSensorCard(sensor);
              },
            );
          },
        ),
      ),
    );
  }

// Diese Methode sucht anhand des Namens das passende Icon heraus
  IconData _getIconForSensor(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('temperatur')) return Icons.thermostat;
    if (lowerTitle.contains('luftfeuchte')) return Icons.water_drop;
    if (lowerTitle.contains('luftdruck')) return Icons.speed; // oder Icons.compress
    if (lowerTitle.contains('beleuchtung')) return Icons.light_mode;
    if (lowerTitle.contains('uv')) return Icons.brightness_high;
    if (lowerTitle.contains('pm')) return Icons.air; // Für alle Feinstaub-Werte (PM1, PM2.5, PM10)
    
    return Icons.sensors; // Standard-Icon, falls ein Name nicht erkannt wird
  }

  // Unser Widget für eine einzelne, moderne Sensordaten-Karte
  Widget _buildSensorCard(SensorData sensor) {
    final iconData = _getIconForSensor(sensor.title);

    return Card(
      elevation: 0, 
      // 1. ÄNDERUNG: Abstand nach unten von 12 auf 6 reduziert
      margin: const EdgeInsets.only(bottom: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Minimal kleinerer Radius
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        // 2. ÄNDERUNG: Innerer Abstand oben/unten von 16 auf 8 reduziert
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            Container(
              // 3. ÄNDERUNG: Icon-Hintergrundbox etwas schmaler (8 statt 10)
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // 4. ÄNDERUNG: Die Warnung ist weg! withAlpha(20) entspricht 8% Deckkraft
                color: const Color(0xFF00427A).withAlpha(20), 
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                color: const Color(0xFF00427A), 
                size: 22, // Icon-Größe von 26 auf 22 reduziert
              ),
            ),
            const SizedBox(width: 12), // Abstand zum Text etwas verkleinert
            
            Expanded(
              child: Text(
                sensor.title,
                style: const TextStyle(
                  fontSize: 14, // Schriftgröße Titel von 16 auf 14 reduziert
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00427A), 
                ),
              ),
            ),
            
            Text(
              '${sensor.value} ${sensor.unit}',
              style: const TextStyle(
                fontSize: 15, // Schriftgröße Wert von 18 auf 15 reduziert
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}