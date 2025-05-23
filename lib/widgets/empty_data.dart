import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmptyData extends StatelessWidget {
  const EmptyData(
      {super.key, required this.message, required this.noDataMessage});

  final String message;
  final String noDataMessage;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.church, // Represents Catholic heritage
            size: screenHeight * 0.07,
            color: Colors.brown.shade600, // A warm, earthy color
          ),
          SizedBox(height: screenHeight * 0.016), // Space between icon and text
          Text(
            noDataMessage,
            style: TextStyle(
              fontSize: screenHeight * 0.016,
              fontWeight: FontWeight.w600,
              color: Colors.brown.shade700,
              fontFamily: 'Serif', // Use a serif font for a classic look
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: screenHeight * 0.008),
          Text(
            message,
            style: TextStyle(
              fontSize: screenHeight * 0.013,
              fontStyle: FontStyle.italic,
              color: Colors.brown.shade400,
              fontFamily: 'Serif',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
