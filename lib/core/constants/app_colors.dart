import 'package:flutter/material.dart';

/// App color palette for DailyCost.
/// Direction: Warm, vibrant, motivating, modern fintech look with pristine contrast in light and dark modes.
class AppColors {
  AppColors._();

  // Primary brand colors (Persian Mint / Emerald Cyan #00BBA7)
  static const Color primary = Color(0xFF00BBA7); // Core Brand Mint
  static const Color primaryLight = Color(0xFF2DD4BF); // Crisp bright mint for dark mode
  static const Color primaryDark = Color(0xFF0F766E); // Deep emerald teal
  static const Color primaryContainer = Color(0xFFE6FFFA); // Soft ice-mint container
  static const Color primaryContainerDark = Color(0xFF042F2E); // Deep obsidian teal container

  // Accent & Secondary
  static const Color secondary = Color(0xFFF43F5E); // Radiant Coral Rose
  static const Color secondaryLight = Color(0xFFFB7185);
  static const Color accent = Color(0xFF06B6D4); // Cyber Cyan
  static const Color violet = Color(0xFF7C3AED); // Luminous Purple
  static const Color gold = Color(0xFFF59E0B); // Luxury Gold for VIP/Premium
  static const Color goldLight = Color(0xFFFDE68A);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF00BBA7), Color(0xFF0D9488), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    colors: [Color(0xFF042F2E), Color(0xFF115E59), Color(0xFF00BBA7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status indicators
  static const Color withinBudget = Color(0xFF10B981); // Spring Emerald
  static const Color nearBudget = Color(0xFFF59E0B); // Golden Amber
  static const Color overBudget = Color(0xFFEF4444); // Sunset Crimson

  // Surface & Neutral - Light Mode (Clean, soft mint tint)
  static const Color backgroundLight = Color(0xFFF4FAF9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFE8F6F4);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFD1EDE8);

  // Surface & Neutral - Dark Mode (Greenish Obsidian Dark vibe)
  static const Color backgroundDark = Color(0xFF061412); // Deep forest obsidian background
  static const Color surfaceDark = Color(0xFF0C201D); // Rich dark emerald surface
  static const Color surfaceElevatedDark = Color(0xFF132D29); // Elevated emerald container
  static const Color textPrimaryDark = Color(0xFFF0FDF4); // Crisp light mint text
  static const Color textSecondaryDark = Color(0xFF94A3B8); // High contrast secondary
  static const Color borderDark = Color(0xFF1B403B); // Refined dark emerald border

  // Distinct Category Accent Colors
  static const Color catFood = Color(0xFFF97316); // Bright Orange
  static const Color catTransport = Color(0xFF0284C7); // Sky Blue
  static const Color catBills = Color(0xFFEAB308); // Yellow
  static const Color catShopping = Color(0xFFA855F7); // Purple
  static const Color catEntertainment = Color(0xFFEC4899); // Pink
  static const Color catHealth = Color(0xFF14B8A6); // Teal
  static const Color catGroceries = Color(0xFF22C55E); // Green
  static const Color catRent = Color(0xFF6366F1); // Indigo
  static const Color catOther = Color(0xFF64748B); // Slate

  // Color palette list for custom categories
  static const List<Color> customCategoryColors = [
    Color(0xFFF97316),
    Color(0xFF0284C7),
    Color(0xFFEAB308),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF22C55E),
    Color(0xFF6366F1),
    Color(0xFFF43F5E),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
  ];
}
