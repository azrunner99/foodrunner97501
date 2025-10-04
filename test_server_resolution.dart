import 'lib/services/application_update_service.dart';

void main() async {
  print('Testing server name resolution...');
  
  // Test with some known server IDs from the logs
  final testIds = ['hjemzqy3sslvtt3o', 'jmwkqxav22yi4ek6', '128'];
  
  for (final serverId in testIds) {
    try {
      final serverName = await ApplicationUpdateService.resolveServerName(serverId);
      print('Server ID "$serverId" resolves to: "$serverName"');
    } catch (e) {
      print('Error resolving server ID "$serverId": $e');
    }
  }
}