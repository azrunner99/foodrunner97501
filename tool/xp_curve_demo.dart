import '../lib/gamification.dart';

void main() {
  for (int lvl = 1; lvl <= 20; lvl++) {
    print('Level $lvl: XP required = \\${xpTable[lvl]}, XP to next = \\${xpTable[lvl+1] - xpTable[lvl]}');
  }
  print('Level 100: XP required = \\${xpTable[100]}');
  print('Level 150: XP required = \\${xpTable[150]}');
}
