
import 'package:flutter/material.dart';

void main() {
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Islamic Assistant',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
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
  // ব্যবহারকারীর নাম (আপনার চাহিদা অনুযায়ী নাম ধরে ডাকবে)
  final String userName = "খোরশেদ"; 
  
  // একটি ডেমো ভয়েস অ্যালার্ট ফাংশন (নাম ধরে ডাকবে)
  void triggerVoiceAlert(String prayerName) {
    String alertMessage = "আসসালামু আলাইকুম $userName ভাই, এখন $prayerName নামাজের সময় হয়েছে। দয়া করে নামাজ আদায় করুন।";
    // ব্রাউজারে বা ডিভাইসে ভয়েস সিমুলেশন দেখানোর জন্য
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🔊 ভয়েস অ্যালার্ট: \"$alertMessage\""),
        backgroundColor: Colors.teal[800],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ইসলামিক জীবনসাথী ($userName)'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // রোজা ও সেহরি কাউন্টডাউন কার্ড
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF004D40)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌙 রমজান ও রোজা কাউন্টডাউন',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('সেহরির শেষ সময়', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          Text('০৪:১৫ AM', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ইফতারের সময়', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          Text('০৬:৩০ PM', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // নামাজের সময়সূচী সেকশন টাইটেল
            const Text(
              'আজকের নামাজের সময়সূচী',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // নামাজের লিস্ট কার্ডগুলো
            _buildPrayerCard('ফজর', '০৪:৩০ AM', Icons.wb_twilight),
            _buildPrayerCard('যোহর', '০১:১৫ PM', Icons.wb_sunny),
            _buildPrayerCard('আসর', '০৪:৪৫ PM', Icons.wb_cloudy),
            _buildPrayerCard('মাগরিব', '০৬:৩২ PM', Icons.nights_stay),
            _buildPrayerCard('এশা', '০৭:৫০ PM', Icons.brightness_3),
          ],
        ),
      ),
    );
  }

  // একটি নামাজের কার্ড তৈরির উইজেট
  Widget _buildPrayerCard(String name, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal[50],
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('ওয়াক্ত শুরু: $time'),
        trailing: ElevatedButton.icon(
          onPressed: () => triggerVoiceAlert(name),
          icon: const Icon(Icons.volume_up, size: 16),
          label: const Text('টেস্ট কল'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}