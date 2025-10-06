import 'dart:convert';
import '../models.dart';
import '../app_state.dart' show ServerProfile; // For profile typing

/// UnifiedStorageService (temporary in-memory stub)
/// ------------------------------------------------
/// This class intentionally avoids any Drift/database code so the app can
/// compile and run while the real unified storage layer is rebuilt.
/// All methods keep the same signatures that existing code expects.
class UnifiedStorageService {
  static UnifiedStorageService? _instance;
  static UnifiedStorageService get instance => _instance ??= UnifiedStorageService._();
  UnifiedStorageService._();

  bool _initialized = false;

  // In-memory backing stores
  final List<Server> _servers = [];
  final List<ShiftRecord> _shifts = [];
  final Map<String, ServerProfile> _profiles = {};
  final List<Map<String, dynamic>> _npsFeedback = [];
  final List<Map<String, dynamic>> _monthlyReports = [];
  final Map<String, dynamic> _settings = {};
  final List<Map<String, dynamic>> _performanceData = [];
  final List<Map<String, dynamic>> _businessData = [];
  final List<Map<String, dynamic>> _stationAssignments = [];
  final Map<String, Map<String, dynamic>> _tapLogs = {};
  final Map<String, Map<String, dynamic>> _dayPlans = {};
  final Map<String, Map<String, dynamic>> _assets = {};

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<void> _ensureInit() async { if (!_initialized) await init(); }

  // Servers
  Future<List<Server>> getAllServers() async { await _ensureInit(); return List.from(_servers); }
  Future<void> saveServer(Server server) async { await _ensureInit(); final i=_servers.indexWhere((s)=>s.id==server.id); if(i==-1){_servers.add(server);}else{_servers[i]=server;} }
  Future<void> deleteServer(String serverId) async { await _ensureInit(); _servers.removeWhere((s)=>s.id==serverId); }

  // Shifts
  Future<List<ShiftRecord>> getAllShifts() async { await _ensureInit(); return List.from(_shifts); }
  Future<void> saveShift(ShiftRecord shift) async { await _ensureInit(); final i=_shifts.indexWhere((s)=>s.id==shift.id); if(i==-1){_shifts.add(shift);}else{_shifts[i]=shift;} }
  Future<void> deleteShift(String shiftId) async { await _ensureInit(); _shifts.removeWhere((s)=>s.id==shiftId); }

  // Profiles
  Future<List<ServerProfile>> getAllServerProfiles() async { await _ensureInit(); return _profiles.values.toList(); }
  Future<void> saveServerProfile(String serverId, ServerProfile profile) async { await _ensureInit(); _profiles[serverId]=profile; }

  // NPS feedback
  Future<void> saveNPSFeedback(Map<String, dynamic> feedback) async { await _ensureInit(); _npsFeedback.add(Map<String,dynamic>.from(feedback)); }
  Future<List<Map<String, dynamic>>> getNPSFeedback(String serverId) async { await _ensureInit(); return _npsFeedback.where((f)=>f['server_id']==serverId).map((f)=>Map<String,dynamic>.from(f)).toList(); }
  Future<List<Map<String, dynamic>>> getAllNPSFeedback() async { await _ensureInit(); return _npsFeedback.map((f)=>Map<String,dynamic>.from(f)).toList(); }

  // Monthly reports
  Future<void> saveMonthlyReport(Map<String, dynamic> report) async { await _ensureInit(); _monthlyReports.removeWhere((r)=>r['server_id']==report['server_id'] && r['report_month']==report['report_month'] && r['report_year']==report['report_year']); _monthlyReports.add(Map<String,dynamic>.from(report)); }
  Future<List<Map<String, dynamic>>> getMonthlyReports(String serverId) async { await _ensureInit(); return _monthlyReports.where((r)=>r['server_id']==serverId).map((r)=>Map<String,dynamic>.from(r)).toList(); }

