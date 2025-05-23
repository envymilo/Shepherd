import 'package:flutter/material.dart';

class StatusButton extends StatelessWidget {
  final String label;
  final int count;
  final Color backgroundColor;
  final Color labelColor;
  final Color countBackgroundColor;
  final Color countTextColor;
  final bool isSelected;
  final VoidCallback onTap;

  const StatusButton({super.key, 
    required this.label,
    required this.count,
    required this.backgroundColor,
    required this.labelColor,
    required this.countBackgroundColor,
    required this.countTextColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Change the background color based on selection
    Color currentBackgroundColor = isSelected
        ? backgroundColor.withOpacity(
            0.7) // Change color on select (for example, reduce opacity)
        : backgroundColor;

    return Padding(
      padding: EdgeInsets.only(right: screenWidth * 0.03),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shadowColor: Colors.black,
          elevation: 2,
          backgroundColor: currentBackgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: countBackgroundColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: countTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
