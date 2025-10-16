import 'package:flutter/material.dart';

/// Simplified social monitoring dashboard widget (stub implementation)
class SocialMonitoringDashboard extends StatefulWidget {
  final Duration refreshInterval;
  final bool showRealTimeStatus;

  const SocialMonitoringDashboard({
    super.key,
    this.refreshInterval = const Duration(minutes: 5),
    this.showRealTimeStatus = true,
  });

  @override
  State<SocialMonitoringDashboard> createState() => _SocialMonitoringDashboardState();
}

class _SocialMonitoringDashboardState extends State<SocialMonitoringDashboard> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Monitoring'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Social Monitoring Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
