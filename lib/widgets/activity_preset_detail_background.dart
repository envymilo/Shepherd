import 'package:flutter/material.dart';
import 'package:shepherd_mo/models/activity.dart';

class ActivityPresetDetailsBackground extends StatelessWidget {
  final Activity activity;
  const ActivityPresetDetailsBackground({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get theme mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color gradientStartColor = isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Colors.white.withOpacity(0.4);
    final Color gradientEndColor = isDarkMode
        ? Colors.black.withOpacity(0.0)
        : Colors.black.withOpacity(0.4);

    return Align(
      alignment: Alignment.topCenter,
      child: ClipPath(
        clipper: ImageClipper(),
        child: Stack(
          children: [
            activity.imageURL != null
                ? Image.network(
                    activity.imageURL!,
                    fit: BoxFit.cover,
                    width: screenWidth,
                    height: screenHeight * 0.4,
                    color: isDarkMode
                        ? const Color.fromARGB(133, 42, 41, 41)
                        : const Color.fromARGB(0, 0, 0, 0),
                    colorBlendMode: BlendMode.darken,
                  )
                : Image.asset(
                    'assets/images/stained_glass_window.jpg',
                    fit: BoxFit.cover,
                    width: screenWidth,
                    height: screenHeight * 0.4,
                    color: isDarkMode
                        ? const Color.fromARGB(133, 42, 41, 41)
                        : const Color.fromARGB(0, 0, 0, 0),
                    colorBlendMode: BlendMode.darken,
                  ),
            // Add a radial gradient overlay along the curved edge
            Positioned.fill(
              child: ClipPath(
                clipper: ImageClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment(0.05, -0.1),
                      colors: [
                        gradientStartColor, // Start color for blending
                        gradientEndColor, // Fully transparent at the edges
                      ],
                      stops: [0.3, 1], // Control the gradient spread
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Define starting and ending points
    Offset curveStartingPoint = const Offset(0, 40);
    Offset curveEndPoint = Offset(size.width, size.height * 0.88);

    // Define rounder control points for smoother curve
    path.lineTo(curveStartingPoint.dx, curveStartingPoint.dy);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.8,
      curveEndPoint.dx,
      curveEndPoint.dy,
    );
    path.quadraticBezierTo(
      size.width * 0.95,
      size.height,
      curveEndPoint.dx,
      curveEndPoint.dy,
    );
    path.lineTo(size.width, 0); // Close the path on the right side
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true; // Ensures the clip path updates on rebuild
  }
}
