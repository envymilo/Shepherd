import 'package:flutter/material.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/models/activity.dart';
import 'package:shepherd_mo/models/ceremony.dart';

class CeremonyGroupExpandableCard extends StatelessWidget {
  const CeremonyGroupExpandableCard({
    super.key,
    required this.group,
    required this.screenHeight,
    required this.isDark,
    required this.screenWidth,
    required this.isUserGroup,
    required this.activity,
  });

  final GroupCeremony group;
  final double screenHeight;
  final bool isDark;
  final double screenWidth;
  final bool isUserGroup;
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final groupName =
        "${group.groupName ?? localizations.noData} ${isUserGroup ? '(${localizations.participating})' : ''}";
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          groupName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: screenHeight * 0.019, fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.group, color: Const.primaryGoldenColor),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenHeight * 0.016,
                  vertical: screenHeight * 0.008),
              child: Text(
                group.component,
                style: TextStyle(
                  fontSize: screenHeight * 0.016,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
