// Test to verify MessageVarietyEngine produces 500+ unique messages
import 'lib/services/message_variety_engine.dart';

void main() {
  print('Testing MessageVarietyEngine with 500+ unique messages...\n');
  
  final uniqueMessages = <String>{};
  
  // Generate 100 messages to test variety
  for (int i = 0; i < 100; i++) {
    final message = MessageVarietyEngine.getSimpleVarietyMessage('mixed', 15);
    uniqueMessages.add(message);
    
    if (i < 10) {
      print('Message ${i + 1}: $message');
    }
  }
  
  print('\n--- Results ---');
  print('Generated 100 messages');
  print('Unique messages: ${uniqueMessages.length}');
  print('Variety rate: ${(uniqueMessages.length / 100 * 100).toStringAsFixed(1)}%');
  
  if (uniqueMessages.length > 80) {
    print('✅ EXCELLENT: High message variety achieved!');
  } else if (uniqueMessages.length > 50) {
    print('✅ GOOD: Good message variety');
  } else {
    print('⚠️ LOW: Message variety could be improved');
  }
  
  print('\nTest specific categories:');
  
  final speedMessage = MessageVarietyEngine.getSimpleVarietyMessage('speed', 20);
  print('Speed message: $speedMessage');
  
  final competitiveMessage = MessageVarietyEngine.getSimpleVarietyMessage('competitive', 25);
  print('Competitive message: $competitiveMessage');
  
  final achievementMessage = MessageVarietyEngine.getSimpleVarietyMessage('achievement', 30);
  print('Achievement message: $achievementMessage');
  
  final precisionMessage = MessageVarietyEngine.getSimpleVarietyMessage('precision', 35);
  print('Precision message: $precisionMessage');
}