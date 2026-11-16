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
  
  // ৫ ওয়াক্ত নামাজের সময়
  String _fajrTime = "--:--";
  String _dhuhrTime = "--:--";
  String _asrTime = "--:--";
  String _maghribTime = "--:--";
  String _ishaTime = "--:--";

  PrayerTimes? _prayerTimes;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;

  // একই ওয়াক্তে বারবার আজান বাজ যেন না বাজে, সেটি ট্র্যাক করার জন্য
  String? _lastPlayedPrayerKey;

  @override
  void initState() {
    super.initState();
    _loadTasbihCount();
    _determinePositionAndCalculateTimes();

    // প্রতি ৩০ সেকেন্ড পর পর সময় চেক করবে এবং ওয়াক্ত মিলে গেলে স্বয়ংক্রিয়ভাবে আজান বাজাবে
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAndPlayAutoAthan();
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
        _locationStatus = "GPS Location Active (Auto Athan Enabled)";
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

  // অটোমেটিক ওয়াক্ত চেক এবং আজান বাজানোর লজিক
  void _checkAndPlayAutoAthan() {
    if (_prayerTimes == null) return;

    final now = DateTime.now();
    
    // ৫ ওয়াক্তের সঠিক সময় চেক করা
    final fajrLocal = _prayerTimes!.fajr.toLocal();
    final dhuhrLocal = _prayerTimes!.dhuhr.toLocal();
    final asrLocal = _prayerTimes!.asr.toLocal();
    final maghribLocal = _prayerTimes!.maghrib.toLocal();
    final ishaLocal = _prayerTimes!.isha.toLocal();

    String todayKey = "${now.year}-${now.month}-${now.day}";

    if (_isSameMinute(now, fajrLocal) && _lastPlayedPrayerKey != "$todayKey-Fajr") {
      _lastPlayedPrayerKey = "$todayKey-Fajr";
      _playAthanAudio("Fajr Athan Time!");
    } else if (_isSameMinute(now, dhuhrLocal) && _lastPlayedPrayerKey != "$todayKey-Dhuhr") {
      _lastPlayedPrayerKey = "$todayKey-Dhuhr";
      _playAthanAudio("Dhuhr Athan Time!");
    } else if (_isSameMinute(now, asrLocal) && _lastPlayedPrayerKey != "$todayKey-Asr") {
      _lastPlayedPrayerKey = "$todayKey-Asr";
      _playAthanAudio("Asr Athan Time!");
    } else if (_isSameMinute(now, maghribLocal) && _lastPlayedPrayerKey != "$todayKey-Maghrib") {
      _lastPlayedPrayerKey = "$todayKey-Maghrib";
      _playAthanAudio("Maghrib Athan Time!");
    } else if (_isSameMinute(now, ishaLocal) && _lastPlayedPrayerKey != "$todayKey-Isha") {
      _lastPlayedPrayerKey = "$todayKey-Isha";
      _playAthanAudio("Isha Athan Time!");
    }
  }

  bool _isSameMinute(DateTime t1, DateTime t2) {
    return t1.year == t2.year &&
        t1.month == t2.month &&
        t1.day == t2.day &&
        t1.hour == t2.hour &&
        t1.minute == t2.minute;
  }

  Future<void> _playAthanAudio(String message) async {
    const audioUrl = "https://islamicfinder.org/audio/athan/makkah_adhan.mp3";
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 5), backgroundColor: Colors.teal),
        );
      }
    } catch (e) {
      // হ্যান্ডলিং এরর যদি ইন্টারনেট বা অডিও সোর্সে সমস্যা হয়
    }
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
            // ইনফো কার্ড
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌍 5 Daily Prayer Times (Auto Athan)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 8),
                    Text(_locationStatus, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    const Text(
                      'ℹ️ Keep app open in browser for automatic Athan.',
                      style: TextStyle(fontSize: 11, color: Colors.indigo, fontStyle: FontStyle.italic),
                    ),
                    const Divider(height: 20),
                    _buildClickablePrayerRow('🌅 Fajr (Sehri Ends)', _fajrTime, Colors.indigo),
                    const Divider(),
                    _buildClickablePrayerRow('☀️ Dhuhr', _dhuhrTime, Colors.teal),
                    const Divider(),
                    _buildClickablePrayerRow(' عصر Asr', _asrTime, Colors.brown),
                    const Divider(),
                    _buildClickablePrayerRow('🌇 Maghrib (Iftar)', _maghribTime, Colors.deepOrange),
                    const Divider(),
                    _buildClickablePrayerRow('🌙 Isha', _ishaTime, Colors.deepPurple),
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

            // ম্যানুয়াল টেস্ট বাটন
            ElevatedButton.icon(
              onPressed: () => _playAthanAudio("Playing Test Athan Audio..."),
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

  Widget _buildClickablePrayerRow(String title, String time, Color color) {
    return InkWell(
      onTap: () {
        _playAthanAudio("Playing Athan for $title");
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.volume_up_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            Text(time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}