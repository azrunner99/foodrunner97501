import '../lib/theme/app_theme.dart';

void main() {
  // Demo showing progressive darkening within each tier
  print('=== Level Color Progressive Darkening Demo ===\n');

  // Define example levels for each tier to show progression
  final exampleLevels = [
    // Beginner tier (1-5): Green progression
    [1, 2, 3, 4, 5],
    // Developing tier (6-15): Blue progression
    [6, 8, 10, 12, 15],
    // Intermediate tier (16-30): Purple progression
    [16, 20, 23, 27, 30],
    // Advanced tier (31-50): Orange progression
    [31, 36, 41, 46, 50],
    // Expert tier (51-75): Red progression
    [51, 58, 65, 70, 75],
    // Master tier (76-100): Deep Purple progression
    [76, 83, 90, 95, 100],
    // Legendary tier (101-125): Gold progression
    [101, 108, 115, 120, 125],
    // Mythical tier (126+): Cyan progression
    [126, 130, 135, 140, 150],
  ];

  final tierNames = [
    'Beginner',
    'Developing',
    'Intermediate',
    'Advanced',
    'Expert',
    'Master',
    'Legendary',
    'Mythical'
  ];

  for (int tierIndex = 0; tierIndex < exampleLevels.length; tierIndex++) {
    final levels = exampleLevels[tierIndex];
    final tierName = tierNames[tierIndex];

    print('$tierName Tier (Levels ${levels.first}-${levels.last}):');

    for (int level in levels) {
      final color = AppTheme.getLevelBubbleColor(level);
      final hex =
          '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
      print('  Level $level: $hex');
    }
    print(''); // Empty line between tiers
  }

  print('How it works:');
  print('- Each tier maintains its base color family');
  print(
      '- Colors progressively darken within each tier as you approach the next level');
  print('- 5 evenly distributed shades across each tier range');
  print('- Smooth visual progression that rewards advancement');
}
