import 'package:flutter/material.dart';

/// A widget that displays a reference card for a common programming error.
///
/// The card shows:
///   * **errorTitle** – the name of the error (e.g., "NullPointerException").
///   * **errorDescription** – a short Arabic description of why the error occurs.
///   * **solution** – a concise Arabic solution or best‑practice tip.
///   * **language** – optional programming language badge (e.g., "Dart").
///   * **onTap** – optional callback when the card is tapped (e.g., navigate to a detailed page).
///
/// The widget follows the app's dark theme defined in `app_theme.dart` and can be
/// used anywhere in the app – the home screen, the AI‑chat suggestions list, or
/// the code‑editor help overlay.
class ReferenceCard extends StatelessWidget {
  /// Title of the error (usually the exception name or a short phrase).
  final String errorTitle;

  /// Brief Arabic description of the error cause.
  final String errorDescription;

  /// Arabic solution or best‑practice recommendation.
  final String solution;

  /// Optional programming language badge (e.g., "Dart", "Python").
  final String? language;

  /// Optional callback when the user taps the card.
  final VoidCallback? onTap;

  const ReferenceCard({
    Key? key,
    required this.errorTitle,
    required this.errorDescription,
    required this.solution,
    this.language,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: title + optional language badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      errorTitle,
                      style: theme.textTheme.headline6?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (language != null) _buildLanguageBadge(language!, isDark),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                errorDescription,
                style: theme.textTheme.bodyText2?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              // Solution title
              Text(
                'الحل:',
                style: theme.textTheme.subtitle1?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.tealAccent[200] : Colors.teal[800],
                ),
              ),
              const SizedBox(height: 4),
              // Solution body
              Text(
                solution,
                style: theme.textTheme.bodyText2?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a small badge that displays the programming language.
  Widget _buildLanguageBadge(String language, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey[700] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        language,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.blue[800],
        ),
      ),
    );
  }
}
