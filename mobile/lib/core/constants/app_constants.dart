/// Points awarded based on task time duration
const Map<int, int> kTimePoints = {5: 5, 15: 10, 30: 15, 60: 25};

/// Points awarded based on level (social/energy)
const Map<String, int> kLevelPoints = {'low': 5, 'medium': 10, 'high': 20};

/// Numeric mapping for energy/social levels
const Map<String, int> kEnergyLevels = {'low': 1, 'medium': 2, 'high': 3};
const Map<String, int> kSocialLevels = {'low': 1, 'medium': 2, 'high': 3};

/// Rank definitions
class Rank {
  final String name;
  final int minPoints;
  const Rank(this.name, this.minPoints);
}

const List<Rank> kRanks = [
  Rank('Task Newbie', 0),
  Rank('Task Apprentice', 100),
  Rank('Task Warrior', 500),
  Rank('Task Hero', 1000),
  Rank('Task Master', 2500),
  Rank('Task Legend', 5000),
];

/// Default task types
const List<String> kDefaultTypes = [
  'Chores',
  'Work',
  'Health',
  'Admin',
  'Errand',
  'Self-care',
  'Creative',
  'Social',
];

/// Freemium limits
const int kFreeTaskLimit = 10;
const String kPremiumMonthlyId = 'whatnow_premium_monthly';
const String kPremiumLifetimeId = 'whatnow_premium_lifetime';

/// Interstitial ad cooldown
const Duration kInterstitialCooldown = Duration(minutes: 3);

/// Time comparisons for gallery
class TimeComparison {
  final double hours;
  final String text;
  const TimeComparison(this.hours, this.text);
}

const List<TimeComparison> kTimeComparisons = [
  TimeComparison(1, 'enough to watch a movie'),
  TimeComparison(5, 'a full workday of productivity'),
  TimeComparison(10, 'the time to read a novel'),
  TimeComparison(24, 'a full day of focus'),
  TimeComparison(50, 'enough to learn a new skill'),
  TimeComparison(100, 'the fastest time to cycle around the world... almost!'),
  TimeComparison(200, 'more than a week of non-stop work'),
];

/// Task count comparisons for gallery
class TaskComparison {
  final int count;
  final String text;
  const TaskComparison(this.count, this.text);
}

const List<TaskComparison> kTaskComparisons = [
  TaskComparison(10, 'a playlist of wins'),
  TaskComparison(25, 'almost a month of daily tasks'),
  TaskComparison(50, 'a deck of cards worth of tasks'),
  TaskComparison(100, 'a century of accomplishments'),
  TaskComparison(200, 'more tasks than days in most years'),
  TaskComparison(365, 'a full year of daily achievements'),
  TaskComparison(500, 'half a thousand victories'),
];

/// Motivational messages for celebration screen
const List<String> kCelebrationMessages = [
  'Keep up the great work!',
  'You\'re on fire!',
  'One step at a time!',
  'Crushing it!',
  'You did the thing!',
  'That\'s how it\'s done!',
  'Progress, not perfection!',
  'Look at you go!',
  'Momentum is everything!',
  'Nailed it!',
];

/// Fallback tasks when no user tasks match
const List<Map<String, dynamic>> kFallbackTasks = [
  {'name': 'Go for a short walk', 'desc': 'Fresh air helps clear the mind', 'type': 'Health', 'time': 15, 'social': 'low', 'energy': 'low'},
  {'name': 'Check the post', 'desc': 'Quick and easy win', 'type': 'Errand', 'time': 5, 'social': 'low', 'energy': 'low'},
  {'name': 'Hoover one room', 'desc': 'Just one room, not the whole house', 'type': 'Chores', 'time': 15, 'social': 'low', 'energy': 'medium'},
  {'name': 'Do the dishes', 'desc': 'Clear the sink, clear the mind', 'type': 'Chores', 'time': 15, 'social': 'low', 'energy': 'low'},
  {'name': 'Drink a glass of water', 'desc': 'Stay hydrated', 'type': 'Health', 'time': 5, 'social': 'low', 'energy': 'low'},
  {'name': 'Stretch for 5 minutes', 'desc': 'Your body will thank you', 'type': 'Health', 'time': 5, 'social': 'low', 'energy': 'low'},
  {'name': 'Tidy your desk', 'desc': 'A clear space for a clear mind', 'type': 'Chores', 'time': 15, 'social': 'low', 'energy': 'low'},
  {'name': 'Take out the rubbish', 'desc': 'One less thing to think about', 'type': 'Chores', 'time': 5, 'social': 'low', 'energy': 'low'},
  {'name': 'Water the plants', 'desc': 'They need you', 'type': 'Chores', 'time': 5, 'social': 'low', 'energy': 'low'},
  {'name': 'Reply to one message', 'desc': 'Just one, you can do it', 'type': 'Social', 'time': 5, 'social': 'medium', 'energy': 'low'},
  {'name': 'Make your bed', 'desc': 'Start with a quick win', 'type': 'Chores', 'time': 5, 'social': 'low', 'energy': 'low'},
  {'name': 'Clear kitchen counter', 'desc': 'Just the counter, nothing else', 'type': 'Chores', 'time': 10, 'social': 'low', 'energy': 'low'},
];
