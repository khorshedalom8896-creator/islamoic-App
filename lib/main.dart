import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IslamoicApp());
}

class IslamoicApp extends StatelessWidget {
  const IslamoicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Islamoic App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
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
  // ভেরিয়েবলসমূহ
  String _locationStatus = "লোকেশন খোঁজা হচ্ছে...";
  PrayerTimes? _prayerTimes;
  int _tasbihCount = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _determinePositionAndCalculatePrayerTimes();
  }

  // ১. জিপিএস লোকেশন বের করে নামাজের সময় ক্যালকুলেট করা
  Future<void> _determinePositionAndCalculatePrayerTimes() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = "দয়া করে ফোনের জিপিএস (Location) অন করুন।";
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

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationStatus = "লোকেশন পারমিশন স্থায়ীভাবে বন্ধ রয়েছে। সেটিংস থেকে অন করুন।";
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // অ্যাডান (Adhan) প্যাকেজ দিয়ে নামাজের সময় হিসাব করা
      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.hanafi;
      
      final date = DateComponents.from(DateTime.now());
      final prayerTimes = PrayerTimes(coordinates, date, params);

      setState(() {
        _prayerTimes = prayerTimes;
        _locationStatus = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
      });
    } catch (e) {
      setState(() {
        _locationStatus = "লোকেশন পেতে সমস্যা হয়েছে: $e";
      });
    }
  }

  // ২. আজানের অডিও টেস্ট করার ফাংশন
  Future<void> _playTestAthan() async {
    try {
      // অনলাইন সোর্স থেকে অডিও বাজানোর টেস্ট (অথবা লোকাল ফাইল)
      await _audioPlayer.play(UrlSource('https://islamic-audio.org/athan.mp3'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("আজানের অডিও প্লে করা হচ্ছে...")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("অডিও প্লে করতে সমস্যা হয়েছে: $e")),
      );
    }
  }

  // ৩. তাসবিহ কাউন্টার বাড়ানোর ফাংশন
  void _incrementTasbih() {
    setState(() {
      _tasbihCount++;
    });
  }

  // ৪. তাসবিহ রিসেট করার ফাংশন
  void _resetTasbih() {
    setState(() {
      _tasbihCount = 0;
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "--:--";
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ইসলামিক অ্যাপ & আজান', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // লোকেশন স্ট্যাটাস কার্ড
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.location_on, color: Colors.teal, size: 36),
                    const SizedBox(height: 8),
                    const Text("বর্তমান জিপিএস লোকেশন", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_locationStatus, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _determinePositionAndCalculatePrayerTimes,
                      icon: const Icon(Icons.refresh),
                      label: const Text("লোকেশন ও সময় আপডেট করুন"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // নামাজের সময়সূচি সেকশন
            const Text("আজকের ৫ ওয়াক্ত নামাজের সময়", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildPrayerRow("ফজর (Fajr)", _formatTime(_prayerTimes?.fajr)),
                    const Divider(),
                    _buildPrayerRow("যোহর (Dhuhr)", _formatTime(_prayerTimes?.dhuhr)),
                    const Divider(),
                    _buildPrayerRow("আসর (Asr)", _formatTime(_prayerTimes?.asr)),
                    const Divider(),
                    _buildPrayerRow("মাগরিব (Maghrib)", _formatTime(_prayerTimes?.maghrib)),
                    const Divider(),
                    _buildPrayerRow("এশা (Isha)", _formatTime(_prayerTimes?.isha)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // টেস্ট আজান অডিও বাটন
            ElevatedButton.icon(
              onPressed: _playTestAthan,
              icon: const Icon(Icons.volume_up),
              label: const Text("Test Athan Audio Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // ডিজিটাল তাসবিহ কাউন্টার সেকশন
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text("ডিজিটাল তাসবিহ কাউন্টার", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
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
      row: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(prayerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(prayerTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }
}