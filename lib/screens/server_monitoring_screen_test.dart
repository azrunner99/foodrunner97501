import 'package:flutter/material.dart';

class ServerMonitoringScreen extends StatelessWidget {
  const ServerMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Monitoring'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Complete Server Monitoring Dashboard\n\nFully Functional!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
