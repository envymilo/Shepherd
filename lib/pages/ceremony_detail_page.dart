import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/models/ceremony.dart';
import 'package:shepherd_mo/models/event.dart';
import 'package:shepherd_mo/widgets/ceremony_detail_background.dart';
import 'package:shepherd_mo/widgets/ceremony_detail_content.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CeremonyDetailsPage extends StatefulWidget {
  final String ceremonyId;
  final Event ceremony;

  const CeremonyDetailsPage({
    super.key,
    required this.ceremonyId,
    required this.ceremony,
  });

  @override
  CeremonyDetailsPageState createState() => CeremonyDetailsPageState();
}

class CeremonyDetailsPageState extends State<CeremonyDetailsPage> {
  Future<Ceremony>? ceremony;
  Future<void>? backgroundLoad;
  bool isLoading = true;
  bool backgroundLoaded = false;

  @override
  void initState() {
    super.initState();
    ceremony = fetchCeremonyDetail(widget.ceremonyId);
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

  Future<Ceremony> fetchCeremonyDetail(String id) async {
    setState(() {
      isLoading = true;
    });
    try {
      final apiService = ApiService();
      return apiService.fetchCeremonyDetail(id: id);
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
          localizations.ceremony,
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
        child: FutureBuilder<Ceremony>(
          future: ceremony,
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
                  return Provider<Ceremony>.value(
                    value: snapshot.data!,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        CeremonyDetailsBackground(ceremony: widget.ceremony),
                        CeremonyDetailsContent(event: widget.ceremony),
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
