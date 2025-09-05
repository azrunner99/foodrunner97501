import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StationType {
  final String name;
  final String abbreviation;
  final int sections;
  StationType({required this.name, required this.abbreviation, required this.sections});

  Map<String, dynamic> toJson() => {
    'name': name,
    'abbreviation': abbreviation,
    'sections': sections,
  };
  factory StationType.fromJson(Map<String, dynamic> json) => StationType(
    name: json['name'],
    abbreviation: json['abbreviation'],
    sections: json['sections'],
  );
}

class StationTypesScreen extends StatefulWidget {
  const StationTypesScreen({super.key});

  @override
  State<StationTypesScreen> createState() => _StationTypesScreenState();
}

class _StationTypesScreenState extends State<StationTypesScreen> {
  final List<StationType> _stationTypes = [];
  final Set<int> _expanded = {};

  static const _prefsKey = 'station_types';

  @override
  void initState() {
    super.initState();
    _loadStationTypes();
  }

  Future<void> _loadStationTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString != null) {
      final List decoded = json.decode(jsonString);
      setState(() {
        _stationTypes.clear();
        _stationTypes.addAll(decoded.map((e) => StationType.fromJson(e)).cast<StationType>());
      });
    }
  }

  // Simulate saving to persistent storage
  Future<void> _saveStationTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_stationTypes.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, jsonString);
  }

  @override
  void dispose() {
    _saveStationTypes();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    await _saveStationTypes();
    return true;
  }

  void _showAddDialog() async {
    final nameController = TextEditingController();
    final abbrController = TextEditingController();
    final sectionsController = TextEditingController();
    final result = await showDialog<StationType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Station Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Station type name'),
            ),
            TextField(
              controller: abbrController,
              decoration: const InputDecoration(labelText: 'Abbreviation'),
              maxLength: 6,
            ),
            TextField(
              controller: sectionsController,
              decoration: const InputDecoration(labelText: 'Number of sections'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final abbr = abbrController.text.trim();
              final sections = int.tryParse(sectionsController.text.trim()) ?? 0;
              if (name.isNotEmpty && abbr.isNotEmpty && sections > 0) {
                Navigator.pop(context, StationType(name: name, abbreviation: abbr, sections: sections));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && !_stationTypes.any((s) => s.name == result.name)) {
      setState(() {
        _stationTypes.add(result);
      });
      await _saveStationTypes();
    }
  }

  void _removeStationType(int index) {
    setState(() {
      _stationTypes.removeAt(index);
      _expanded.remove(index);
    });
    _saveStationTypes();
  }

  void _editStationType(int index) async {
    final type = _stationTypes[index];
    final nameController = TextEditingController(text: type.name);
    final abbrController = TextEditingController(text: type.abbreviation);
    final sectionsController = TextEditingController(text: type.sections.toString());
    final result = await showDialog<StationType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Station Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Station type name'),
            ),
            TextField(
              controller: abbrController,
              decoration: const InputDecoration(labelText: 'Abbreviation'),
              maxLength: 6,
            ),
            TextField(
              controller: sectionsController,
              decoration: const InputDecoration(labelText: 'Number of sections'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final abbr = abbrController.text.trim();
              final sections = int.tryParse(sectionsController.text.trim()) ?? 0;
              if (name.isNotEmpty && abbr.isNotEmpty && sections > 0) {
                Navigator.pop(context, StationType(name: name, abbreviation: abbr, sections: sections));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _stationTypes[index] = result;
      });
      await _saveStationTypes();
    }
  }

  List<String> _generateStations(StationType type) {
    return List.generate(type.sections, (i) => '${type.abbreviation} ${i + 1}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Station Types')),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Container(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Create a new station type:', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      onPressed: _showAddDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Existing station types:', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Expanded(
                  child: _stationTypes.isEmpty
                      ? Center(
                          child: Text('No station types yet.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)),
                        )
                      : ListView.separated(
                          itemCount: _stationTypes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final type = _stationTypes[index];
                            final isExpanded = _expanded.contains(index);
                            return Card(
                              elevation: isExpanded ? 4 : 1,
                              color: theme.colorScheme.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ExpansionTile(
                                key: PageStorageKey('${type.name}_$index'),
                                initiallyExpanded: isExpanded,
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    if (expanded) {
                                      _expanded.add(index);
                                    } else {
                                      _expanded.remove(index);
                                    }
                                  });
                                },
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        type.name,
                                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                          tooltip: 'Edit',
                                          onPressed: () => _editStationType(index),
                                        ),
                                        SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          tooltip: 'Delete',
                                          onPressed: () => _removeStationType(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text('Abbr: ${type.abbreviation} • Sections: ${type.sections}', style: theme.textTheme.bodyMedium),
                                ),
                                children: [
                                  Divider(indent: 16, endIndent: 16, color: theme.dividerColor),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 4),
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: _generateStations(type)
                                          .map((s) => Chip(
                                                label: Text(s, style: theme.textTheme.bodyMedium),
                                                backgroundColor: theme.colorScheme.secondaryContainer,
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Public function to load station types for other screens
Future<List<StationType>> loadStationTypes() async {
  final prefs = await SharedPreferences.getInstance();
  const prefsKey = 'station_types';
  final jsonString = prefs.getString(prefsKey);
  if (jsonString != null) {
    final List decoded = json.decode(jsonString);
    return decoded.map((e) => StationType.fromJson(e)).cast<StationType>().toList();
  }
  return [];
}
