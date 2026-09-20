import 'package:intl/intl.dart';

class DailyQuotes {
  DailyQuotes._();

  static const List<String> quotes = [
    "Do not save what is left after spending, but spend what is left after saving.",
    "A budget isn't about restriction; it's about making your money work for what truly matters.",
    "Small daily savings create monumental future freedom.",
    "Beware of little expenses; a small leak will sink a great ship.",
    "Staying under your daily budget today is a deposit into tomorrow's peace of mind.",
    "Financial peace isn't the acquisition of stuff; it's learning to live on less than you make.",
    "The secret to wealth is simple: find more joy in saving than in mindless spending.",
    "Every dollar you don't spend today is an employee working for your future.",
    "A disciplined budget is your bridge between financial goals and financial reality.",
    "Spending within your daily limit gives you the power to say yes to what matters most.",
    "Rich isn't what you earn; it is what you keep and grow.",
    "Patience in spending is the foundation of lifelong financial confidence.",
    "Before you buy, ask yourself if it buys you lasting happiness or temporary thrill.",
    "Living below your means today buys you choices and dignity tomorrow.",
    "A daily budget keeps you intentional, confident, and free from financial anxiety.",
    "True wealth is having enough independence to control your own time.",
    "The fastest way to double your money is to fold it over and put it back in your pocket.",
    "Mastering your daily cost today protects your peace tomorrow.",
    "Money is a terrible master but an excellent, obedient servant.",
    "You don't need a fortune to start saving; you need daily consistency.",
    "Delaying gratification is the superpower of every financially successful person.",
    "Count your daily expenses carefully, and your monthly savings will take care of themselves.",
    "A budget tells your money where to go instead of wondering where it went.",
    "Frugality without deprivation is the art of prioritizing genuine value.",
    "Every time you stay under budget, you take one step closer to financial independence.",
    "Peace of mind is the ultimate luxury that only financial discipline can buy.",
    "Your future self will thank you for the thoughtful spending choices you make today.",
    "Smart spending isn't about buying less; it's about buying what truly enriches your life.",
    "Consistency beats perfection: respect your daily limit, one day at a time.",
    "Financial freedom begins the day your savings become non-negotiable.",
  ];

  /// Returns the deterministic quote for [referenceDate] (defaults to current date).
  /// Quote remains unchanged from 12:00 AM to 11:59 PM and rotates daily through 30 unique quotes.
  static String getTodayQuote([DateTime? referenceDate]) {
    final date = referenceDate ?? DateTime.now();
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final index = (dayOfYear - 1) % quotes.length;
    return quotes[index];
  }
}
