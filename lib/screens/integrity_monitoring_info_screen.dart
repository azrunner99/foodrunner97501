import 'package:flutter/material.dart';

class IntegrityMonitoringInfoScreen extends StatelessWidget {
  const IntegrityMonitoringInfoScreen({Key? key}) : super(key: key);

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
                'Timing Patterns (25%): Looks for unnatural clicking rhythms',
                'Volume Analysis (30%): Detects unrealistic delivery counts',
                'Click Patterns (25%): Spots rapid-fire clicking that doesn\'t match real food service',
                'Peer Comparison (20%): Compares performance to other servers for context'
              ],
              Icons.analytics,
              Colors.blue,
            ),
            
            _buildFeatureCard(
              'Rapid-Fire Click Detection',
              'The biggest red flag: servers clicking extremely fast in short bursts to rack up fake deliveries. This catches people trying to cheat by rapid-clicking their button.',
              [
                'Detects bursts of 4+ clicks per minute (humanly difficult during real service)',
                'Flags patterns of rapid clicking followed by long breaks',
                'Identifies clicking speeds that don\'t match realistic food delivery timing',
                'Catches servers trying to quickly accumulate fraudulent points'
              ],
              Icons.mouse,
              Colors.red,
            ),
            
            _buildFeatureCard(
              'Unnatural Pattern Detection',
              'Real food service has natural variation - sometimes busy, sometimes slow. This catches overly consistent clicking that suggests someone is gaming the system methodically.',
              [
                'Detects clicking that\'s "too perfect" or mechanical',
                'Flags unrealistic consistency in delivery timing',
                'Spots patterns that don\'t match natural restaurant flow',
                'Identifies servers who might be systematically cheating'
              ],
              Icons.precision_manufacturing,
              Colors.orange,
            ),
            
            _buildFeatureCard(
              'Unrealistic Session Monitoring',
              'Real servers take breaks, have rushes and slow periods. This flags sessions that seem too long or consistent to be genuine food service work.',
              [
                'Monitors for suspiciously long continuous clicking sessions',
                'Flags activity that doesn\'t match realistic work patterns',
                'Detects servers who might be clicking during off-hours',
                'Identifies patterns that don\'t align with restaurant operating reality'
              ],
              Icons.schedule,
              Colors.green,
            ),
            
            _buildFeatureCard(
              'Performance Outlier Analysis',
              'When someone is delivering way more food than everyone else, it raises questions. This compares each server to the group to spot unrealistic overperformers.',
              [
                'Identifies servers with suspiciously high delivery counts',
                'Compares performance to peer group averages',
                'Flags statistical outliers who might be cheating',
                'Helps maintain fair competition among servers'
              ],
              Icons.show_chart,
              Colors.purple,
            ),
            
            _buildFeatureCard(
              'Sudden Performance Spike Detection',
              'If someone suddenly goes from 10 deliveries to 30+ deliveries instantly, that\'s suspicious. This catches dramatic increases that don\'t match restaurant reality.',
              [
                'Monitors for unrealistic jumps in delivery counts',
                'Flags sudden 3x increases in performance',
                'Detects patterns that don\'t match natural service flow',
                'Catches servers who might start cheating mid-shift'
              ],
              Icons.trending_up,
              Colors.deepOrange,
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
                    'All these systems run automatically in the background, constantly analyzing behavior patterns. When multiple red flags appear together, the risk score increases. The system presents findings in plain English so you can quickly understand what needs attention.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The goal is to maintain fair competition while protecting against automation and ensuring genuine human performance.',
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
            )).toList(),
          ],
        ),
      ),
    );
  }
}
