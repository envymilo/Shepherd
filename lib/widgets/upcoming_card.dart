import 'package:flutter/material.dart';

class UpcomingCard extends StatelessWidget {
  final Color color;
  final String title;
  final Icon icon;
  final VoidCallback onCardPressed;

  const UpcomingCard({
    super.key,
    required this.color,
    required this.title,
    required this.icon,
    required this.onCardPressed,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final text = _insertLineBreak(title, context);

    return ElevatedButton(
      onPressed: onCardPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.02, horizontal: screenWidth * 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // More rounded corners
        ),
        elevation: 8, // Increased elevation for a stronger shadow
        shadowColor: Colors.black26,
      ),
      child: SizedBox(
        width: screenWidth * 0.33,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: icon,
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenHeight * 0.022,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _insertLineBreak(String text, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'vi' && text.contains(' ')) {
      final words = text.split(' ');
      if (words.length > 1) {
        return '${words[0]} ${words[1]}\n${words.sublist(2).join(' ')}';
      }
    } else if (locale == 'en' && text.contains(' ')) {
      final words = text.split(' ');
      if (words.length > 1) {
        return '${words[0]}\n${words.sublist(1).join(' ')}';
      }
    }
    return text;
  }
}
