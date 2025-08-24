import 'dart:math';

class GamificationSettings {
  bool enableGamification;
  bool showTeamTotals;
  bool showGoalProgress;
  bool showMvpConfetti;
  bool showEncouragement;

  GamificationSettings({
    this.enableGamification = true,
    this.showTeamTotals = true,
    this.showGoalProgress = true,
    this.showMvpConfetti = true,
    this.showEncouragement = true,
  });

  Map<String, dynamic> toMap() => {
        'enableGamification': enableGamification,
        'showTeamTotals': showTeamTotals,
        'showGoalProgress': showGoalProgress,
        'showMvpConfetti': showMvpConfetti,
        'showEncouragement': showEncouragement,
      };

  static GamificationSettings fromMap(Map m) => GamificationSettings(
        enableGamification: (m['enableGamification'] ?? true) as bool,
        showTeamTotals: (m['showTeamTotals'] ?? true) as bool,
        showGoalProgress: (m['showGoalProgress'] ?? true) as bool,
        showMvpConfetti: (m['showMvpConfetti'] ?? true) as bool,
        showEncouragement: (m['showEncouragement'] ?? true) as bool,
      );
}

enum PowerUp { doublePoint, bonusFive, nothing }

PowerUp rollPowerUp(Random r) {
  final p = r.nextDouble();
  if (p < 0.05) return PowerUp.doublePoint; // 5%
  if (p < 0.08) return PowerUp.bonusFive;   // +5 about 3%
  return PowerUp.nothing;                    // 92%
}

class AchievementDef {
  final String id;
  final String title;
  final String description;

  const AchievementDef(this.id, this.title, this.description);
}

const achievementsCatalog = <AchievementDef>[
  AchievementDef('first_run', 'First Run', 'Logged your very first run.'),
  AchievementDef('ten_in_shift', 'Double Digits', '10 runs in a single shift.'),
  AchievementDef('twenty_in_shift', 'Hustler', '20 runs in a single shift.'),
  AchievementDef('fifty_all_time', 'Workhorse', '50 runs all time.'),
  AchievementDef('hundred_all_time', 'Centurion', '100 runs all time.'),
  AchievementDef('three_streak', 'On a Roll', '3 runs in a row without a break.'),
  AchievementDef('five_streak', 'Steam Engine', '5 runs in a row without a break.'),
  AchievementDef('mvp', 'MVP', 'Top runner for a shift.'),
  AchievementDef('team_goal', 'Closer', 'Team hit the shift goal.'),
  AchievementDef('night_owl', 'Night Owl', 'Logging runs after 11 PM.'),
];

