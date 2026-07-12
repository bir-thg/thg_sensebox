import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// 1. Ein kleines Datenmodell für unsere Messpunkte
class Measurement {
  final DateTime time;
  final double value;
  Measurement(this.time, this.value);
}

// 2. Das StatefulWidget für unsere aufklappbare Karte
class SensorHistoryCard extends StatefulWidget {
  final String boxId;
  final String sensorId;
  final String title;
  final String currentValue;
  final String unit;
  final IconData icon;

  const SensorHistoryCard({
    Key? key,
    required this.boxId,
    required this.sensorId,
    required this.title,
    required this.currentValue,
    required this.unit,
    required this.icon,
  }) : super(key: key);

  @override
  _SensorHistoryCardState createState() => _SensorHistoryCardState();
}

class _SensorHistoryCardState extends State<SensorHistoryCard> {
  bool _isLoading = false;
  List<Measurement> _dataPoints = [];
  String _selectedPeriod = 'Heute'; // 'Heute', 'Monat', 'Custom'
  DateTimeRange? _customDateRange;

  // 3. Diese Funktion holt die Daten von der OpenSenseMap
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    DateTime toDate = DateTime.now();
    DateTime fromDate;

    // Zeitraum berechnen
    if (_selectedPeriod == 'Heute') {
      fromDate = toDate.subtract(const Duration(hours: 24));
    } else if (_selectedPeriod == 'Monat') {
      fromDate = toDate.subtract(const Duration(days: 30));
    } else if (_selectedPeriod == 'Custom' && _customDateRange != null) {
      fromDate = _customDateRange!.start;
      toDate = _customDateRange!.end.add(const Duration(hours: 23, minutes: 59));
    } else {
      fromDate = toDate.subtract(const Duration(hours: 24));
    }

    // API Aufruf zusammenbauen (UTC Zeitformat ist wichtig für die API!)
    final url = Uri.parse(
        'https://api.opensensemap.org/boxes/${widget.boxId}/data/${widget.sensorId}?from-date=${fromDate.toUtc().toIso8601String()}&to-date=${toDate.toUtc().toIso8601String()}&format=json');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        List<Measurement> points = [];
        
        for (var item in rawData) {
          points.add(Measurement(
            DateTime.parse(item['createdAt']).toLocal(),
            double.parse(item['value'].toString()),
          ));
        }
        
        // fl_chart verlangt zwingend, dass die Daten chronologisch sortiert sind (X-Achse aufsteigend)
        points.sort((a, b) => a.time.compareTo(b.time));

        setState(() {
          _dataPoints = points;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // 4. Den Kalender öffnen
  Future<void> _selectCustomDateRange() async {
    // 1. Startdatum auswählen
    final DateTime? start = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 7)), // Schlägt standardmäßig eine Woche vor
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: 'VON (STARTDATUM)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // Nutzt direkt das passende Blau Deiner App
            colorScheme: const ColorScheme.light(primary: Color(0xFF00427A)),
          ),
          child: child!,
        );
      },
    );

    // Wenn der Nutzer beim ersten Kalender auf "Abbrechen" drückt, beenden
    if (start == null) return; 

    // 2. Enddatum auswählen (poppt sofort nach dem Startdatum auf)
    final DateTime? end = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Schlägt standardmäßig heute vor
      firstDate: start, // Clever: Flutter verhindert automatisch, dass das Enddatum VOR dem Startdatum liegt!
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: 'BIS (ENDDATUM)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00427A)),
          ),
          child: child!,
        );
      },
    );

    // 3. Wenn beide Daten erfolgreich gewählt wurden, laden wir die neuen Graphen
    if (end != null) {
      setState(() {
        _customDateRange = DateTimeRange(start: start, end: end);
        _selectedPeriod = 'Custom';
      });
      _fetchData(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        // Was passiert beim Aufklappen?
        onExpansionChanged: (isExpanded) {
          if (isExpanded && _dataPoints.isEmpty) {
            _fetchData(); // Daten nur beim ersten Aufklappen laden
          }
        },
        leading: Icon(widget.icon, size: 32, color: Colors.blue),
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${widget.currentValue} ${widget.unit}'),
        
        // Was wird beim Aufklappen angezeigt?
        children: [
          // A: Die Buttons zur Zeitraum-Auswahl
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                ActionChip(
                  label: const Text('Letzte 24h'),
                  backgroundColor: _selectedPeriod == 'Heute' ? Colors.blue.shade100 : null,
                  onPressed: () {
                    setState(() => _selectedPeriod = 'Heute');
                    _fetchData();
                  },
                ),
                ActionChip(
                  label: const Text('Letzter Monat'),
                  backgroundColor: _selectedPeriod == 'Monat' ? Colors.blue.shade100 : null,
                  onPressed: () {
                    setState(() => _selectedPeriod = 'Monat');
                    _fetchData();
                  },
                ),
                ActionChip(
                  label: const Text('Zeitraum...'),
                  backgroundColor: _selectedPeriod == 'Custom' ? Colors.blue.shade100 : null,
                  avatar: const Icon(Icons.calendar_month, size: 16),
                  onPressed: _selectCustomDateRange,
                ),
              ],
            ),
          ),
          
          // B: Der Graph oder Ladebalken
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8, bottom: 16, top: 16),
            child: SizedBox(
              height: 250,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _dataPoints.isEmpty 
                  ? const Center(child: Text('Keine Daten für diesen Zeitraum'))
                  : _buildChart(),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Den Graphen mit fl_chart zeichnen
  Widget _buildChart() {
    return LineChart(
      LineChartData(
        // Tooltips (Popups) beim Hovern/Tippen
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                final formattedDate = DateFormat('dd.MM.yy HH:mm').format(date);
                return LineTooltipItem(
                  '$formattedDate\n${spot.y} ${widget.unit}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: false), // Raster im Hintergrund
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // X-Achse (Datum/Uhrzeit) formatieren
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                // Wenn wir nur 24h anzeigen, reicht die Uhrzeit, sonst das Datum
                final text = _selectedPeriod == 'Heute' 
                    ? DateFormat('HH:mm').format(date)
                    : DateFormat('dd.MM.').format(date);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(text, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
        lineBarsData: [
          LineChartBarData(
            // Hier verwandeln wir unsere Measurements in X/Y Koordinaten für den Graphen
            spots: _dataPoints.map((m) {
              return FlSpot(m.time.millisecondsSinceEpoch.toDouble(), m.value);
            }).toList(),
            isCurved: true, // Weiche Linien
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false), // Punkte auf der Linie verbergen (sieht sauberer aus)
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2), // Leichter Schatten unter der Linie
            ),
          ),
        ],
      ),
    );
  }
}