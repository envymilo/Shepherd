import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/models/event.dart';
import 'package:shepherd_mo/widgets/event_detail_background.dart';
import 'package:shepherd_mo/widgets/event_detail_content.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({super.key, required this.eventId});

  @override
  EventDetailsPageState createState() => EventDetailsPageState();
}

class EventDetailsPageState extends State<EventDetailsPage> {
  Future<Event>? event;
  Future<void>? backgroundLoad;
  bool isLoading = true;
  bool backgroundLoaded = false;

  @override
  void initState() {
    super.initState();
    event = fetchEventDetail(widget.eventId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load the background once
    if (!backgroundLoaded) {
      backgroundLoad = loadBackground();
      backgroundLoaded = true;
    }
  }

  Future<Event> fetchEventDetail(String id) async {
    setState(() {
      isLoading = true;
    });
    try {
      final apiService = ApiService();
      List<Event> events = await apiService.fetchEvents(eventId: id) ?? [];
      return events.first;
    } finally {
      setState(() {
        isLoading = false;
      });
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
          localizations.event,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEEC05C),
      ),
      body: ProgressHUD(
        inAsyncCall: isLoading,
        child: FutureBuilder<Event>(
          future: event,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container();
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  localizations.errorOccurred,
                  style: TextStyle(fontSize: screenHeight * 0.02),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text(
                  localizations.noData,
                  style: TextStyle(fontSize: screenHeight * 0.02),
                ),
              );
            } else {
              // When event data is ready, wait for the background as well
              return FutureBuilder<void>(
                future: backgroundLoad,
                builder: (context, bgSnapshot) {
                  if (bgSnapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  // Both background and event data are ready; display the content
                  return Provider<Event>.value(
                    value: snapshot.data!,
                    child: Stack(
                      fit: StackFit.expand,
                      children: const <Widget>[
                        EventDetailsBackground(),
                        EventDetailsContent(),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
