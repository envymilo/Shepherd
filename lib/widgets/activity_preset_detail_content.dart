import 'dart:convert';

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/formatter/custom_currency_format.dart';
import 'package:shepherd_mo/formatter/status_language.dart';
import 'package:shepherd_mo/models/activity.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/models/ceremony.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/widgets/ceremony_group_expandable.dart';

class ActivityPresetDetailsContent extends StatefulWidget {
  final Activity activity;
  final List<GroupCeremony> groupCeremonies;
  const ActivityPresetDetailsContent({
    super.key,
    required this.activity,
    required this.groupCeremonies,
  });

  @override
  State<ActivityPresetDetailsContent> createState() =>
      _ActivityPresetDetailsContentState();
}

class _ActivityPresetDetailsContentState
    extends State<ActivityPresetDetailsContent> {
  List<GroupRole> userGroupsList = [];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final userGroups = prefs.getString("loginUserGroups");

    if (userGroups != null) {
      final decodedJson = jsonDecode(userGroups) as List<dynamic>;
      setState(() {
        userGroupsList = decodedJson
            .map((item) => GroupRole.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityPreset = Provider.of<ActivityPreset>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final locale = Localizations.localeOf(context).languageCode;
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userJoinedGroups = widget.groupCeremonies.where((group) {
      return userGroupsList
          .any((userGroup) => userGroup.groupId == group.groupID);
    }).toList();

    Widget groupListWidget;
    if (widget.groupCeremonies.isNotEmpty) {
      groupListWidget = ListView.builder(
        itemCount: widget.groupCeremonies.length,
        itemBuilder: (context, index) {
          final group = widget.groupCeremonies[index];
          final isUserGroup = userJoinedGroups
              .any((userGroup) => userGroup.groupID == group.groupID);

          return CeremonyGroupExpandableCard(
            group: group,
            screenHeight: screenHeight,
            isDark: isDark,
            screenWidth: screenWidth,
            isUserGroup: isUserGroup,
            activity: widget.activity,
          );
        },
      );
    } else {
      groupListWidget = Center(
        child: Text(
          localizations.noGroup,
          style: TextStyle(
            fontSize: screenHeight * 0.02,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Activity Name with custom text style and shadows for readability
          SizedBox(
            height: screenHeight * 0.17,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.24,
                    top: screenHeight * 0.05,
                  ),
                  child: Text(
                    widget.activity.activityName ?? localizations.noData,
                    style: TextStyle(
                      fontSize: screenHeight * 0.03,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          offset: Offset(1, 1),
                          color: Colors.black26,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Location custom padding
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.24),
                  child: FittedBox(
                    child: Row(
                      children: <Widget>[
                        Text(
                          "-",
                          style: TextStyle(
                            fontSize: screenHeight * 0.02,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Icon(Icons.star,
                            color: Colors.white, size: screenHeight * 0.02),
                        SizedBox(width: screenHeight * 0.005),
                        Text(
                          widget.activity.location ??
                              localizations.parishChurch,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: screenHeight * 0.02,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.045),
          // Total Cost with Label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.money,
                                size: screenHeight * 0.022,
                              ),
                              SizedBox(width: screenHeight * 0.005),
                              Text(
                                "${localizations.budget}:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenHeight * 0.02,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            activityPreset.totalCost != null
                                ? "${formatCurrency(activityPreset.totalCost!)} VND"
                                : localizations.noData,
                            style: TextStyle(
                              fontSize: screenHeight * 0.017,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    getStatus(widget.activity.status!, localizations) ??
                        localizations.noData,
                    style: TextStyle(
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Date Information (Start and End Dates) with Labels
          Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateInfo(localizations.start,
                    widget.activity.startTime.toString(), screenHeight, locale),
                _buildDateInfo(localizations.end,
                    widget.activity.endTime.toString(), screenHeight, locale),
              ],
            ),
          ),
          // Description with Label
          Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description,
                      size: screenHeight * 0.022,
                    ),
                    SizedBox(width: screenHeight * 0.005),
                    Text(
                      "${localizations.description}:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenHeight * 0.02,
                      ),
                    ),
                  ],
                ),
                ExpandableText(
                  activityPreset.description ?? localizations.noData,
                  expandText: localizations.showMore,
                  collapseText: localizations.showLess,
                  maxLines: 2,
                  animation: true,
                  linkColor: Colors.blueAccent,
                  style: TextStyle(
                    fontSize: screenHeight * 0.016,
                    color: isDark ? Colors.grey.shade300 : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group,
                size: screenHeight * 0.022,
              ),
              SizedBox(width: screenHeight * 0.005),
              Text(
                "${localizations.group}:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenHeight * 0.02,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.005),

          Flexible(child: groupListWidget),
        ],
      ),
    );
  }

  Widget _buildDateInfo(
      String label, String dateTime, double screenHeight, String locale) {
    final date =
        DateFormat('EEEE, dd/MM/yyyy', locale).format(DateTime.parse(dateTime));
    final time = DateFormat('HH:mm', locale).format(DateTime.parse(dateTime));

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.002),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wysiwyg,
                size: screenHeight * 0.022,
              ),
              SizedBox(width: screenHeight * 0.005),
              Text(
                "$label:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenHeight * 0.02,
                ),
              ),
            ],
          ),
          Text(
            '$date | $time',
            style: TextStyle(fontSize: screenHeight * 0.016),
          ),
        ],
      ),
    );
  }
}
