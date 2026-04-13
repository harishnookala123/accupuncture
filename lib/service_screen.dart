import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  final List<Map<String, String>> services = const [
    {
      "title": "Acupuncture Treatment",
      "desc": "Traditional therapy using fine needles to relieve pain and improve health.",
      "icon": "🌿"
    },
    {
      "title": "Acupressure Treatment",
      "desc": "Pressure-based healing technique without needles.",
      "icon": "👆"
    },
    {
      "title": "Sujok Therapy",
      "desc": "Korean therapy focusing on hands and feet for healing.",
      "icon": "🖐️"
    },
    {
      "title": "Auricular Therapy",
      "desc": "Ear acupuncture technique to treat various conditions.",
      "icon": "👂"
    },
    {
      "title": "Moxibustion",
      "desc": "Heat therapy using herbal sticks to improve circulation.",
      "icon": "🔥"
    },
    {
      "title": "Cupping Therapy",
      "desc": "Suction-based therapy to relieve muscle tension and pain.",
      "icon": "🥤"
    },
    {
      "title": "Massage Therapy",
      "desc": "Relaxation and healing through body massage techniques.",
      "icon": "💆"
    },
    {
      "title": "Cosmetic Acupuncture",
      "desc": "Natural facial treatment for skin rejuvenation and glow.",
      "icon": "✨"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.white,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Custom AppBar with Hero effect
            SliverAppBar(
              expandedHeight: 140,
              floating: true,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.teal,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  "Our Services",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:Colors.white ,
                    letterSpacing: 1,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.teal,
                        Colors.teal.shade700,
                        Colors.teal.shade800,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Opacity(
                      opacity: 0.3,
                      child: Icon(
                        Icons.spa,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Services List with animation
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final service = services[index];
                    return _buildAnimatedServiceCard(service, index, context);
                  },
                  childCount: services.length,
                ),
              ),
            ),

            // Footer spacing
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 24),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     _showConsultationDialog(context);
      //   },
      //   backgroundColor: Colors.teal,
      //   icon: const Icon(Icons.calendar_today, color: Colors.white),
      //   label: const Text(
      //     "Book Consultation",
      //     style: TextStyle(color: Colors.white),
      //   ),
      // ),
    );
  }

  Widget _buildAnimatedServiceCard(Map<String, String> service, int index, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 400 + (index * 50)),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () {
            _showServiceDetails(context, service);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showServiceDetails(context, service);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Animated Icon Container
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.teal.shade100,
                              Colors.teal.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            service["icon"]!,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service["title"]!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              service["desc"]!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Tap for details",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.teal.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Arrow indicator
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showServiceDetails(BuildContext context, Map<String, String> service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade100, Colors.teal.shade50],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  service["icon"]!,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              service["title"]!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              service["desc"]!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showConsultationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Book This Service",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showConsultationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Book a Consultation"),
        content: const Text(
          "Our team will contact you shortly to schedule your consultation. Please provide your contact details.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Consultation request sent!"),
                  backgroundColor: Colors.teal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}