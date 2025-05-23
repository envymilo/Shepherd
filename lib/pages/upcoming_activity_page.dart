import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/models/activity.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/models/group_user.dart';
import 'package:shepherd_mo/pages/home_page.dart';
import 'package:shepherd_mo/pages/leader/task_management_page.dart';
import 'package:shepherd_mo/pages/task_page.dart';
import 'package:shepherd_mo/widgets/activity_card.dart';
import 'package:shepherd_mo/widgets/empty_data.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';

class UpcomingActivityPage extends StatefulWidget {
  const UpcomingActivityPage({super.key});

  @override
  State<UpcomingActivityPage> createState() => _UpcomingActivityPageState();
}

class _UpcomingActivityPageState extends State<UpcomingActivityPage> {
  List<Activity>? _activities;
  bool isLoading = false;
  String? _error;
  String? selectedOrganization;
  int selectedFilter = 1; // Default filter
  Future<List<GroupRole>>? userGroups;

  @override
  void initState() {
    super.initState();
    initializeData();
    _fetchActivities();
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
      selectedOrganization = newValue == "All" ? null : newValue;
      isLoading = true;
    });
    _fetchActivities();
  }

  void _onFilterChanged(int newValue) {
    setState(() {
      selectedFilter = newValue;
      isLoading = true;
    });
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
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
      final activities = await apiService.fetchUpcomingActivities(
        filterDate,
        selectedOrganization ?? "",
        1,
        "true",
        "true",
      );
      setState(() {
        _activities = activities;
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
        localizations.upcomingActivities,
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
          SizedBox(width: 130, child: _buildFilterDropdown(context)),
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
                  localizations.allCurrentlyUserOrganizations,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                value: selectedOrganization,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: [
                  DropdownMenuItem(
                    value: "All",
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
    final screenHeight = MediaQuery.of(context).size.height;

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
    final screenHeight = MediaQuery.of(context).size.height;

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text(_error!)),
      );
    }

    if (_activities == null || _activities!.isEmpty) {
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
        itemCount: _activities!.length,
        itemBuilder: (context, index) {
          final activity = _activities![index];
          return ActivityCard(
            activity: activity,
            onTap: () async {
              final groupAndUsers = activity.groupAndUsers;

              // Ensure there are groups in the activity
              if (groupAndUsers == null || groupAndUsers.isEmpty) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(localizations.noGroup),
                      content: Text("This activity has no associated groups."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("OK"),
                        ),
                      ],
                    );
                  },
                );
                return; // Exit since there are no groups
              }

              if (selectedOrganization != null) {
                try {
                  // Find the group matching the selected organization
                  final selectedGroup = groupAndUsers.firstWhere(
                    (group) => group.groupID == selectedOrganization,
                  );

                  // Proceed with the found group
                  await _checkRoleAndNavigate(selectedGroup, activity);
                  return; // Exit after successful navigation
                } catch (e) {
                  // Handle the case where no matching group is found
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Error"),
                        content:
                            Text("Selected organization no longer exists."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                  return; // Exit after showing the error
                }
              }

              // Handle multiple groups
              if (groupAndUsers.length > 1) {
                // Show dialog to select a group
                final selectedGroup = await showDialog<GroupAndUser>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        localizations.selectGroup,
                        style: TextStyle(
                          fontSize: screenHeight * 0.018,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: groupAndUsers.length,
                          itemBuilder: (context, index) {
                            final group = groupAndUsers[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                title: Text(
                                  group.groupName ?? localizations.noData,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenHeight * 0.016,
                                  ),
                                ),
                                trailing: Icon(Icons.chevron_right,
                                    color: Colors.grey.shade700),
                                onTap: () {
                                  Navigator.of(context)
                                      .pop(group); // Return selected group
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(null), // No selection
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                          child: Text(
                            localizations.cancel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  },
                );

                if (selectedGroup == null) {
                  // If the user cancels the selection, return
                  return;
                }

                // Proceed with the selected group
                await _checkRoleAndNavigate(selectedGroup, activity);
              } else {
                // Only one group exists, proceed directly
                await _checkRoleAndNavigate(groupAndUsers.first, activity);
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _checkRoleAndNavigate(
      GroupAndUser selectedGroup, Activity activity) async {
    try {
      // Await the userGroups Future to get the actual list
      final userGroupList = await userGroups;

      // Find the user group matching the selected group
      final userGroup = userGroupList!.firstWhere(
        (group) => group.groupId == selectedGroup.groupID,
      );

      // Determine if the user is a leader
      final String leader = dotenv.env['LEADER'] ?? '';
      final String accountant = dotenv.env['GROUPACCOUNTANT'] ?? '';
      final isLeader =
          userGroup.roleName == leader || userGroup.roleName == accountant;

      // Navigate based on the user's role
      final BottomNavController controller = Get.find<BottomNavController>();
      if (controller.selectedIndex.toInt() != 2) controller.changeTabIndex(2);
      Get.to(
        () => ActivitiesTab(
          chosenDate: activity.startTime,
        ),
        id: 2,
        transition: Transition.fade,
      );
      Get.to(
          () => isLeader
              ? TaskManagementPage(
                  activityId: activity.id,
                  activityName: activity.activityName!,
                  group: userGroup,
                )
              : TaskPage(
                  activityId: activity.id,
                  activityName: activity.activityName!,
                  group: userGroup,
                ),
          id: 2,
          transition: Transition.rightToLeftWithFade,
          routeName: isLeader ? "/TaskManagementPage" : "/TaskPage");
    } catch (e) {
      // Handle errors during role checking
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final localizations = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text("Error"),
            content: Text(localizations.somethingWrong),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }
}
