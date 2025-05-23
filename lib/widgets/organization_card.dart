import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OrganizationCard extends StatefulWidget {
  final Color color;
  final String title;
  final int membersCount;
  final VoidCallback onDetailsPressed;

  const OrganizationCard({
    super.key,
    required this.color,
    required this.title,
    required this.membersCount,
    required this.onDetailsPressed,
  });

  @override
  _OrganizationCardState createState() => _OrganizationCardState();
}

class _OrganizationCardState extends State<OrganizationCard> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final localizations = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    final isEnglish = currentLocale.languageCode == 'en';
    final membersText =
        "${localizations.member}${(isEnglish && widget.membersCount > 1) ? 's' : ''}" ??
            localizations.noData;
    final detailsText = localizations.details ?? localizations.noData;

    // Define a fixed minimum height for the title (2 lines)
    final double titleMinHeight =
        screenHeight * 0.07; // Adjust based on your font size

    final titleWidget = Text(
      widget.title,
      style: TextStyle(
        fontSize: screenHeight * 0.024,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
      maxLines: 2, // Allow wrapping to max 2 lines
      softWrap: true, // Allow wrapping
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        width: screenWidth * 0.6,
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use a `ConstrainedBox` to ensure the title takes at least the min height
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: titleMinHeight),
              child: titleWidget,
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              '${widget.membersCount} $membersText',
              style: const TextStyle(color: Colors.black),
            ),
            SizedBox(height: screenHeight * 0.02),
            ElevatedButton(
              onPressed: widget.onDetailsPressed,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(screenWidth * 0.5, screenHeight * 0.06),
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.015),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    detailsText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenHeight * 0.02,
                    ),
                  ),
                  Container(
                    width: screenWidth * 0.07,
                    height: screenWidth * 0.07,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade700,
                    ),
                    child: Icon(
                      Icons.arrow_right_alt_rounded,
                      size: screenWidth * 0.055,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
