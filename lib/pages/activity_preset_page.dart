import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/models/activity.dart';
import 'package:shepherd_mo/models/ceremony.dart';
import 'package:shepherd_mo/widgets/activity_preset_detail_background.dart';
import 'package:shepherd_mo/widgets/activity_preset_detail_content.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';

class ActivityPresetDetailPage extends StatefulWidget {
  final ActivityPreset activityPreset;
  final Activity activity;
  final List<GroupCeremony> groupCeremonies;

  const ActivityPresetDetailPage({
    super.key,
    required this.activityPreset,
    required this.activity,
    required this.groupCeremonies,
  });

  @override
  _ActivityPresetDetailPageState createState() =>
      _ActivityPresetDetailPageState();
}

class _ActivityPresetDetailPageState extends State<ActivityPresetDetailPage> {
  Future<void>? backgroundLoad;
  bool backgroundLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load the background once
    if (!backgroundLoaded) {
      backgroundLoad = loadBackground();
      backgroundLoaded = true;
    }
  }

  Future<void> loadBackground() async {
    // Load the background asset asynchronously with precacheImage
    await precacheImage(
      AssetImage('assets/images/stained_glass_window.jpg'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.activity,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEEC05C),
      ),
      body: ProgressHUD(
        inAsyncCall: backgroundLoad != null && !backgroundLoaded,
        child: FutureBuilder<void>(
          future: backgroundLoad,
          builder: (context, bgSnapshot) {
            if (bgSnapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            // When background is ready, display the content
            return Provider<ActivityPreset>.value(
              value: widget.activityPreset,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ActivityPresetDetailsBackground(activity: widget.activity),
                  ActivityPresetDetailsContent(
                    activity: widget.activity,
                    groupCeremonies: widget.groupCeremonies,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
