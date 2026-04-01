import 'package:acupuncture/booking_screen.dart';
import 'package:acupuncture/service_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'login_screen.dart';

class StaticHomeScreen extends StatefulWidget {
  const StaticHomeScreen({super.key});

  @override
  State<StaticHomeScreen> createState() => _StaticHomeScreenState();
}

class _StaticHomeScreenState extends State<StaticHomeScreen> {
  final List<String> imagePaths = [
    'assets/img1.png',
    'assets/img2.png',
    'assets/img3.png',
    'assets/img4.png',
  ];

  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = (_currentPage + 1) % imagePaths.length;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double imageHeight = screenWidth * 0.5; // Image height is 50% of screen width

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade50,
        title:  Text(
          'Acupuncture',
          style: TextStyle(color: Colors.teal.shade700,fontWeight: FontWeight.bold),
        ),

      ),
      body: Container(
        height:double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildImageCarousel(imageHeight),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Welcome to Acupuncture Wellness',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildFeatureButton(context, 'Book Appointment', Icons.calendar_today, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookingScreen()),
                );
              }),
              _buildFeatureButton(context, 'Our Services', Icons.spa, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ServicesScreen()),
                );
              }),
              _buildFeatureButton(context, 'Contact Us', Icons.phone, () {
                // Navigate to Contact Us screen
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(double imageHeight) {
    return SizedBox(
      height: imageHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                imagePaths[index],
                width: double.infinity,
                height: imageHeight,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildFeatureButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
      child: SizedBox(
        width: double.infinity, // Ensures all buttons are of the same width
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white),
          label: Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

}