// 100+ messages you provided, verbatim-ish. SnackBar will show them for 3s.
const encouragements = <String>[
  "Run that food, don’t break stride, guests are smiling far and wide.",
  "From fryer to floor, your steps mean more.",
  "Carry high, move with grace, you’re the hero of this place.",
  "Plates don’t wait, you sealed their fate.",
  "Kitchen hot, dining room loud, you just made the team so proud.",
  "Beer is cold, food is hot, hustle like this—we like it a lot.",
  "Quick on your feet, service complete.",
  "One more run, the job gets done.",
  "Guests get fed, the stress is shed.",
  "Your steps today keep chaos away.",
  "Every plate you run is a smoother shift for everyone.",
  "Servers who run food don’t just serve—they lead.",
  "That’s teamwork in motion. Respect.",
  "Guests won’t remember the ticket time, but they’ll remember you showing up quick.",
  "Running food = running the show.",
  "Your hustle keeps the kitchen sane.",
  "That’s how you turn hangry into happy.",
  "Keep it moving—you’re the reason guests brag later.",
  "Fast feet, happy guests. Simple math.",
  "Thanks for reminding everyone what teamwork looks like.",
  "What’s cheesier than our Loaded Nachos? This message.",
  "You move faster than a Pizookie disappearing at a birthday party.",
  "Guests didn’t just order dinner—they ordered you getting it there hot.",
  "Why don’t BJ’s beers fight? Because they’re always on tap for peace.",
  "Your hustle pairs better with burgers than IPA.",
  "If speed was a craft beer, you’d be an Imperial pour.",
  "Deep Dish pizza? Deep hustle energy.",
  "Our Avocado Egg Rolls are crispy, but you’re crispier with timing.",
  "You deliver faster than we rotate seasonal taps.",
  "Pizookie + you = the real perfect pairing.",
  "What do you call cheese that isn’t yours? Nacho cheese.",
  "Why did the chicken join a band? Because it had the drumsticks.",
  "I only know 25 letters of the alphabet. I don’t know Y.",
  "What do you call fake spaghetti? An impasta.",
  "Why don’t skeletons fight each other? They don’t have the guts.",
  "I asked the burger if it wanted a joke. It said, ‘Lettuce be serious.’",
  "Why don’t oysters donate? Because they’re shellfish.",
  "You’re delivering plates like Amazon Prime with legs.",
  "Guests ordered food, but you served style.",
  "The nachos are loaded—just like this app with cheesy lines.",
  "If hustle was bottled, you’d be the house brew.",
  "That run was faster than a bartender chasing clean glassware.",
  "Running food: the only cardio that pays.",
  "No treadmill needed—you already hit your steps.",
  "If plates had legs, they’d still lose to you.",
  "Guests clap quietly in their heads when you run food.",
  "One more plate, one less wait.",
  "You’re serving smoother than nitro.",
  "That sprint? Five-star service.",
  "Shift MVP alert: it’s you.",
  "Food to go, hustle to show.",
  "Run, don’t stall, you’re feeding all.",
  "Hot plate, great mate.",
  "Guests smile, worth the mile.",
  "Quick hands, big plans.",
  "Move fast, make it last.",
  "Run true, all eyes on you.",
  "Kitchen’s done, now you’ve won.",
  "Step by step, you’ve earned respect.",
  "Shift complete with speedy feet.",
  "Our guests want burgers. We want servers like you.",
  "You’re faster than a Pizookie on free dessert day.",
  "BJ’s handcrafted beer is smooth. Your run was smoother.",
  "Avocado Egg Rolls don’t crunch themselves—thanks for the assist.",
  "You put the ‘brew’ in Brewhouse hustle.",
  "You’re hotter than our Parmesan-Crusted Chicken.",
  "Guests came for the menu, stayed because of you.",
  "That run was seasoned better than our Tri-Tip.",
  "Teamwork is the real secret ingredient, and you’ve got plenty.",
  "Nothing pairs better with fries than your speed.",
  "I asked my dog to run food—he said it was too ruff.",
  "What do you call an alligator in a vest? An investigator.",
  "Why did the tomato blush? Because it saw the salad dressing.",
  "What do you call a factory that makes okay products? A satisfactory.",
  "This run brought more smiles than mozzarella sticks.",
  "Why can’t your nose be 12 inches long? Because then it’d be a foot.",
  "Guests don’t tip clocks, but they should—because you’re on time.",
  "Your run was cleaner than a sanitized pint glass.",
  "What do you call someone with no body and no nose? Nobody knows.",
  "Fastest thing on the floor? Not Wi-Fi—you.",
  "You’re delivering happiness one plate at a time.",
  "That hustle deserves a round of BJ’s Blonde.",
  "Guests don’t know how chaotic it is—but we do. Thanks.",
  "You’re the human version of a Pizookie sampler platter: everyone loves you.",
  "You keep service hotter than the oven line.",
  "Running food is a thankless job—so here’s a thank you.",
  "If there were Olympic medals for food running, you’d be gold.",
  "You move smoother than a full keg roll.",
  "That run deserves applause louder than a Saturday night.",
  "Shift saved. Thanks to you.",
  "If hustle had a flavor, it’d be BJ’s Honey Blonde.",
  "You’re moving faster than kids when they hear ‘free Pizookie.’",
  "Service is a symphony—you’re the rhythm.",
  "You just carried joy on a plate.",
  "Another run, another guest turned happy.",
  "You’ve got more energy than a nitro cold brew.",
  "You’re stacking wins like pepperoni on a flatbread.",
  "That run was smoother than our Cream Soda float.",
  "Food is fuel. You’re the spark.",
  "This isn’t just food running—it’s Brewhouse artistry.",
  "Keep moving like that and HR’s gonna have to add ‘marathoner’ to your title.",
  "Guests didn’t clap, but they’re definitely thinking it.",
  "Fast, sharp, reliable—you’re the Swiss Army knife of the shift.",
  "Your hustle is the Wi-Fi password: essential.",
  "BJ’s has 100+ menu items, but you’re the best one.",
];

