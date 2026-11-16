import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Islamic Life App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tasbihCount = 0;
  String _locationStatus = "Loading location...";
  
  // 5 Prayer Times Variables
  String _fajrTime = "--:--";
  String _dhuhrTime = "--:--";
  String _asrTime = "--:--";
  String _maghribTime = "--:--";
  String _ishaTime = "--:--";

  PrayerTimes? _prayerTimes;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTasbihCount();
    _determinePositionAndCalculateTimes();

    // প্রতি ১ মিনিট পর পর চেক করবে নামাজের সময় হয়েছে কিনা
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkPrayerTimeAndPlayAthan();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadTasbihCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasbihCount = prefs.getInt('tasbih_count') ?? 0;
    });
  }

  Future<void> _incrementTasbih() async {
    setState(() {
      _tasbihCount++;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', _tasbihCount);
  }

  Future<void> _resetTasbih() async {
    setState(() {
      _tasbihCount = 0;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', 0);
  }

  Future<void> _determinePositionAndCalculateTimes() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = "Please enable GPS location.";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationStatus = "Location permission denied.";
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final myCoordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;
      
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      _prayerTimes = PrayerTimes(myCoordinates, date, params);

      setState(() {
        _locationStatus = "GPS Location Active (Lat: ${position.latitude.toStringAsFixed(2)}, Lon: ${position.longitude.toStringAsFixed(2)})";
        _fajrTime = _formatTime(_prayerTimes!.fajr);
        _dhuhrTime = _formatTime(_prayerTimes!.dhuhr);
        _asrTime = _formatTime(_prayerTimes!.asr);
        _maghribTime = _formatTime(_prayerTimes!.maghrib);
        _ishaTime = _formatTime(_prayerTimes!.isha);
      });
    } catch (e) {
      setState(() {
        _locationStatus = "Failed to get location or times";
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final hour = localTime.hour > 12 ? localTime.hour - 12 : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  // অটোমেটিক ওয়াক্ত চেক করে আজান বাজানোর ফাংশন
  void _checkPrayerTimeAndPlayAthan() {
    if (_prayerTimes == null) return;

    final now = DateTime.now();
    
    // প্রতিটা ওয়াক্তের আওয়ার ও মিনিট চেক করা
    bool isFajr = now.hour == _prayerTimes!.fajr.toLocal().hour && now.minute == _prayerTimes!.fajr.toLocal().minute;
    bool isDhuhr = now.hour == _prayerTimes!.dhuhr.toLocal().hour && now.minute == _prayerTimes!.dhuhr.toLocal().minute;
    bool isAsr = now.hour == _prayerTimes!.asr.toLocal().hour && now.minute == _prayerTimes!.asr.toLocal().minute;
    bool isMaghrib = now.hour == _prayerTimes!.maghrib.toLocal().hour && now.minute == _prayerTimes!.maghrib.toLocal().minute;
    bool isIsha = now.hour == _prayerTimes!.isha.toLocal().hour && now.minute == _prayerTimes!.isha.toLocal().minute;

    if (isFajr || isDhuhr || isAsr || isMaghrib || isIsha) {
      _playAthanAudio();
    }
  }

  Future<void> _playAthanAudio() async {
    const audioUrl = "https://islamicfinder.org/audio/athan/makkah_adhan.mp3";
    await _audioPlayer.play(UrlSource(audioUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Life App'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ৫ ওয়াক্ত নামাজের সময় কার্ড
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌍 5 Daily Prayer Times (GPS Based)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 8),
                    Text(_locationStatus, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Divider(height: 20),
                    _buildPrayerRow('🌅 Fajr (Sehri Ends):', _fajrTime, Colors.indigo),
                    const SizedBox(height: 8),
                    _buildPrayerRow('☀️ Dhuhr:', _dhuhrTime, Colors.teal),
                    const SizedBox(height: 8),
                    _buildPrayerRow(' عصر Asr:', _asrTime, Colors.brown),
                    const SizedBox(height: 8),
                    _buildPrayerRow('🌇 Maghrib (Iftar):', _maghribTime, Colors.deepOrange),
                    const SizedBox(height: 8),
                    _buildPrayerRow('🌙 Isha:', _ishaTime, Colors.deepPurple),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ডিজিটাল তাসবিহ সেকশন
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      '📿 Digital Tasbih Counter',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$_tasbihCount',
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _incrementTasbih,
                          icon: const Icon(Icons.add),
                          label: const Text('Count', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 15),
                        IconButton(
                          onPressed: _resetTasbih,
                          icon: const Icon(Icons.refresh, color: Colors.red, size: 30),
                          tooltip: 'Reset',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ম্যানুয়াল আজান টেস্ট বাটন
            ElevatedButton.icon(
              onPressed: _playAthanAudio,
              icon: const Icon(Icons.volume_up),
              label: const Text('Test Athan Audio Now', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerRow(String title, String time, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}