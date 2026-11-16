import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Islamic Azan & Prayer Times',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const PrayerHomePage(),
    );
  }
}

class PrayerHomePage extends StatefulWidget {
  const PrayerHomePage({super.key});

  @override
  State<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends State<PrayerHomePage> {
  String _locationStatus = "Detecting location...";
  PrayerTimes? _prayerTimes;
  int _tasbihCount = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timeCheckTimer;
  String _lastPlayedPrayer = "";

  @override
  void initState() {
    super.initState();
    _determinePositionAndCalculatePrayerTimes();

    // প্রতি ১ মিনিট পরপর চেক করবে নামাজের সময় হয়েছে কিনা
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkPrayerTimeAndPlayAzan();
    });
  }

  @override
  void dispose() {
    _timeCheckTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ইউজারের বর্তমান জিপিএস লোকেশন বের করে স্থানীয় সময় অনুযায়ী নামাজের সময় হিসাব করা
  Future<void> _determinePositionAndCalculatePrayerTimes() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = "Please turn on device GPS/Location.";
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

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationStatus = "Location permissions are permanently denied.";
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final coordinates = Coordinates(position.latitude, position.longitude);
      // বিশ্বব্যাপী গ্রহণযোগ্য ক্যালকুলেশন মেথড (Muslim World League)
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.hanafi;

      // ইউজারের লোকাল টাইম অনুযায়ী আজকের তারিখ
      final date = DateComponents.from(DateTime.now());
      final prayerTimes = PrayerTimes(coordinates, date, params);

      setState(() {
        _prayerTimes = prayerTimes;
        _locationStatus = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
      });
    } catch (e) {
      setState(() {
        _locationStatus = "Error getting location: $e";
      });
    }
  }

  // অটোমেটিক ওয়াক্ত মিললে মক্কার আজান বাজানোর লজিক
  void _checkPrayerTimeAndPlayAzan() {
    if (_prayerTimes == null) return;

    final now = DateTime.now();
    final currentTimeFormatted = DateFormat('hh:mm a').format(now);

    final fajr = _formatTime(_prayerTimes?.fajr);
    final dhuhr = _formatTime(_prayerTimes?.dhuhr);
    final asr = _formatTime(_prayerTimes?.asr);
    final maghrib = _formatTime(_prayerTimes?.maghrib);
    final isha = _formatTime(_prayerTimes?.isha);

    String currentPrayerName = "";
    if (currentTimeFormatted == fajr) currentPrayerName = "Fajr";
    else if (currentTimeFormatted == dhuhr) currentPrayerName = "Dhuhr";
    else if (currentTimeFormatted == asr) currentPrayerName = "Asr";
    else if (currentTimeFormatted == maghrib) currentPrayerName = "Maghrib";
    else if (currentTimeFormatted == isha) currentPrayerName = "Isha";

    // একই ওয়াক্তে বারবার যেন বেজে না ওঠে, তাই চেক করা হচ্ছে
    if (currentPrayerName.isNotEmpty && _lastPlayedPrayer != currentPrayerName) {
      _lastPlayedPrayer = currentPrayerName;
      _playMakkahAzan();
    }
  }

  // মক্কার সুন্দর আজানের অডিও লিংক
  Future<void> _playMakkahAzan() async {
    try {
      // নির্ভরযোগ্য মক্কার আজানের অডিও সোর্স
      await _audioPlayer.play(UrlSource('https://www.islamcan.com/audio/adhan/azan1.mp3'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Azan playing automatically for prayer time!")),
      );
    } catch (e) {
      print("Azan play error: $e");
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "--:--";
    return DateFormat('hh:mm a').format(time);
  }

  void _incrementTasbih() {
    setState(() {
      _tasbihCount++;
    });
  }

  void _resetTasbih() {
    setState(() {
      _tasbihCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Prayer & Azan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.location_on, color: Colors.teal, size: 36),
                    const SizedBox(height: 8),
                    const Text("Current GPS Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_locationStatus, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _determinePositionAndCalculatePrayerTimes,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh Location & Times"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Today's Prayer Times", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildPrayerRow("Fajr", _formatTime(_prayerTimes?.fajr)),
                    const Divider(),
                    _buildPrayerRow("Dhuhr", _formatTime(_prayerTimes?.dhuhr)),
                    const Divider(),
                    _buildPrayerRow("Asr", _formatTime(_prayerTimes?.asr)),
                    const Divider(),
                    _buildPrayerRow("Maghrib", _formatTime(_prayerTimes?.maghrib)),
                    const Divider(),
                    _buildPrayerRow("Isha", _formatTime(_prayerTimes?.isha)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _playMakkahAzan,
              icon: const Icon(Icons.volume_up),
              label: const Text("Test Makkah Azan Audio"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text("Digital Tasbih Counter", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 15),
                    Text("$_tasbihCount", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _incrementTasbih,
                          icon: const Icon(Icons.add),
                          label: const Text("Count (+1)"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton.icon(
                          onPressed: _resetTasbih,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Reset"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerRow(String prayerName, String prayerTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(prayerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(prayerTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }
}