import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../app_state.dart';

import '../widgets/wallpaper_background.dart';

import 'manage_servers_screen.dart';class AdminScreen extends StatelessWidget {

import 'server_avatar_settings_screen.dart';

import 'server_dashboard_screen.dart';  const AdminScreen({super.key});

import 'backup_manager_screen.dart';

import 'server_performance_screen.dart';class AdminScreen extends StatelessWidget {import 'package:provider/provider.dart';

import 'server_nps_screen.dart';

  @override

class AdminScreen extends StatefulWidget {

  const AdminScreen({super.key});  Widget build(BuildContext context) {  const AdminScreen({super.key});



  @override    print("🚨 NEW ADMIN SCREEN IS WORKING!");

  State<AdminScreen> createState() => _AdminScreenState();

}    import '../app_state.dart';import 'package:provider/provider.dart';import 'package:provider/provider.dart';



class _AdminScreenState extends State<AdminScreen> {    return Scaffold(

  bool _unlocked = true; // AUTO-UNLOCK FOR TESTING

  final _pinCtrl = TextEditingController();      appBar: AppBar(  @override



  @override        title: const Text('🚨 NEW Admin Tools'),

  Widget build(BuildContext context) {

    print("🚨 DEBUG: AdminScreen.build() called - NEW VERSION ACTIVE!");        backgroundColor: Colors.green,  Widget build(BuildContext context) {import '../widgets/wallpaper_background.dart';

    

    final app = context.watch<AppState>();      ),

    if (!_unlocked) {

      return Scaffold(      body: const Center(    print("🚨 NEW ADMIN SCREEN IS WORKING!");

        appBar: AppBar(

          title: const Text('😊 Admin Access'),        child: Text(

          backgroundColor: Colors.green, // SMILEY TEST

        ),          'Fresh Admin Screen - Build Cache Bypassed!',    import 'manage_servers_screen.dart';import '../app_state.dart';import '../app_state.dart';

        body: const Center(

          child: Text('PIN Entry Screen'),          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

        ),

      );        ),    return Scaffold(

    }

      ),

    print("🚨 DEBUG: Showing unlocked admin screen with Server NPS!");

        );      appBar: AppBar(import 'server_avatar_settings_screen.dart';

    return Scaffold(

      appBar: AppBar(  }

        title: const Text('😊 NEW Admin Tools'),

        backgroundColor: Colors.green, // GREEN FOR TESTING}        title: const Text('🚨 NEW Admin Tools'),

        elevation: 0,

      ),        backgroundColor: Colors.green,import 'server_dashboard_screen.dart';import '../widgets/wallpaper_background.dart';import '../widgets/wallpaper_background.dart';

      body: WallpaperBackground(

        child: Container(      ),

          decoration: BoxDecoration(

            gradient: LinearGradient(      body: const Center(import 'backup_manager_screen.dart';

              begin: Alignment.topCenter,

              end: Alignment.bottomCenter,        child: Text(

              colors: [

                Colors.black.withOpacity(0.1),          'Fresh Admin Screen - Build Cache Bypassed!',import 'server_performance_screen.dart';import 'manage_servers_screen.dart';import 'manage_servers_screen.dart';

                Colors.black.withOpacity(0.3),

              ],          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

            ),

          ),        ),import 'server_nps_screen.dart';

          child: ListView(

            padding: const EdgeInsets.all(16),      ),

            children: [

              _buildSectionCard(    );import 'server_avatar_settings_screen.dart';import 'server_avatar_settings_screen.dart';

                'Management Tools',

                Icons.settings,  }

                [

                  _buildAdminTile(}class AdminScreen extends StatefulWidget {

                    icon: Icons.manage_accounts,

                    title: 'Manage Servers',  const AdminScreen({super.key});import 'server_dashboard_screen.dart';import 'server_dashboard_screen.dart';

                    subtitle: 'Add, rename, or remove servers (PIN required)',

                    enabled: true,

                    onTap: () {

                      Navigator.push(  @overrideimport 'backup_manager_screen.dart';import 'backup_manager_screen.dart';

                        context,

                        MaterialPageRoute(builder: (_) => const ManageServersScreen()),  State<AdminScreen> createState() => _AdminScreenState();

                      );

                    },}import 'server_performance_screen.dart';import 'server_performance_screen.dart';

                  ),

                  _buildAdminTile(

                    icon: Icons.table_restaurant,

                    title: 'Manage Stations',class _AdminScreenState extends State<AdminScreen> {import 'server_nps_screen.dart';import 'server_nps_screen.dart';

                    subtitle: 'Create, edit, or remove station types',

                    enabled: true,  bool _unlocked = true; // AUTO-UNLOCK FOR TESTING

                    onTap: () {

                      Navigator.pushNamed(context, '/stations');  final _pinCtrl = TextEditingController();

                    },

                  ),

                  _buildAdminTile(

                    icon: Icons.image,  @override// CRITICAL DEBUG: This should print when file is loaded// CRITICAL DEBUG: This should print when file is loaded

                    title: 'Server Avatar Audit',

                    subtitle: 'View photos taken by Team Members',  void initState() {

                    enabled: true,

                    onTap: () {    super.initState();void _debugPrint() {void _debugPrint() {

                      Navigator.push(

                        context,    print('🚨 [FRESH ADMIN] AdminScreen.initState called - NEW FILE WORKING!');

                        MaterialPageRoute(builder: (_) => const ServerAvatarSettingsScreen()),

                      );  }  print('[CRITICAL DEBUG] NEW admin_screen.dart FILE LOADED WITH MODIFICATIONS!!!');  print('[CRITICAL DEBUG] admin_screen.dart FILE LOADED WITH MODIFICATIONS!!!');

                    },

                  ),

                  _buildAdminTile(

                    icon: Icons.monitor_heart,  @override}}

                    title: 'Server Monitoring',

                    subtitle: 'Monitor server activity and performance',  Widget build(BuildContext context) {

                    enabled: true,

                    onTap: () {    print('🚨 [FRESH ADMIN] AdminScreen.build called - SERVER NPS SHOULD BE VISIBLE!');

                      Navigator.push(

                        context,    

                        MaterialPageRoute(builder: (_) => const ServerDashboardScreen()),

                      );    final app = context.watch<AppState>();class AdminScreen extends StatefulWidget {class AdminScreen extends StatefulWidget {

                    },

                  ),    if (!_unlocked) {

                  _buildAdminTile(

                    icon: Icons.analytics,      return Scaffold(  AdminScreen({super.key}) {  AdminScreen({super.key}) {

                    title: 'Server Performance',

                    subtitle: 'Analyze server performance metrics and trends',        appBar: AppBar(

                    enabled: true,

                    onTap: () {          title: const Text('Admin Access'),    _debugPrint(); // Force debug print    _debugPrint(); // Force debug print

                      Navigator.push(

                        context,        ),

                        MaterialPageRoute(builder: (_) => const ServerPerformanceScreen()),

                      );        body: const Center(child: Text('PIN Entry (bypassed for testing)')),  }  }

                    },

                  ),      );

                  _buildAdminTile(

                    icon: Icons.sentiment_satisfied,    }

                    title: 'Server NPS', // CHANGED FROM BUSINESS DATA ENTRY

                    subtitle: 'Manage server Net Promoter Score tracking',

                    enabled: true,

                    onTap: () {    return Scaffold(  @override  @override

                      print("🚨 DEBUG: Navigating to Server NPS screen!");

                      Navigator.push(      appBar: AppBar(

                        context,

                        MaterialPageRoute(builder: (_) => const ServerNPSScreen()),        title: const Text('🚨 FRESH Admin Tools 😃 (NEW FILE)'),  State<AdminScreen> createState() => _AdminScreenState();  State<AdminScreen> createState() => _AdminScreenState();

                      );

                    },        backgroundColor: Colors.green, // Different color to prove it's working

                  ),

                  _buildAdminTile(      ),}}

                    icon: Icons.backup,

                    title: 'Data Backup & Restore',      body: WallpaperBackground(

                    subtitle: 'Backup and restore all app data',

                    enabled: true,        child: ListView(

                    onTap: () {

                      Navigator.push(          padding: const EdgeInsets.all(16),

                        context,

                        MaterialPageRoute(builder: (_) => const BackupManagerScreen()),          children: [class _AdminScreenState extends State<AdminScreen> {class _AdminScreenState extends State<AdminScreen> {

                      );

                    },            // BIG TEST MARKER

                  ),

                ],            Container(  bool _unlocked = true; // AUTO-UNLOCK FOR TESTING  bool _unlocked = true; // AUTO-UNLOCK FOR TESTING

              ),

              const SizedBox(height: 32),              padding: const EdgeInsets.all(24),

            ],

          ),              color: Colors.yellow,  final _pinCtrl = TextEditingController();  final _pinCtrl = TextEditingController();

        ),

      ),              child: const Text(

    );

  }                '🚨 NEW FILE WORKING! 😊',



  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {                fontSize: 32,

    return Card(

      elevation: 8,                textAlign: TextAlign.center,  @override  @override

      shadowColor: Colors.red.withOpacity(0.3),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),                style: TextStyle(fontWeight: FontWeight.bold),

      child: Container(

        decoration: BoxDecoration(              ),  void initState() {  void initState() {

          borderRadius: BorderRadius.circular(16),

          gradient: LinearGradient(            ),

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,            const SizedBox(height: 16),    super.initState();    super.initState();

            colors: [

              Colors.white.withOpacity(0.9),            _buildSectionCard(

              Colors.white.withOpacity(0.7),

            ],              'Management Tools',    // Extra debug to verify construction    // Extra debug to verify construction

          ),

          border: Border.all(              Icons.settings,

            color: Colors.red.withOpacity(0.2),

            width: 1,              [    print('[DEBUG] NEW AdminScreen.initState called - instance created');    print('[DEBUG] AdminScreen.initState called - instance created');

          ),

        ),                _buildAdminTile(

        child: Padding(

          padding: const EdgeInsets.all(20),                  icon: Icons.manage_accounts,    _debugPrint(); // Call debug function again    _debugPrint(); // Call debug function again

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,                  title: 'Manage Servers',

            children: [

              Row(                  subtitle: 'Add, rename, or remove servers (PIN required)',  }  }

                children: [

                  Container(                  enabled: true,

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(                  onTap: () {

                      gradient: LinearGradient(

                        begin: Alignment.topLeft,                    Navigator.push(

                        end: Alignment.bottomRight,

                        colors: [                      context,  @override  @override

                          Colors.red.shade600,

                          Colors.red.shade400,                      MaterialPageRoute(builder: (_) => const ManageServersScreen()),

                        ],

                      ),                    );  Widget build(BuildContext context) {  Widget build(BuildContext context) {

                      borderRadius: BorderRadius.circular(12),

                      boxShadow: [                  },

                        BoxShadow(

                          color: Colors.red.withOpacity(0.3),                ),    print('[DEBUG] NEW AdminScreen.build called - Server NPS should be visible! UPDATED!!!');    print('[DEBUG] AdminScreen.build called - Server NPS should be visible! UPDATED!!!');

                          spreadRadius: 2,

                          blurRadius: 8,                _buildAdminTile(

                          offset: const Offset(0, 4),

                        ),                  icon: Icons.star_rate,        

                      ],

                    ),                  title: '🚨 Server NPS (NEW!)',

                    child: Icon(icon, color: Colors.white, size: 24),

                  ),                  subtitle: 'Manage Net Promoter Score data and analytics',    final app = context.watch<AppState>();    final app = context.watch<AppState>();

                  const SizedBox(width: 16),

                  Text(                  enabled: true,

                    title,

                    style: const TextStyle(                  onTap: () {    if (!_unlocked) {    if (!_unlocked) {

                      fontSize: 20,

                      fontWeight: FontWeight.bold,                    print('🚨 [FRESH ADMIN] Server NPS tile tapped!');

                      color: Colors.black87,

                    ),                    Navigator.push(      return Scaffold(      return Scaffold(

                  ),

                ],                      context,

              ),

              const SizedBox(height: 20),                      MaterialPageRoute(builder: (_) => const ServerNPSScreen()),        appBar: AppBar(        appBar: AppBar(

              ...children,

            ],                    );

          ),

        ),                  },          title: const Text('Admin Access'),          title: const Text('Admin Access'),

      ),

    );                ),

  }

                _buildAdminTile(          backgroundColor: Colors.transparent,          backgroundColor: Colors.transparent,

  Widget _buildAdminTile({

    required IconData icon,                  icon: Icons.backup,

    required String title,

    required String subtitle,                  title: 'Data Backup & Restore',          elevation: 0,          elevation: 0,

    required bool enabled,

    required VoidCallback? onTap,                  subtitle: 'Backup and restore all app data',

  }) {

    return Padding(                  enabled: true,          flexibleSpace: Container(          flexibleSpace: Container(

      padding: const EdgeInsets.only(bottom: 12),

      child: Material(                  onTap: () {

        color: Colors.transparent,

        child: InkWell(                    Navigator.push(            decoration: BoxDecoration(            decoration: BoxDecoration(

          onTap: enabled ? onTap : null,

          borderRadius: BorderRadius.circular(12),                      context,

          child: Container(

            padding: const EdgeInsets.all(16),                      MaterialPageRoute(builder: (_) => const BackupManagerScreen()),              gradient: LinearGradient(              gradient: LinearGradient(

            decoration: BoxDecoration(

              color: enabled                     );

                  ? Colors.red.shade50.withOpacity(0.5)

                  : Colors.grey.shade100.withOpacity(0.3),                  },                begin: Alignment.topCenter,                begin: Alignment.topCenter,

              borderRadius: BorderRadius.circular(12),

              border: Border.all(                ),

                color: enabled 

                    ? Colors.red.withOpacity(0.3)              ],                end: Alignment.bottomCenter,                end: Alignment.bottomCenter,

                    : Colors.grey.withOpacity(0.3),

                width: 1,            ),

              ),

            ),          ],                colors: [                colors: [

            child: Row(

              children: [        ),

                Container(

                  padding: const EdgeInsets.all(8),      ),                  Colors.red.shade600.withOpacity(0.8),                  Colors.red.shade600.withOpacity(0.8),

                  decoration: BoxDecoration(

                    color: enabled     );

                        ? Colors.red.shade600

                        : Colors.grey.shade400,  }                  Colors.red.shade400.withOpacity(0.6),                  Colors.red.shade400.withOpacity(0.6),

                    borderRadius: BorderRadius.circular(8),

                  ),

                  child: Icon(

                    icon,  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {                ],                ],

                    color: Colors.white,

                    size: 20,    return Card(

                  ),

                ),      child: Padding(              ),              ),

                const SizedBox(width: 16),

                Expanded(        padding: const EdgeInsets.all(16),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,        child: Column(            ),            ),

                    children: [

                      Text(          crossAxisAlignment: CrossAxisAlignment.start,

                        title,

                        style: TextStyle(          children: [          ),          ),

                          fontSize: 16,

                          fontWeight: FontWeight.w600,            Row(

                          color: enabled ? Colors.black87 : Colors.grey.shade600,

                        ),              children: [        ),        ),

                      ),

                      const SizedBox(height: 4),                Icon(icon),

                      Text(

                        subtitle,                const SizedBox(width: 8),        body: WallpaperBackground(        body: WallpaperBackground(

                        style: TextStyle(

                          fontSize: 14,                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                          color: enabled ? Colors.black54 : Colors.grey.shade500,

                        ),              ],          child: Container(          child: Container(

                      ),

                    ],            ),

                  ),

                ),            const SizedBox(height: 16),            decoration: BoxDecoration(            decoration: BoxDecoration(

                if (enabled)

                  Icon(            ...children,

                    Icons.arrow_forward_ios,

                    color: Colors.red.shade400,          ],              gradient: LinearGradient(              gradient: LinearGradient(

                    size: 16,

                  ),        ),

              ],

            ),      ),                begin: Alignment.topCenter,                begin: Alignment.topCenter,

          ),

        ),    );

      ),

    );  }                end: Alignment.bottomCenter,                end: Alignment.bottomCenter,

  }

}

  Widget _buildAdminTile({                colors: [                colors: [

    required IconData icon,

    required String title,                  Colors.black.withOpacity(0.1),                  Colors.black.withOpacity(0.1),

    required String subtitle,

    required bool enabled,                  Colors.black.withOpacity(0.3),                  Colors.black.withOpacity(0.3),

    required VoidCallback? onTap,

  }) {                ],                ],

    return ListTile(

      leading: Icon(icon),              ),              ),

      title: Text(title),

      subtitle: Text(subtitle),            ),            ),

      onTap: enabled ? onTap : null,

      trailing: enabled ? const Icon(Icons.arrow_forward_ios) : null,            child: Center(            child: Center(

    );

  }              child: Container(              child: Container(

}
                margin: const EdgeInsets.all(24),                margin: const EdgeInsets.all(24),

                padding: const EdgeInsets.all(24),                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(                decoration: BoxDecoration(

                  borderRadius: BorderRadius.circular(16),                  borderRadius: BorderRadius.circular(16),

                  gradient: LinearGradient(                  gradient: LinearGradient(

                    begin: Alignment.topLeft,                    begin: Alignment.topLeft,

                    end: Alignment.bottomRight,                    end: Alignment.bottomRight,

                    colors: [                    colors: [

                      Colors.white.withOpacity(0.9),                      Colors.white.withOpacity(0.9),

                      Colors.white.withOpacity(0.7),                      Colors.white.withOpacity(0.7),

                    ],                    ],

                  ),                  ),

                  border: Border.all(                  border: Border.all(

                    color: Colors.red.withOpacity(0.3),                    color: Colors.red.withOpacity(0.3),

                    width: 1,                    width: 1,

                  ),                  ),

                  boxShadow: [                  boxShadow: [

                    BoxShadow(                    BoxShadow(

                      color: Colors.black.withOpacity(0.2),                      color: Colors.black.withOpacity(0.2),

                      blurRadius: 8,                      blurRadius: 8,

                      offset: const Offset(0, 4),                      offset: const Offset(0, 4),

                    ),                    ),

                  ],                  ],

                ),                ),

                child: Column(                child: SingleChildScrollView(

                  mainAxisSize: MainAxisSize.min,                  child: Column(

                  children: [                    mainAxisSize: MainAxisSize.min,

                    Container(                    children: [

                      padding: const EdgeInsets.all(16),                    Container(

                      decoration: BoxDecoration(                      padding: const EdgeInsets.all(16),

                        color: Colors.red.withOpacity(0.1),                      decoration: BoxDecoration(

                        borderRadius: BorderRadius.circular(12),                        color: Colors.red.withOpacity(0.1),

                      ),                        borderRadius: BorderRadius.circular(12),

                      child: Icon(                      ),

                        Icons.admin_panel_settings,                      child: Icon(

                        size: 48,                        Icons.admin_panel_settings,

                        color: Colors.red.shade700,                        size: 48,

                      ),                        color: Colors.red.shade700,

                    ),                      ),

                    const SizedBox(height: 24),                    ),

                    Text(                    const SizedBox(height: 24),

                      'Admin Access Required',                    Text(

                      style: TextStyle(                      'Admin Access Required',

                        fontSize: 24,                      style: TextStyle(

                        fontWeight: FontWeight.bold,                        fontSize: 24,

                        color: Colors.red.shade700,                        fontWeight: FontWeight.bold,

                      ),                        color: Colors.red.shade700,

                    ),                      ),

                    const SizedBox(height: 8),                    ),

                    Text(                    const SizedBox(height: 8),

                      'Enter your PIN to access admin tools',                    Text(

                      style: TextStyle(                      'Enter your PIN to access admin tools',

                        color: Colors.grey.shade600,                      style: TextStyle(

                        fontSize: 16,                        color: Colors.grey.shade600,

                      ),                        fontSize: 16,

                    ),                      ),

                    const SizedBox(height: 24),                    ),

                    Container(                    const SizedBox(height: 24),

                      decoration: BoxDecoration(                    Container(

                        color: Colors.grey.shade50,                      decoration: BoxDecoration(

                        borderRadius: BorderRadius.circular(12),                        color: Colors.grey.shade50,

                        border: Border.all(color: Colors.grey.shade300),                        borderRadius: BorderRadius.circular(12),

                      ),                        border: Border.all(color: Colors.grey.shade300),

                      child: TextField(                      ),

                        controller: _pinCtrl,                      child: TextField(

                        obscureText: true,                        controller: _pinCtrl,

                        textAlign: TextAlign.center,                        obscureText: true,

                        readOnly: true,                        textAlign: TextAlign.center,

                        style: const TextStyle(                        readOnly: true,

                          fontSize: 20,                        style: const TextStyle(

                          letterSpacing: 4,                          fontSize: 20,

                          fontWeight: FontWeight.bold,                          letterSpacing: 4,

                        ),                          fontWeight: FontWeight.bold,

                        decoration: InputDecoration(                        ),

                          hintText: 'Enter PIN',                        decoration: InputDecoration(

                          border: InputBorder.none,                          hintText: 'Enter PIN',

                          contentPadding: const EdgeInsets.all(16),                          border: InputBorder.none,

                          focusedBorder: OutlineInputBorder(                          contentPadding: const EdgeInsets.all(16),

                            borderRadius: BorderRadius.circular(12),                          focusedBorder: OutlineInputBorder(

                            borderSide: BorderSide(color: Colors.red.shade400, width: 2),                            borderRadius: BorderRadius.circular(12),

                          ),                            borderSide: BorderSide(color: Colors.red.shade400, width: 2),

                        ),                          ),

                      ),                        ),

                    ),                      ),

                    const SizedBox(height: 24),                    ),

                    _buildKeypad(),                    const SizedBox(height: 24),

                    const SizedBox(height: 24),                    _buildKeypad(),

                    SizedBox(                    const SizedBox(height: 24),

                      width: double.infinity,                    SizedBox(

                      child: ElevatedButton(                      width: double.infinity,

                        onPressed: () => _tryUnlock(app),                      child: ElevatedButton(

                        style: ElevatedButton.styleFrom(                        onPressed: () => _tryUnlock(app),

                          backgroundColor: Colors.red.shade600,                        style: ElevatedButton.styleFrom(

                          foregroundColor: Colors.white,                          backgroundColor: Colors.red.shade600,

                          padding: const EdgeInsets.symmetric(vertical: 16),                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(                          padding: const EdgeInsets.symmetric(vertical: 16),

                            borderRadius: BorderRadius.circular(12),                          shape: RoundedRectangleBorder(

                          ),                            borderRadius: BorderRadius.circular(12),

                        ),                          ),

                        child: const Text(                        ),

                          'Unlock Admin Tools',                        child: const Text(

                          style: TextStyle(                          'Unlock Admin Tools',

                            fontSize: 16,                          style: TextStyle(

                            fontWeight: FontWeight.bold,                            fontSize: 16,

                          ),                            fontWeight: FontWeight.bold,

                        ),                          ),

                      ),                        ),

                    ),                      ),

                  ],                    ),

                ),                  ],

              ),                ),

            ),              ),

          ),              ),

        ),            ),

      );          ),

    }        ),

      );

    return Scaffold(    }

      appBar: AppBar(

        title: const Text('Admin Tools 😃 (debug)'),    return Scaffold(

        backgroundColor: Colors.transparent,      appBar: AppBar(

        elevation: 0,        title: const Text('Admin Tools 😃 (debug)'),

        flexibleSpace: Container(        backgroundColor: Colors.transparent,

          decoration: BoxDecoration(        elevation: 0,

            gradient: LinearGradient(        flexibleSpace: Container(

              begin: Alignment.topCenter,          decoration: BoxDecoration(

              end: Alignment.bottomCenter,            gradient: LinearGradient(

              colors: [              begin: Alignment.topCenter,

                Colors.red.shade600.withOpacity(0.8),              end: Alignment.bottomCenter,

                Colors.red.shade400.withOpacity(0.6),              colors: [

              ],                Colors.red.shade600.withOpacity(0.8),

            ),                Colors.red.shade400.withOpacity(0.6),

          ),              ],

        ),            ),

      ),          ),

      body: WallpaperBackground(        ),

        child: Container(      ),

          decoration: BoxDecoration(      body: WallpaperBackground(

            gradient: LinearGradient(        child: Container(

              begin: Alignment.topCenter,          decoration: BoxDecoration(

              end: Alignment.bottomCenter,            gradient: LinearGradient(

              colors: [              begin: Alignment.topCenter,

                Colors.black.withOpacity(0.1),              end: Alignment.bottomCenter,

                Colors.black.withOpacity(0.3),              colors: [

              ],                Colors.black.withOpacity(0.1),

            ),                Colors.black.withOpacity(0.3),

          ),              ],

          child: ListView(            ),

            padding: const EdgeInsets.all(16),          ),

            children: [          child: ListView(

              // Test smiley marker            padding: const EdgeInsets.all(16),

              Container(            children: [

                padding: const EdgeInsets.all(16),              // Test smiley face for responsiveness

                child: const Text(              Container(

                  '😊',                alignment: Alignment.center,

                  fontSize: 48,                padding: const EdgeInsets.all(16),

                  textAlign: TextAlign.center,                child: const Text(

                ),                  '😊',

              ),                  style: TextStyle(fontSize: 48),

              const SizedBox(height: 16),                ),

              _buildSectionCard(              ),

                'Management Tools',              _buildSectionCard(

                Icons.settings,                'Management Tools',

                [                Icons.settings,

                  _buildAdminTile(                [

                    icon: Icons.manage_accounts,                  _buildAdminTile(

                    title: 'Manage Servers',                    icon: Icons.manage_accounts,

                    subtitle: 'Add, rename, or remove servers (PIN required)',                    title: 'Manage Servers',

                    enabled: true,                    subtitle: 'Add, rename, or remove servers (PIN required)',

                    onTap: () {                    enabled: true,

                      Navigator.push(                    onTap: () {

                        context,                      Navigator.push(

                        MaterialPageRoute(builder: (_) => const ManageServersScreen()),                        context,

                      );                        MaterialPageRoute(builder: (_) => const ManageServersScreen()),

                    },                      );

                  ),                    },

                  _buildAdminTile(                  ),

                    icon: Icons.table_restaurant,                  _buildAdminTile(

                    title: 'Manage Stations',                    icon: Icons.table_restaurant,

                    subtitle: 'Create, edit, or remove station types',                    title: 'Manage Stations',

                    enabled: true,                    subtitle: 'Create, edit, or remove station types',

                    onTap: () {                    enabled: true,

                      Navigator.pushNamed(context, '/stations');                    onTap: () {

                    },                      Navigator.pushNamed(context, '/stations');

                  ),                    },

                  _buildAdminTile(                  ),

                    icon: Icons.image,                  _buildAdminTile(

                    title: 'Server Avatar Audit',                    icon: Icons.image,

                    subtitle: 'View photos taken by Team Members',                    title: 'Server Avatar Audit',

                    enabled: true,                    subtitle: 'View photos taken by Team Members',

                    onTap: () {                    enabled: true,

                      Navigator.push(                    onTap: () {

                        context,                      Navigator.push(

                        MaterialPageRoute(builder: (_) => const ServerAvatarSettingsScreen()),                        context,

                      );                        MaterialPageRoute(builder: (_) => const ServerAvatarSettingsScreen()),

                    },                      );

                  ),                    },

                  _buildAdminTile(                  ),

                    icon: Icons.monitor_heart,                  _buildAdminTile(

                    title: 'Server Monitoring',                    icon: Icons.monitor_heart,

                    subtitle: 'Monitor server activity and performance',                    title: 'Server Activity Monitoring',

                    enabled: true,                    subtitle: 'Monitor server activity and performance',

                    onTap: () {                    enabled: true,

                      Navigator.push(                    onTap: () {

                        context,                      Navigator.push(

                        MaterialPageRoute(builder: (_) => const ServerDashboardScreen()),                        context,

                      );                        MaterialPageRoute(builder: (_) => const ServerDashboardScreen()),

                    },                      );

                  ),                    },

                  _buildAdminTile(                  ),

                    icon: Icons.analytics,                  _buildAdminTile(

                    title: 'Server Performance',                    icon: Icons.analytics,

                    subtitle: 'Analyze server performance metrics and trends',                    title: 'Server Performance',

                    enabled: true,                    subtitle: 'Analyze server performance metrics and trends',

                    onTap: () {                    enabled: true,

                      Navigator.push(                    onTap: () {

                        context,                      Navigator.push(

                        MaterialPageRoute(builder: (_) => const ServerPerformanceScreen()),                        context,

                      );                        MaterialPageRoute(builder: (_) => const ServerPerformanceScreen()),

                    },                      );

                  ),                    },

                  _buildAdminTile(                  ),

                    icon: Icons.star_rate,                  _buildAdminTile(

                    title: 'Server NPS',                    icon: Icons.star_rate,

                    subtitle: 'Manage Net Promoter Score data and analytics',                    title: 'Server NPS',

                    enabled: true,                    subtitle: 'Manage Net Promoter Score data and analytics',

                    onTap: () {                    enabled: true,

                      print('[DEBUG] NEW Server NPS tile tapped!');                    onTap: () {

                      Navigator.push(                      print('[DEBUG] Server NPS tile tapped!');

                        context,                      Navigator.push(

                        MaterialPageRoute(builder: (_) => const ServerNPSScreen()),                        context,

                      );                        MaterialPageRoute(builder: (_) => const ServerNPSScreen()),

                    },                      );

                  ),                    },

                  _buildAdminTile(                  ),

                    icon: Icons.backup,                  _buildAdminTile(

                    title: 'Data Backup & Restore',                    icon: Icons.backup,

                    subtitle: 'Backup and restore all app data',                    title: 'Data Backup & Restore',

                    enabled: true,                    subtitle: 'Backup and restore all app data',

                    onTap: () {                    enabled: true,

                      Navigator.push(                    onTap: () {

                        context,                      Navigator.push(

                        MaterialPageRoute(builder: (_) => const BackupManagerScreen()),                        context,

                      );                        MaterialPageRoute(builder: (_) => const BackupManagerScreen()),

                    },                      );

                  ),                    },

                ],                  ),

              ),                ],

              const SizedBox(height: 32),              ),

            ],              const SizedBox(height: 32),

          ),            ],

        ),          ),

      ),        ),

    );      ),

  }    );

  }

  void _tryUnlock(AppState app) {

    if (_pinCtrl.text == AppState.adminPin) {  void _tryUnlock(AppState app) {

      setState(() => _unlocked = true);    if (_pinCtrl.text == AppState.adminPin) {

    } else {      setState(() => _unlocked = true);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN')));    } else {

    }      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN')));

  }    }

  }

  Widget _buildKeypad() {

    return Container(  Widget _buildKeypad() {

      padding: const EdgeInsets.all(16),    return Container(

      child: Column(      padding: const EdgeInsets.all(16),

        children: [      child: Column(

          Row(        children: [

            mainAxisAlignment: MainAxisAlignment.spaceEvenly,          Row(

            children: [            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              _buildKeypadButton('1'),            children: [

              _buildKeypadButton('2'),              _buildKeypadButton('1'),

              _buildKeypadButton('3'),              _buildKeypadButton('2'),

            ],              _buildKeypadButton('3'),

          ),            ],

          const SizedBox(height: 12),          ),

          Row(          const SizedBox(height: 12),

            mainAxisAlignment: MainAxisAlignment.spaceEvenly,          Row(

            children: [            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              _buildKeypadButton('4'),            children: [

              _buildKeypadButton('5'),              _buildKeypadButton('4'),

              _buildKeypadButton('6'),              _buildKeypadButton('5'),

            ],              _buildKeypadButton('6'),

          ),            ],

          const SizedBox(height: 12),          ),

          Row(          const SizedBox(height: 12),

            mainAxisAlignment: MainAxisAlignment.spaceEvenly,          Row(

            children: [            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              _buildKeypadButton('7'),            children: [

              _buildKeypadButton('8'),              _buildKeypadButton('7'),

              _buildKeypadButton('9'),              _buildKeypadButton('8'),

            ],              _buildKeypadButton('9'),

          ),            ],

          const SizedBox(height: 12),          ),

          Row(          const SizedBox(height: 12),

            mainAxisAlignment: MainAxisAlignment.spaceEvenly,          Row(

            children: [            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              _buildKeypadButton('Clear', isSpecial: true),            children: [

              _buildKeypadButton('0'),              _buildKeypadButton('Clear', isSpecial: true),

              _buildKeypadButton('⌫', isSpecial: true),              _buildKeypadButton('0'),

            ],              _buildKeypadButton('⌫', isSpecial: true),

          ),            ],

        ],          ),

      ),        ],

    );      ),

  }    );

  }

  Widget _buildKeypadButton(String text, {bool isSpecial = false}) {

    return SizedBox(  Widget _buildKeypadButton(String text, {bool isSpecial = false}) {

      width: 70,    return SizedBox(

      height: 60,      width: 70,

      child: ElevatedButton(      height: 60,

        onPressed: () => _onKeypadPressed(text),      child: ElevatedButton(

        style: ElevatedButton.styleFrom(        onPressed: () => _onKeypadPressed(text),

          backgroundColor: isSpecial        style: ElevatedButton.styleFrom(

              ? Colors.grey.shade200          backgroundColor: isSpecial 

              : Colors.white,              ? Colors.grey.shade200 

          foregroundColor: isSpecial              : Colors.white,

              ? Colors.grey.shade700          foregroundColor: isSpecial 

              : Colors.black87,              ? Colors.grey.shade700 

          elevation: 2,              : Colors.black87,

          shadowColor: Colors.red.withOpacity(0.2),          elevation: 2,

          shape: RoundedRectangleBorder(          shadowColor: Colors.red.withOpacity(0.2),

            borderRadius: BorderRadius.circular(12),          shape: RoundedRectangleBorder(

            side: BorderSide(            borderRadius: BorderRadius.circular(12),

              color: Colors.red.withOpacity(0.2),            side: BorderSide(

              width: 1,              color: Colors.red.withOpacity(0.2),

            ),              width: 1,

          ),            ),

        ),          ),

        child: Text(        ),

          text,        child: Text(

          style: TextStyle(          text,

            fontSize: isSpecial ? 16 : 20,          style: TextStyle(

            fontWeight: FontWeight.w600,            fontSize: isSpecial ? 16 : 20,

          ),            fontWeight: FontWeight.w600,

        ),          ),

      ),        ),

    );      ),

  }    );

  }

  void _onKeypadPressed(String value) {

    setState(() {  void _onKeypadPressed(String value) {

      if (value == 'Clear') {    setState(() {

        _pinCtrl.clear();      if (value == 'Clear') {

      } else if (value == '⌫') {        _pinCtrl.clear();

        if (_pinCtrl.text.isNotEmpty) {      } else if (value == '⌫') {

          _pinCtrl.text = _pinCtrl.text.substring(0, _pinCtrl.text.length - 1);        if (_pinCtrl.text.isNotEmpty) {

        }          _pinCtrl.text = _pinCtrl.text.substring(0, _pinCtrl.text.length - 1);

      } else if (_pinCtrl.text.length < 6) { // Limit PIN length        }

        _pinCtrl.text += value;      } else if (_pinCtrl.text.length < 6) { // Limit PIN length

      }        _pinCtrl.text += value;

    });      }

    });

    // Auto-unlock if PIN is complete    

    if (_pinCtrl.text.length >= 4 && _pinCtrl.text == AppState.adminPin) {    // Auto-unlock if PIN is complete

      _tryUnlock(context.read<AppState>());    if (_pinCtrl.text.length >= 4 && _pinCtrl.text == AppState.adminPin) {

    }      _tryUnlock(context.read<AppState>());

  }    }

  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {

    return Card(  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {

      elevation: 8,    return Card(

      shadowColor: Colors.red.withOpacity(0.3),      elevation: 8,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),      shadowColor: Colors.red.withOpacity(0.3),

      child: Container(      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        decoration: BoxDecoration(      child: Container(

          borderRadius: BorderRadius.circular(16),        decoration: BoxDecoration(

          gradient: LinearGradient(          borderRadius: BorderRadius.circular(16),

            begin: Alignment.topLeft,          gradient: LinearGradient(

            end: Alignment.bottomRight,            begin: Alignment.topLeft,

            colors: [            end: Alignment.bottomRight,

              Colors.white.withOpacity(0.9),            colors: [

              Colors.white.withOpacity(0.7),              Colors.white.withOpacity(0.9),

            ],              Colors.white.withOpacity(0.7),

          ),            ],

          border: Border.all(          ),

            color: Colors.red.withOpacity(0.2),          border: Border.all(

            width: 1,            color: Colors.red.withOpacity(0.2),

          ),            width: 1,

        ),          ),

        child: Padding(        ),

          padding: const EdgeInsets.all(20),        child: Padding(

          child: Column(          padding: const EdgeInsets.all(20),

            crossAxisAlignment: CrossAxisAlignment.start,          child: Column(

            children: [            crossAxisAlignment: CrossAxisAlignment.start,

              Row(            children: [

                children: [              Row(

                  Container(                children: [

                    padding: const EdgeInsets.all(12),                  Container(

                    decoration: BoxDecoration(                    padding: const EdgeInsets.all(12),

                      gradient: LinearGradient(                    decoration: BoxDecoration(

                        begin: Alignment.topLeft,                      gradient: LinearGradient(

                        end: Alignment.bottomRight,                        begin: Alignment.topLeft,

                        colors: [                        end: Alignment.bottomRight,

                          Colors.red.shade600,                        colors: [

                          Colors.red.shade400,                          Colors.red.shade600,

                        ],                          Colors.red.shade400,

                      ),                        ],

                      borderRadius: BorderRadius.circular(12),                      ),

                      boxShadow: [                      borderRadius: BorderRadius.circular(12),

                        BoxShadow(                      boxShadow: [

                          color: Colors.red.withOpacity(0.3),                        BoxShadow(

                          spreadRadius: 2,                          color: Colors.red.withOpacity(0.3),

                          blurRadius: 8,                          spreadRadius: 2,

                          offset: const Offset(0, 4),                          blurRadius: 8,

                        ),                          offset: const Offset(0, 4),

                      ],                        ),

                    ),                      ],

                    child: Icon(icon, color: Colors.white, size: 24),                    ),

                  ),                    child: Icon(icon, color: Colors.white, size: 24),

                  const SizedBox(width: 16),                  ),

                  Text(                  const SizedBox(width: 16),

                    title,                  Text(

                    style: const TextStyle(                    title,

                      fontSize: 20,                    style: const TextStyle(

                      fontWeight: FontWeight.bold,                      fontSize: 20,

                      color: Colors.black87,                      fontWeight: FontWeight.bold,

                    ),                      color: Colors.black87,

                  ),                    ),

                ],                  ),

              ),                ],

              const SizedBox(height: 20),              ),

              ...children,              const SizedBox(height: 20),

            ],              ...children,

          ),            ],

        ),          ),

      ),        ),

    );      ),

  }    );

  }

  Widget _buildAdminTile({

    required IconData icon,  Widget _buildAdminTile({

    required String title,    required IconData icon,

    required String subtitle,    required String title,

    required bool enabled,    required String subtitle,

    required VoidCallback? onTap,    required bool enabled,

  }) {    required VoidCallback? onTap,

    return Padding(  }) {

      padding: const EdgeInsets.only(bottom: 12),    return Padding(

      child: Material(      padding: const EdgeInsets.only(bottom: 12),

        color: Colors.transparent,      child: Material(

        child: InkWell(        color: Colors.transparent,

          onTap: enabled ? onTap : null,        child: InkWell(

          borderRadius: BorderRadius.circular(12),          onTap: enabled ? onTap : null,

          child: Container(          borderRadius: BorderRadius.circular(12),

            padding: const EdgeInsets.all(16),          child: Container(

            decoration: BoxDecoration(            padding: const EdgeInsets.all(16),

              color: enabled            decoration: BoxDecoration(

                  ? Colors.red.shade50.withOpacity(0.5)              color: enabled 

                  : Colors.grey.shade100.withOpacity(0.3),                  ? Colors.red.shade50.withOpacity(0.5)

              borderRadius: BorderRadius.circular(12),                  : Colors.grey.shade100.withOpacity(0.3),

              border: Border.all(              borderRadius: BorderRadius.circular(12),

                color: enabled              border: Border.all(

                    ? Colors.red.withOpacity(0.3)                color: enabled 

                    : Colors.grey.withOpacity(0.3),                    ? Colors.red.withOpacity(0.3)

                width: 1,                    : Colors.grey.withOpacity(0.3),

              ),                width: 1,

            ),              ),

            child: Row(            ),

              children: [            child: Row(

                Container(              children: [

                  padding: const EdgeInsets.all(8),                Container(

                  decoration: BoxDecoration(                  padding: const EdgeInsets.all(8),

                    color: enabled                  decoration: BoxDecoration(

                        ? Colors.red.shade600                    color: enabled 

                        : Colors.grey.shade400,                        ? Colors.red.shade600

                    borderRadius: BorderRadius.circular(8),                        : Colors.grey.shade400,

                  ),                    borderRadius: BorderRadius.circular(8),

                  child: Icon(                  ),

                    icon,                  child: Icon(

                    color: Colors.white,                    icon,

                    size: 20,                    color: Colors.white,

                  ),                    size: 20,

                ),                  ),

                const SizedBox(width: 16),                ),

                Expanded(                const SizedBox(width: 16),

                  child: Column(                Expanded(

                    crossAxisAlignment: CrossAxisAlignment.start,                  child: Column(

                    children: [                    crossAxisAlignment: CrossAxisAlignment.start,

                      Text(                    children: [

                        title,                      Text(

                        style: TextStyle(                        title,

                          fontSize: 16,                        style: TextStyle(

                          fontWeight: FontWeight.w600,                          fontSize: 16,

                          color: enabled ? Colors.black87 : Colors.grey.shade600,                          fontWeight: FontWeight.w600,

                        ),                          color: enabled ? Colors.black87 : Colors.grey.shade600,

                      ),                        ),

                      const SizedBox(height: 4),                      ),

                      Text(                      const SizedBox(height: 4),

                        subtitle,                      Text(

                        style: TextStyle(                        subtitle,

                          fontSize: 14,                        style: TextStyle(

                          color: enabled ? Colors.black54 : Colors.grey.shade500,                          fontSize: 14,

                        ),                          color: enabled ? Colors.black54 : Colors.grey.shade500,

                      ),                        ),

                    ],                      ),

                  ),                    ],

                ),                  ),

                if (enabled)                ),

                  Icon(                if (enabled)

                    Icons.arrow_forward_ios,                  Icon(

                    color: Colors.red.shade400,                    Icons.arrow_forward_ios,

                    size: 16,                    color: Colors.red.shade400,

                  ),                    size: 16,

              ],                  ),

            ),              ],

          ),            ),

        ),          ),

      ),        ),

    );      ),

  }    );

}  }
}