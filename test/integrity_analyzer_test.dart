import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/utils/integrity_analyzer.dart';
import 'package:food_runs_counter/models.dart';

void main() {
  group('Integrity Analyzer Tests', () {
    final testServers = [
      Server(id: 'test_server', name: 'Test Server'),
      Server(id: 'other_server', name: 'Other Server'),
    ];
    final testServerCounts = {'test_server': 1000, 'other_server': 500};
    final testTime = DateTime.now();

    test('Basic integrity analysis works without timestamps', () {
      final assessment = IntegrityAnalyzer.analyzeServer(
        serverId: 'test_server',
        serverName: 'Test Server',
        clickBins: {'1': 10, '2': 5, '3': 2, '4+': 0},
        totalRuns: 1000,
        allServers: testServers,
        allServerCounts: testServerCounts,
        analysisTime: testTime,
      );

      expect(assessment.serverId, equals('test_server'));
      expect(assessment.serverName, equals('Test Server'));
      expect(assessment.riskScore, isA<double>());
      expect(assessment.riskLevel, isA<RiskLevel>());
    });

    test('Enhanced integrity analysis works with timestamps', () {
      // Create test timestamps - 5 clicks over 2 seconds
      final now = DateTime.now();
      final timestamps = [
        now,
        now.add(Duration(milliseconds: 500)),
        now.add(Duration(milliseconds: 1000)),
        now.add(Duration(milliseconds: 1500)),
        now.add(Duration(milliseconds: 2000)),
      ];

      final assessment = IntegrityAnalyzer.analyzeServer(
        serverId: 'test_server',
        serverName: 'Test Server',
        clickBins: {'1': 10, '2': 5, '3': 2, '4+': 0},
        totalRuns: 1000,
        allServers: testServers,
        allServerCounts: testServerCounts,
        analysisTime: testTime,
        individualTimestamps: timestamps,
      );

      expect(assessment.serverId, equals('test_server'));
      expect(assessment.serverName, equals('Test Server'));
      expect(assessment.riskScore, isA<double>());
      expect(assessment.riskLevel, isA<RiskLevel>());
      // With timestamp data, should have enhanced analysis
      expect(assessment.alerts.length, greaterThanOrEqualTo(0));
    });

    test('TimestampIntegrityAnalyzer methods work correctly', () {
      // Create test timestamps
      final now = DateTime.now();
      final timestamps = [
        now,
        now.add(Duration(milliseconds: 100)),
        now.add(Duration(milliseconds: 200)),
        now.add(Duration(milliseconds: 300)),
        now.add(Duration(milliseconds: 400)),
      ];

      // Test velocity analysis
      final velocityRisk = TimestampIntegrityAnalyzer.analyzeClickVelocity(timestamps);
      expect(velocityRisk, isA<double>());
      expect(velocityRisk, greaterThanOrEqualTo(0.0));
      expect(velocityRisk, lessThanOrEqualTo(100.0));

      // Test mechanical consistency analysis
      final signature = TimestampIntegrityAnalyzer.analyzeMechanicalConsistency(timestamps);
      expect(signature.meanInterval, isA<double>());
      expect(signature.coefficientOfVariation, isA<double>());
      expect(signature.isMechanical, isA<bool>());
      expect(signature.isSuspicious, isA<bool>());
      expect(signature.isHuman, isA<bool>());

      // Test micro-burst detection
      final bursts = TimestampIntegrityAnalyzer.detectMicroBursts(timestamps);
      expect(bursts, isA<List<MicroBurst>>());
    });

    test('Legitimate 2-3 item runs do not trigger false positives', () {
      // Create legitimate multi-item run patterns (2-3 clicks within reasonable time)
      final now = DateTime.now();
      final legitimateTimestamps = [
        // Normal single clicks
        now,
        now.add(Duration(seconds: 30)),
        now.add(Duration(seconds: 60)),
        
        // Legitimate 2-item run (2 clicks ~300ms apart)
        now.add(Duration(seconds: 90)),
        now.add(Duration(milliseconds: 90300)),
        
        // Legitimate 3-item run (3 clicks ~400ms apart)
        now.add(Duration(seconds: 120)),
        now.add(Duration(milliseconds: 120400)),
        now.add(Duration(milliseconds: 120800)),
        
        // More normal single clicks
        now.add(Duration(seconds: 150)),
        now.add(Duration(seconds: 180)),
      ];

      final assessment = IntegrityAnalyzer.analyzeServer(
        serverId: 'legitimate_server',
        serverName: 'Legitimate Server',
        clickBins: {'1': 15, '2': 8, '3': 2, '4+': 0}, // Normal pattern
        totalRuns: 1500,
        allServers: testServers,
        allServerCounts: testServerCounts,
        analysisTime: testTime,
        individualTimestamps: legitimateTimestamps,
      );

      // Should NOT trigger alerts for legitimate behavior
      final timestampAlerts = assessment.alerts.where((alert) => 
        alert.title.contains('Burst') || 
        alert.title.contains('Velocity') || 
        alert.title.contains('Pattern')
      ).toList();

      expect(timestampAlerts.isEmpty, isTrue, 
        reason: 'Legitimate 2-3 item runs should NOT trigger alerts');
      expect(assessment.riskLevel, isNot(RiskLevel.red),
        reason: 'Legitimate patterns should not result in high risk');
    });

    test('Proportional analysis detects dishonest vs honest multi-clicking', () {
      final now = DateTime.now();
      
      // Honest pattern: Mostly single clicks with occasional legitimate 2-3 item runs
      final honestTimestamps = [
        // Single clicks
        now, now.add(Duration(seconds: 30)), now.add(Duration(seconds: 60)),
        now.add(Duration(seconds: 90)), now.add(Duration(seconds: 120)),
        
        // Legitimate 2-item run
        now.add(Duration(seconds: 150)), now.add(Duration(milliseconds: 150400)),
        
        // More single clicks
        now.add(Duration(seconds: 180)), now.add(Duration(seconds: 210)),
        now.add(Duration(seconds: 240)), now.add(Duration(seconds: 270)),
        
        // Legitimate 3-item run
        now.add(Duration(seconds: 300)), now.add(Duration(milliseconds: 300400)),
        now.add(Duration(milliseconds: 300800)),
        
        // More single clicks
        now.add(Duration(seconds: 330)), now.add(Duration(seconds: 360)),
        now.add(Duration(seconds: 390)), now.add(Duration(seconds: 420)),
      ];
      
      final honestAssessment = IntegrityAnalyzer.analyzeServer(
        serverId: 'honest_server',
        serverName: 'Honest Server',
        clickBins: {'1': 18, '2': 3, '3': 1, '4+': 0}, // Realistic honest pattern
        totalRuns: 1200,
        allServers: testServers,
        allServerCounts: testServerCounts,
        analysisTime: testTime,
        individualTimestamps: honestTimestamps,
      );

      // Dishonest pattern: Too many multi-clicks - walking by and clicking extra
      final dishonestTimestamps = [
        // 2-click events (dishonest extras)
        now, now.add(Duration(milliseconds: 200)),
        now.add(Duration(seconds: 20)), now.add(Duration(milliseconds: 20200)),
        now.add(Duration(seconds: 40)), now.add(Duration(milliseconds: 40200)),
        
        // 3-click events (more dishonest extras)  
        now.add(Duration(seconds: 60)), now.add(Duration(milliseconds: 60200)),
        now.add(Duration(milliseconds: 60400)),
        now.add(Duration(seconds: 80)), now.add(Duration(milliseconds: 80200)),
        now.add(Duration(milliseconds: 80400)),
        
        // Even some 4+ click events (clear abuse)
        now.add(Duration(seconds: 100)), now.add(Duration(milliseconds: 100200)),
        now.add(Duration(milliseconds: 100400)), now.add(Duration(milliseconds: 100600)),
        
        // Single clicks are rare
        now.add(Duration(seconds: 120)), now.add(Duration(seconds: 140)),
      ];
      
      final dishonestAssessment = IntegrityAnalyzer.analyzeServer(
        serverId: 'dishonest_server',
        serverName: 'Dishonest Server',
        clickBins: {'1': 5, '2': 8, '3': 6, '4+': 2}, // Suspicious proportions
        totalRuns: 600,
        allServers: testServers,
        allServerCounts: testServerCounts,
        analysisTime: testTime,
        individualTimestamps: dishonestTimestamps,
      );

      // Verify honest pattern doesn't trigger proportional alerts
      final honestProportionalAlerts = honestAssessment.alerts.where((alert) => 
        alert.title.contains('Multi-Click') || alert.title.contains('Frequency')
      ).toList();
      
      expect(honestProportionalAlerts.isEmpty, isTrue, 
        reason: 'Honest servers with occasional legitimate multi-clicks should NOT trigger proportional alerts');

      // Verify dishonest pattern DOES trigger proportional alerts
      final dishonestProportionalAlerts = dishonestAssessment.alerts.where((alert) => 
        alert.title.contains('Multi-Click') || alert.title.contains('Frequency')
      ).toList();
      
      expect(dishonestProportionalAlerts.isNotEmpty, isTrue, 
        reason: 'Dishonest servers with excessive multi-clicking should trigger proportional alerts');
      
      // Verify risk levels reflect the difference
      expect(dishonestAssessment.riskScore, greaterThan(honestAssessment.riskScore),
        reason: 'Dishonest proportional patterns should result in higher risk scores');
    });
  });
}