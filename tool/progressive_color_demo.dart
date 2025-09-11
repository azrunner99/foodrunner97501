// Demo showing progressive darkening within each tier
// This demonstrates how colors get darker as levels approach the next tier

void main() {
  print('=== Level Color Progressive Darkening Demo ===\n');
  
  // Example levels for each tier to show progression
  final examples = [
    // Beginner tier (1-5): Green progression
    {'tier': 'Beginner', 'levels': [1, 2, 3, 4, 5], 'range': '1-5'},
    // Developing tier (6-15): Blue progression  
    {'tier': 'Developing', 'levels': [6, 8, 10, 12, 15], 'range': '6-15'},
    // Intermediate tier (16-30): Purple progression
    {'tier': 'Intermediate', 'levels': [16, 20, 23, 27, 30], 'range': '16-30'},
    // Advanced tier (31-50): Orange progression
    {'tier': 'Advanced', 'levels': [31, 36, 41, 46, 50], 'range': '31-50'},
    // Expert tier (51-75): Red progression
    {'tier': 'Expert', 'levels': [51, 58, 65, 70, 75], 'range': '51-75'},
    // Master tier (76-100): Deep Purple progression
    {'tier': 'Master', 'levels': [76, 83, 90, 95, 100], 'range': '76-100'},
    // Legendary tier (101-125): Gold progression
    {'tier': 'Legendary', 'levels': [101, 108, 115, 120, 125], 'range': '101-125'},
    // Mythical tier (126+): Cyan progression
    {'tier': 'Mythical', 'levels': [126, 130, 135, 140, 150], 'range': '126+'},
  ];
  
  for (final example in examples) {
    final tier = example['tier'] as String;
    final levels = example['levels'] as List<int>;
    final range = example['range'] as String;
    
    print('$tier Tier (Levels $range):');
    print('  Progressive darkening as you approach next tier:');
    
    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final percentage = ((i / (levels.length - 1)) * 100).round();
      final darkness = i == 0 ? 'Lightest' : 
                      i == levels.length - 1 ? 'Darkest' :
                      '${percentage}% darker';
      
      print('  Level $level: $darkness shade of tier color');
    }
    print(''); // Empty line between tiers
  }
  
  print('✨ How Progressive Darkening Works:');
  print('• Each tier keeps its distinctive base color (Green, Blue, Purple, etc.)');
  print('• Colors get progressively DARKER within each tier as you advance');
  print('• At level 1: Lightest green (fresh start)');
  print('• At level 5: Darkest green (approaching blue tier)');
  print('• At level 6: Lightest blue (fresh start in new tier)');
  print('• Creates smooth visual progression that rewards advancement!');
}
