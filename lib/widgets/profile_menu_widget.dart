import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.endIcon = true,
    this.textColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: screenHeight * 0.035,
        height: screenHeight * 0.035,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.grey.shade300.withOpacity(0.2),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
      title: Text(title,
          style: TextStyle(
                  fontSize: screenHeight * 0.0215, fontWeight: FontWeight.bold)
              .apply(color: textColor)),
      trailing: endIcon
          ? Container(
              width: screenHeight * 0.0215,
              height: screenHeight * 0.0215,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                LineAwesomeIcons.angle_right_solid,
                color: Colors.grey[600],
              ),
            )
          : null,
    );
  }
}
