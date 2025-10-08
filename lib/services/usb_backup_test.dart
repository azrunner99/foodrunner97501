import 'dart:io';
import 'usb_backup_service.dart';
import '../utils/log.dart';

/// Test utility for USB backup functionality
class USBBackupTest {
  static Future<void> testUSBDetection() async {
    d('[USBBackupTest] Testing USB drive detection...');
    
    final usbService = USBBackupService.instance;
    
    // Test USB drive detection
    final hasUSB = await usbService.hasUSBDrive();
    d('[USBBackupTest] Has USB drive: $hasUSB');
    
    if (hasUSB) {
      final drives = await usbService.getConnectedUSBDrives();
      d('[USBBackupTest] Connected drives: $drives');
    }
  }
  
  static Future<void> testBackupCreation() async {
    d('[USBBackupTest] Testing backup creation...');
    
    final usbService = USBBackupService.instance;
    final success = await usbService.manualBackupToUSB();
    
    d('[USBBackupTest] Backup creation result: $success');
  }
}






