import 'package:acupuncture/servicedetail_screen.dart';
import 'package:flutter/material.dart';

class ServicesScreen extends StatefulWidget {
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final List<Map<String, dynamic>> services = [
    {
      'name': 'Traditional Acupuncture',
      'price': '\₹500 per session',
      'description': 'A holistic approach to balance energy and relieve stress.',
    },
    {
      'name': 'Cupping Therapy',
      'price': '\₹400 per session',
      'description': 'Suction cups help to improve circulation and relieve muscle pain.',
    },
    {
      'name': 'Electroacupuncture',
      'price': '\₹600 per session',
      'description': 'A modern take on acupuncture with mild electric stimulation.',
    },
    {
      'name': 'Herbal Consultation',
      'price': '\$30 per session',
      'description': 'Personalized herbal remedies to support overall wellness.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal.shade50,
        title:  Text(
          'Our Services',
          style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
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
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: Icon(Icons.spa, color: Colors.teal.shade700),
                title: Text(
                  services[index]['name'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(services[index]['description']),
                trailing: Text(
                  services[index]['price'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailScreen(service: services[index]),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}