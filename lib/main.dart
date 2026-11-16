
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
      title: 'Islamic App',
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
  // Tasbih Variables
  int _tasbihCount = 0;

  // Prayer Times Variables
  String _locationStatus = "লোকেশন লোড হচ্ছে...";
  String _fajrTime = "--:--";
  String _maghribTime = "--:--";

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadTasbihCount();
    _determinePositionAndCalculateTimes();
  }

  // Local Storage থেকে তাসবিহ কাউন্ট লোড করা
  Future<void> _loadTasbihCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasbihCount = prefs.getInt('tasbih_count') ?? 0;
    });
  }

  // তাসবিহ কাউন্ট সেভ এবং বাড়ানো
  Future<void> _incrementTasbih() async {
    setState(() {
      _tasbihCount++;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', _tasbihCount);
  }

  // তাসবিহ রিসেট করা
  Future<void> _resetTasbih() async {
    setState(() {
      _tasbihCount = 0;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', 0);
  }

  // জিপিএস লোকেশন ও নামাজের সময় বের করার ফাংশন
  Future<void> _determinePositionAndCalculateTimes() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = "দয়া করে জিপিএস লোকেশন অন করুন।";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationStatus = "লোকেশন পারমিশন দেওয়া হয়নি।";
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Adhan প্যাক দিয়ে নামাজের সময় হিসাব করা
      final myCoordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;
      
      // আজকের তারিখ
      final date = DateComponents.from(DateTime.now());
      final prayerTimes = PrayerTimes(myCoordinates, date, params);

      setState(() {
        _locationStatus = "সঠিক লোকেশন পাওয়া গেছে (Lat: ${position.latitude.toStringAsFixed(2)}, Lon: ${position.longitude.toStringAsFixed(2)})";
        _fajrTime = _formatTime(prayerTimes.fajr);
        _maghribTime = _formatTime(prayerTimes.maghrib);
      });
    } catch (e) {
      setState(() {
        _locationStatus = "লোকেশন পেতে সমস্যা হয়েছে: $e";
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final hour = localTime.hour > 12 ? localTime.hour - 12 : localTime.hour;
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  // আজান বা অডিও টেস্ট করার ফাংশন
  Future<void> _playTestAthan() async {
    const audioUrl = "https://islamicfinder.org/audio/athan/makkah_adhan.mp3";
    await _audioPlayer.play(UrlSource(audioUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ইসলামিক লাইফ অ্যাপ'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ১. লোকেশন ও নামাজের সময় কার্ড
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌍 আন্তর্জাতিক নামাজের ও সেহরি/ইফতার সময়',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 8),
                    Text(_locationStatus, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🌅 সেহরি শেষ (ফজর):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Text(_fajrTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🌇 ইফতার শুরু (মাগরিব):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Text(_maghribTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ২. ডিজিটাল তাসবিহ সেকশন
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      '📿 ডিজিটাল তাসবিহ কাউন্টার',
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
                          label: const Text('গণনা করুন', style: TextStyle(fontSize: 16)),
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
                          tooltip: 'রিসেট করুন',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ৩. আজান অডিও টেস্ট বাটন
            ElevatedButton.icon(
              onPressed: _playTestAthan,
              icon: const Icon(Icons.volume_up),
              label: const Text('আজানের অডিও টেস্ট করুন', style: TextStyle(fontSize: 16)),
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
}