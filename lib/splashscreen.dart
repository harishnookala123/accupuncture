import 'package:acupuncture/Admin/admin_screen.dart';
import 'package:acupuncture/login_screen.dart';
import 'package:acupuncture/static_homescreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<StatefulWidget> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Wait for 2 seconds (splash screen duration)
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is already logged in
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");
    String? userName = prefs.getString("name");
     print(userId);
     print(userName);
     if(userName == "Admin"){
       if(mounted){
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const AdminScreen(username: "Admin",)));
       }
     }
    else if (userId != null && userName != null) {
      // User is already logged in, go to home screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StaticHomeScreen(
              userId: userId,
              name: userName,
            ),
          ),
        );
      }
    } else {
      // User not logged in, go to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/aacu2.gif',
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width * 0.8,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.teal,
            ),
            const SizedBox(height: 10),

          ],
        ),
      ),
    );
  }
}