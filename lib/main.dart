import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  TextEditingController cityController = TextEditingController();
  String temperature = "Gib eine Stadt ein";
  String selectedCity = "Berlin";
  
  @override
  void initState() {
    super.initState();
    _loadLastWeather();
  }

  Future<void> _loadLastWeather() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      temperature = prefs.getString("lastTemperature") ?? "Gib eine Stadt ein";
      selectedCity = prefs.getString("lastCity") ?? "Berlin";
    });
  }

  Future<void> _saveLastWeather(String temp, String city) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastTemperature", temp);
    await prefs.setString("lastCity", city);
  }

  Future<void> _clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("lastTemperature");
    await prefs.remove("lastCity");
    setState(() {
      temperature = "Gib eine Stadt ein";
      selectedCity = "Berlin";
    });
  }

  List<Map<String, dynamic>> staedte = [
    {"name": "Berlin", "latitude": 52.52, "longitude": 13.405},
    {"name": "Hamburg", "latitude": 53.5511, "longitude": 9.9937},
    {"name": "München", "latitude": 48.1351, "longitude": 11.5820},
    {"name": "Köln", "latitude": 50.9375, "longitude": 6.9603},
    {"name": "Frankfurt am Main", "latitude": 50.1109, "longitude": 8.6821},
  ];

  Future<void> fetchWeather(double latitude, double longitude, String city) async {
    setState(() {
      temperature = "Lade...";
    });
    try {
      String requestUrl =
          "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&hourly=temperature_2m";
      final response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String newTemperature = "${data['hourly']['temperature_2m'][0]}°C";
        setState(() {
          temperature = newTemperature;
        });
        _saveLastWeather(newTemperature, city);
      } else {
        setState(() {
          temperature = "Fehler beim Laden";
        });
      }
    } catch (e) {
      setState(() {
        temperature = "Netzwerkfehler";
      });
    }
  }

  void _onCityChanged(String? newCity) {
    if (newCity != null) {
      setState(() {
        selectedCity = newCity;
      });
      var city = staedte.firstWhere((c) => c['name'] == newCity);
      fetchWeather(city['latitude'], city['longitude'], newCity);
    }
  }

  void searchCity(String cityName) {
    var city = staedte.firstWhere(
      (city) => city['name'].toLowerCase() == cityName.toLowerCase(),
      orElse: () => {"name": "Nicht gefunden", "latitude": 0.0, "longitude": 0.0},
    );

    if (city['name'] != "Nicht gefunden") {
      fetchWeather(city['latitude'], city['longitude'], cityName);
    } else {
      setState(() {
        temperature = "Stadt nicht gefunden";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wetter App"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: "Stadt suchen",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                searchCity(value);
              },
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedCity,
              onChanged: _onCityChanged,
              items: staedte.map<DropdownMenuItem<String>>((city) {
                return DropdownMenuItem<String>(
                  value: city['name'],
                  child: Text(city['name']),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(temperature, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearHistory,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Historie löschen", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}