import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shepherd_mo/models/activity.dart';

class ActivityCard extends StatelessWidget {
  final VoidCallback onTap;
  final Activity activity;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive design
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Localizations for multi-language support
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenHeight * 0.018),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(screenHeight, screenWidth),
              SizedBox(height: screenHeight * 0.01),
              _buildDateRow(localizations, screenWidth, screenHeight),
            ],
          ),
        ),
      ),
    );
  }

  // Row widget to display title and status
  Widget _buildTitleRow(double screenHeight, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            activity.activityName!,
            style: TextStyle(
              fontSize: screenHeight * 0.016,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis, // Adds ellipsis for long titles
          ),
        ),
        SizedBox(width: screenWidth * 0.02), // Spacing between title and status
        Text(
          activity.status!,
          style: TextStyle(
            fontSize: screenHeight * 0.014,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(activity.status!),
          ),
        ),
      ],
    );
  }

  // Row widget to display start and end dates
  Widget _buildDateRow(
      AppLocalizations localizations, double screenWidth, double screenHeight) {
    return Column(
      children: [
        _buildDateInfo(localizations.start, activity.startTime!, screenWidth,
            screenHeight),
        _buildDateInfo(
            localizations.end, activity.endTime!, screenWidth, screenHeight),
      ],
    );
  }

  // Helper widget to display each date info with an icon
  Widget _buildDateInfo(
      String label, DateTime date, double screenWidth, double screenHeight) {
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

    return Row(
      children: [
        const Icon(Icons.date_range),
        SizedBox(width: screenWidth * 0.01),
        Text(
          '$label: $formattedDate',
          style: TextStyle(fontSize: screenHeight * 0.014),
        ),
      ],
    );
  }

  // Determines the color based on the status
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Đang duyệt':
        return Colors.blueGrey.shade200;
      case 'Được thông qua':
        return Colors.green;
      case 'Không được thông qua':
        return Colors.red.shade400;
      case 'Đang diễn ra':
        return Colors.orangeAccent;
      case 'Quá hạn':
        return Colors.red.shade400;
      case 'Chưa bắt đầu':
        return Colors.lightBlueAccent;
      default:
        return Colors.grey.shade300;
    }
  }
}
