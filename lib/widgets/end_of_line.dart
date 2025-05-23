import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EndOfListWidget extends StatelessWidget {
  const EndOfListWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.church,
              size: screenHeight * 0.07,
              color: Colors.brown.shade200,
            ),
            Text(
              localizations.endOfLine,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
