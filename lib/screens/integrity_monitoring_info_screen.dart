import 'package:flutter/material.dart';

class IntegrityMonitoringInfoScreen extends StatelessWidget {
  const IntegrityMonitoringInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integrity Monitoring Systems'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Understanding Our Food Service Integrity Monitoring',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our system monitors server behavior to ensure fair competition and prevent cheating. We watch for patterns that suggest servers might be clicking without actually running food deliveries.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            _buildFeatureCard(
              'Multi-Dimensional Fairness Scoring',
              'Like a fairness report card that combines multiple factors to detect potential cheating. We analyze different aspects of clicking behavior to spot servers who might be gaming the system.',
              [
                'Volume Analysis (40%): Detects unrealistic delivery counts and excessive clicking',
                'Click Patterns (35%): Spots rapid-fire clicking that doesn\'t match real food service',
                'Peer Comparison (25%): Compares performance to other servers for context'
              ],
              Icons.analytics,
              Colors.blue,
            ),
            _buildFeatureCard(
              'Rapid-Fire Click Detection',
              'The biggest red flag: servers clicking extremely fast in short bursts to rack up fake deliveries. This catches people trying to cheat by rapid-clicking their button.',
              [
                'Detects bursts of 4+ clicks per minute (suspicious for real food service)',
                'Flags sustained rapid clicking patterns (5+ clicks is highly suspicious)',
                'Identifies clicking speeds above 8 clicks/second (humanly possible but suspicious)',
                'Distinguishes between legitimate multi-item orders (2-3 clicks) and abuse'
              ],
              Icons.mouse,
              Colors.red,
            ),
            _buildFeatureCard(
              'Volume Consistency Analysis',
              'Monitors overall delivery counts and patterns to spot servers who are clicking way more than realistic for actual food service work.',
              [
                'Compares delivery volumes against realistic restaurant capacity',
                'Flags servers with unusually high click-to-delivery ratios',
                'Detects sudden dramatic increases in delivery counts',
                'Monitors for patterns that don\'t match genuine food service timing'
              ],
              Icons.assessment,
              Colors.orange,
            ),
            _buildFeatureCard(
              'Session Pattern Monitoring',
              'Real servers work in natural patterns with breaks and varying intensity. This detects unrealistic clicking sessions that suggest manual over-clicking.',
              [
                'Monitors for unusually long continuous clicking sessions',
                'Flags activity during non-service hours or breaks',
                'Detects sustained high-intensity clicking patterns',
                'Identifies work patterns that don\'t match realistic restaurant operations'
              ],
              Icons.schedule,
              Colors.green,
            ),
            _buildFeatureCard(
              'Peer Performance Comparison',
              'When someone consistently delivers way more than their colleagues, it raises questions. This compares each server\'s performance to realistic group averages.',
              [
                'Compares individual performance to team averages',
                'Flags statistical outliers who exceed realistic delivery rates',
                'Considers shift type, time of day, and restaurant context',
                'Helps identify servers who may be inflating their numbers'
              ],
              Icons.show_chart,
              Colors.purple,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'How It All Works Together',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All these systems run automatically in the background, constantly analyzing behavior patterns. When multiple red flags appear together, the risk score increases. The system focuses on detecting manual over-clicking where servers click without actually running food deliveries.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The goal is to maintain fair competition by ensuring all servers are genuinely performing food service work, not inflating their numbers through excessive clicking.',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    List<String> details,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'Key Features:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...details.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          detail,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
