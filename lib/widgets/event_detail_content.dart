import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/formatter/custom_currency_format.dart';
import 'package:shepherd_mo/formatter/status_language.dart';
import 'package:shepherd_mo/models/event.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/widgets/activity_expandable.dart';

class EventDetailsContent extends StatelessWidget {
  const EventDetailsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final event = Provider.of<Event>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final locale = Localizations.localeOf(context).languageCode;
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Event Name with custom text style and shadows for readability
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
                    event.eventName ?? localizations.noData,
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
                // Location row with custom padding
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
                          event.location ?? localizations.noData,
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
                            event.totalCost != null
                                ? "${formatCurrency(event.totalCost!)} VND"
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        getStatus(event.status!, localizations) ??
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
            ],
          ),
          // Date Information (Start and End Dates) with Labels
          Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateInfo(localizations.start, event.fromDate.toString(),
                    screenHeight, locale),
                _buildDateInfo(localizations.end, event.toDate.toString(),
                    screenHeight, locale),
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
                  '${event.description}' ?? localizations.noData,
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
                Icons.wysiwyg,
                size: screenHeight * 0.022,
              ),
              SizedBox(width: screenHeight * 0.005),
              Text(
                "${localizations.activity}:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenHeight * 0.02,
                ),
              ),
            ],
          ),
          event.activities!.isEmpty
              ? Center(
                  child: Text(
                    localizations.noActivity,
                    style: TextStyle(
                      fontSize: screenHeight * 0.02,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                )
              : Flexible(
                  child: ListView.builder(
                    itemCount: event.activities!.length,
                    itemBuilder: (context, index) {
                      final activity = event.activities![index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.0),
                        child: ActivityExpandableCard(
                          activity: activity,
                          screenHeight: screenHeight,
                          isDark: isDark,
                          screenWidth: screenWidth,
                        ),
                      );
                    },
                  ),
                ),
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
                Icons.event,
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
