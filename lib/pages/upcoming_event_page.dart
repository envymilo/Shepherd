import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:shepherd_mo/models/event.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/widgets/empty_data.dart';
import 'package:shepherd_mo/widgets/event_card.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';

class UpcomingEventPage extends StatefulWidget {
  const UpcomingEventPage({super.key});

  @override
  State<UpcomingEventPage> createState() => _UpcomingEventPageState();
}

class _UpcomingEventPageState extends State<UpcomingEventPage> {
  List<Event>? _events;
  bool isLoading = false;
  String? _error;
  String? selectedOrganization;
  String? selectedGroup;
  int selectedFilter = 1; // Default filter
  Future<List<GroupRole>>? userGroups;
  String userOnly = "false";

  @override
  void initState() {
    super.initState();
    initializeData();
    _fetchEvents(userOnly);
  }

  Future<void> initializeData() async {
    setState(() {
      isLoading = true;
    });
    userGroups = _loadUserGroupInfo();
  }

  Future<List<GroupRole>> _loadUserGroupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userGroups = prefs.getString("loginUserGroups");
    if (userGroups != null) {
      final decodedJson = jsonDecode(userGroups) as List<dynamic>;
      return decodedJson
          .map((item) => GroupRole.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  void _onOrganizationChanged(String? newValue) {
    setState(() {
      selectedGroup = newValue;
      if (newValue == "All") {
        selectedOrganization = null;
        userOnly = "false";
      } else if (newValue == "AllOrg") {
        selectedOrganization = null;
        userOnly = "true";
      } else {
        selectedOrganization = newValue;
        userOnly = "true";
      }
      isLoading = true;
    });
    _fetchEvents(userOnly);
  }

  void _onFilterChanged(int newValue) {
    setState(() {
      selectedFilter = newValue;
      isLoading = true;
    });
    _fetchEvents(userOnly);
  }

  Future<void> _fetchEvents(String userOnly) async {
    setState(() {
      isLoading = true;
    });

    String filterDate = "";
    if (selectedFilter == 1) {
      filterDate = DateTime.now().toString();
    } else if (selectedFilter == 2) {
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      filterDate = nextMonth.toString();
    }

    try {
      ApiService apiService = ApiService();
      final events = await apiService.fetchUpcomingEvents(
        filterDate,
        selectedOrganization ?? "",
        1,
        userOnly,
        "true",
      );
      setState(() {
        _events = events;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      inAsyncCall: isLoading,
      opacity: 0.3,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _buildDropdownRow(context),
            _buildEventList(context),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AppBar(
      centerTitle: true,
      title: Text(
        localizations.upcomingEvents,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.black,
            ),
      ),
      iconTheme: IconThemeData(
        color: Colors.black, // Set leading icon color explicitly
      ),
      backgroundColor: Const.primaryGoldenColor,
    );
  }

  Widget _buildDropdownRow(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: _buildGroupDropdown(context)),
          SizedBox(width: screenWidth * 0.01),
          SizedBox(
              width: screenWidth * 0.305, child: _buildFilterDropdown(context)),
        ],
      ),
    );
  }

  Widget _buildGroupDropdown(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.orangeAccent : Colors.orange.shade600,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FutureBuilder<List<GroupRole>>(
        future: userGroups,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text(localizations.errorOccurred);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text(localizations.noParticipatedGroup);
          } else {
            final userGroups = snapshot.data!;
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true, // Reduce dropdown size
                hint: Text(
                  localizations.all,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                value: selectedGroup,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: [
                  DropdownMenuItem(
                    value: "All",
                    child: Text(
                      localizations.all,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  DropdownMenuItem(
                    value: "AllOrg",
                    child: Text(
                      localizations.allCurrentlyUserOrganizations,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  ...userGroups.map((group) {
                    return DropdownMenuItem(
                      value: group.groupId,
                      child: Text(
                        group.groupName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }),
                ],
                onChanged: _onOrganizationChanged,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.orangeAccent : Colors.orange.shade600,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isDense: true, // Reduce dropdown size
              value: selectedFilter,
              isExpanded: true,
              icon: const Icon(Icons.filter_alt),
              items: [
                DropdownMenuItem(
                    value: 1, child: Text(localizations.thisMonth)),
                DropdownMenuItem(
                    value: 2, child: Text(localizations.nextMonth)),
              ],
              onChanged: (value) => _onFilterChanged(value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventList(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text(_error!)),
      );
    }

    if (_events == null || _events!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: EmptyData(
          noDataMessage: localizations.noEvent,
          message: localizations.takeABreak,
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _events!.length,
        itemBuilder: (context, index) {
          final event = _events![index];
          return EventCard(
            event: event,
            screenHeight: MediaQuery.of(context).size.height,
            screenWidth: MediaQuery.of(context).size.width,
            isDark:
                MediaQuery.of(context).platformBrightness == Brightness.dark,
          );
        },
      ),
    );
  }
}