  // Performance data (generic keying by server + type)
  Future<void> savePerformanceData(String serverId, String dataType, Map<String, dynamic> data) async { await _ensureInit(); _performanceData.add({'serverId':serverId,'dataType':dataType,'dataContent':Map<String,dynamic>.from(data),'createdAt':DateTime.now().toIso8601String()}); }
  Future<List<Map<String, dynamic>>> getPerformanceData(String serverId, String dataType) async { await _ensureInit(); return _performanceData.where((p)=>p['serverId']==serverId && p['dataType']==dataType).map((p)=>Map<String,dynamic>.from(p['dataContent'] as Map)).toList(); }

  // Business data (month-year + type)
  Future<void> saveBusinessData(String monthYear, String dataType, Map<String, dynamic> data) async { await _ensureInit(); _businessData.add({'monthYear':monthYear,'dataType':dataType,'dataContent':Map<String,dynamic>.from(data),'createdAt':DateTime.now().toIso8601String()}); }
  Future<List<Map<String, dynamic>>> getBusinessData(String monthYear, String dataType) async { await _ensureInit(); return _businessData.where((b)=>b['monthYear']==monthYear && b['dataType']==dataType).map((b)=>Map<String,dynamic>.from(b['dataContent'] as Map)).toList(); }

  // Station assignments
  Future<void> saveStationAssignment(String serverId, String shiftDate, String shiftType, String? stationType, String? sectionAssignment) async { await _ensureInit(); _stationAssignments.add({'server_id':serverId,'shift_date':shiftDate,'shift_type':shiftType,'station_type':stationType,'section_assignment':sectionAssignment,'created_at':DateTime.now().toIso8601String()}); }
  Future<List<Map<String, dynamic>>> getStationAssignments(String serverId) async { await _ensureInit(); return _stationAssignments.where((a)=>a['server_id']==serverId).map((a)=>Map<String,dynamic>.from(a)).toList(); }

  // Tap logs
  Future<void> saveTapLogData(String key, Map<String, dynamic> data) async { await _ensureInit(); _tapLogs[key]= {'key': key, 'data': jsonEncode(data), 'updated_at': DateTime.now().toIso8601String()}; }
  Future<Map<String, dynamic>?> getTapLogData(String key) async { await _ensureInit(); final raw=_tapLogs[key]; if(raw==null) return null; return jsonDecode(raw['data'] as String) as Map<String,dynamic>; }

  // Day plans
  Future<void> saveDayPlanData(String date, Map<String, dynamic> data) async { await _ensureInit(); _dayPlans[date]={'date':date,'data':jsonEncode(data),'updated_at':DateTime.now().toIso8601String()}; }
  Future<Map<String, dynamic>?> getDayPlanData(String date) async { await _ensureInit(); final raw=_dayPlans[date]; if(raw==null) return null; return jsonDecode(raw['data'] as String) as Map<String,dynamic>; }

  // Assets
  Future<void> saveAssetData(String key, Map<String, dynamic> data) async { await _ensureInit(); _assets[key]={'key':key,'data':jsonEncode(data),'updated_at':DateTime.now().toIso8601String()}; }
  Future<Map<String, dynamic>?> getAssetData(String key) async { await _ensureInit(); final raw=_assets[key]; if(raw==null) return null; return jsonDecode(raw['data'] as String) as Map<String,dynamic>; }

  // Settings
  Future<T?> getSetting<T>(String key) async { await _ensureInit(); return _settings[key] as T?; }
  Future<void> setSetting(String key, dynamic value) async { await _ensureInit(); if(value==null){_settings.remove(key);}else{_settings[key]=value;} }

  // Stats & maintenance
  Future<Map<String, int>> getDatabaseStats() async { await _ensureInit(); return {
    'servers': _servers.length,
    'shifts': _shifts.length,
    'nps_feedback': _npsFeedback.length,
    'monthly_reports': _monthlyReports.length,
    'performance_data': _performanceData.length,
    'business_data': _businessData.length,
    'station_assignments': _stationAssignments.length,
  }; }
  Future<void> clearAllData() async { await _ensureInit(); _servers.clear(); _shifts.clear(); _profiles.clear(); _npsFeedback.clear(); _monthlyReports.clear(); _settings.clear(); _performanceData.clear(); _businessData.clear(); _stationAssignments.clear(); _tapLogs.clear(); _dayPlans.clear(); _assets.clear(); }
}


