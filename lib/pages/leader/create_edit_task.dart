import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/formatter/currency_vnd_formatter.dart';
import 'package:shepherd_mo/formatter/custom_currency_format.dart';
import 'package:shepherd_mo/models/group_member.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/models/task.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/utils/toast.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/widgets/search_member_dialog.dart';

class CreateEditTaskPage extends StatefulWidget {
  final String activityId;
  final String activityName;
  final GroupRole group;
  final Task? task;
  final int totalCost;

  const CreateEditTaskPage({
    super.key,
    required this.activityId,
    required this.activityName,
    required this.group,
    this.task,
    required this.totalCost,
  });

  @override
  _CreateEditTaskPageState createState() => _CreateEditTaskPageState();
}

class _CreateEditTaskPageState extends State<CreateEditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  var titleController = TextEditingController();
  var descriptionController = TextEditingController();
  var costController = TextEditingController();
  var userController = TextEditingController();
  var groupController = TextEditingController();
  var activityController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _groupFocus = FocusNode();
  final FocusNode _costFocus = FocusNode();
  final FocusNode _activityFocus = FocusNode();
  DateTime? fromDate;
  DateTime? toDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  bool isPublic = false;
  late Task task;
  late Task oldTask;
  bool isApiCallProcess = false;
  final CurrencyTextInputFormatter formatter =
      CurrencyTextInputFormatter.currency(
    locale: 'vi',
    decimalDigits: 0,
    symbol: ' VND',
  );
  int totalCost = 0;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  void initializeData() {
    groupController.text = widget.group.groupName;
    activityController.text = widget.activityName;
    titleController.addListener(() {
      setState(() {});
    });

    descriptionController.addListener(() {
      setState(() {}); // Rebuild when description changes
    });

    costController.addListener(() {
      setState(() {}); // Rebuild when cost changes
    });

    userController.addListener(() {
      setState(() {}); // Rebuild when user changes
    });
    if (widget.task != null) {
      // Populate controllers with task data
      task = widget.task!;
      oldTask = Task(
          title: task.title,
          description: task.description,
          cost: task.cost,
          userId: task.userId);
      print(jsonEncode(oldTask));
      titleController.text = task.title ?? '';
      descriptionController.text = task.description ?? '';
      costController.text = task.cost != null
          ? formatter.formatString(task.cost!.toString())
          : '';
      if (task.status != "Bản nháp") {
        userController.text = task.userName ?? '';
      } else {
        oldTask.userId = "00000000-0000-0000-0000-000000000000";
      }
      task.groupId = widget.group.groupId;
      task.activityId = widget.activityId;
      totalCost = widget.totalCost + task.cost!;
    } else {
      // If no task is passed, initialize a new task
      task = Task(
        groupId: widget.group.groupId,
        activityId: widget.activityId,
      );
      totalCost = widget.totalCost;
    }
  }

  void _unfocus() {
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    costController.dispose();
    groupController.dispose();
    activityController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RefreshController refreshController = Get.find();
      refreshController.setShouldRefresh(true);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      inAsyncCall: isApiCallProcess,
      opacity: 0.3,
      child: _uiSetup(context),
    );
  }

  Widget _uiSetup(BuildContext context) {
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task == null
              ? '${localizations.create} ${localizations.task.toLowerCase()}'
              : '${localizations.edit} ${localizations.task.toLowerCase()}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.0),
                  border: isDark
                      ? Border.all(
                          color: Colors.grey
                              .withOpacity(0.3), // Border color in dark mode
                          width: 1, // Border width
                        )
                      : null, // No border in light mode
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.grey
                                .withOpacity(0.2), // Shadow color in light mode
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(-2, 2), // Shadow on left and bottom
                          ),
                        ]
                      : [], // No shadow in dark mode
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: TextFormField(
                    readOnly: true,
                    focusNode: _groupFocus,
                    controller: groupController,
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.people,
                      ),
                      border: InputBorder.none,
                      labelText: localizations.group,
                      filled: true,
                      hintText:
                          '${localizations.enter} ${localizations.group.toLowerCase()}',
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.0),
                  border: isDark
                      ? Border.all(
                          color: Colors.grey
                              .withOpacity(0.3), // Border color in dark mode
                          width: 1, // Border width
                        )
                      : null, // No border in light mode
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.grey
                                .withOpacity(0.2), // Shadow color in light mode
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(-2, 2), // Shadow on left and bottom
                          ),
                        ]
                      : [], // No shadow in dark mode
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: TextFormField(
                    readOnly: true,
                    focusNode: _activityFocus,
                    controller: activityController,
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.wysiwyg,
                      ),
                      border: InputBorder.none,
                      labelText: localizations.activity,
                      hintText:
                          '${localizations.enter} ${localizations.activity.toLowerCase()}',
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                localizations.title,
                style: TextStyle(fontSize: screenHeight * 0.0165),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.005),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.0),
                  border: isDark
                      ? Border.all(
                          color: Colors.grey
                              .withOpacity(0.3), // Border color in dark mode
                          width: 1, // Border width
                        )
                      : null, // No border in light mode
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.grey
                                .withOpacity(0.2), // Shadow color in light mode
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(-2, 2), // Shadow on left and bottom
                          ),
                        ]
                      : [], // No shadow in dark mode
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: TextFormField(
                    focusNode: _titleFocus,
                    controller: titleController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return localizations.required;
                      }
                      return null;
                    },
                    onSaved: (input) {
                      task.title = input!.trim();
                    },
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.event,
                      ),
                      border: InputBorder.none,
                      labelText: localizations.title,
                      hintText:
                          '${localizations.enter} ${localizations.title.toLowerCase()}',
                      suffixIcon: titleController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                titleController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                localizations.description,
                style: const TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.005),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.0),
                  border: isDark
                      ? Border.all(
                          color: Colors.grey
                              .withOpacity(0.3), // Border color in dark mode
                          width: 1, // Border width
                        )
                      : null, // No border in light mode
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.grey
                                .withOpacity(0.2), // Shadow color in light mode
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(-2, 2), // Shadow on left and bottom
                          ),
                        ]
                      : [], // No shadow in dark mode
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: TextFormField(
                    minLines: 4,
                    maxLines: null,
                    focusNode: _descriptionFocus,
                    controller: descriptionController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return localizations.required;
                      }
                      return null;
                    },
                    onSaved: (input) {
                      task.description = input!.trim();
                    },
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.description_outlined,
                      ),
                      border: InputBorder.none,
                      labelText: localizations.description,
                      hintText: localizations.descriptionHint,
                      alignLabelWithHint: false,
                      suffixIcon: descriptionController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                descriptionController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.0),
                  border: isDark
                      ? Border.all(
                          color: Colors.grey
                              .withOpacity(0.3), // Border color in dark mode
                          width: 1, // Border width
                        )
                      : null, // No border in light mode
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.grey
                                .withOpacity(0.2), // Shadow color in light mode
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(-2, 2), // Shadow on left and bottom
                          ),
                        ]
                      : [], // No shadow in dark mode
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    focusNode: _costFocus,
                    controller: costController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.required;
                      }
                      // } else if (value.startsWith('0')) {
                      //   return "Amount cannot start with zero";
                      // }
                      return null;
                    },
                    inputFormatters: [
                      CurrencyVNDFormatter(maxValue: totalCost),
                    ],
                    onSaved: (input) {
                      final numericValue =
                          input?.replaceAll(RegExp(r'[^\d]'), '');
                      task.cost =
                          numericValue != null ? int.parse(numericValue) : 0;
                    },
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.attach_money,
                      ),
                      border: InputBorder.none,
                      labelText: localizations.cost,
                      hintText:
                          '${localizations.enter} ${localizations.totalCost.toLowerCase()}',
                      suffixIcon: costController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                costController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    left: screenWidth * 0.15,
                    top: screenHeight * 0.01,
                    bottom: screenHeight * 0.015),
                child: Row(
                  children: [
                    Text(
                      "${localizations.remainingBudget} ",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      "${formatCurrency(totalCost)} VND",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.0),
                  border: isDark
                      ? Border.all(
                          color: Colors.grey
                              .withOpacity(0.3), // Border color in dark mode
                          width: 1, // Border width
                        )
                      : null, // No border in light mode
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.grey
                                .withOpacity(0.2), // Shadow color in light mode
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(-2, 2), // Shadow on left and bottom
                          ),
                        ]
                      : [], // No shadow in dark mode
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: TextFormField(
                    readOnly: true,
                    focusNode: _userFocus,
                    controller: userController,
                    onTap: () {
                      showUserDialog(context);
                    },
                    decoration: InputDecoration(
                      icon: const Icon(Icons.person),
                      border: InputBorder.none,
                      labelText: localizations.assignMember,
                      hintText: localizations.assignTask,
                      // Conditionally add a clear icon at the end
                      suffixIcon: userController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                task.userId =
                                    "00000000-0000-0000-0000-000000000000";
                                userController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: () async {
                  _unfocus();
                  if (validateAndSave()) {
                    if (widget.task != null) {
                      if (task.userId ==
                              "00000000-0000-0000-0000-000000000000" &&
                          oldTask.userId == null) {
                        task.userId = null;
                      }

                      if (task.title == oldTask.title &&
                          task.description == oldTask.description &&
                          task.cost == oldTask.cost &&
                          task.userId == oldTask.userId) {
                        showToast(localizations.notChange);
                        return;
                      }
                    }
                    setState(() {
                      isApiCallProcess = true;
                    });

                    final apiService = ApiService();
                    bool isSuccess;

                    if (widget.task == null) {
                      // Create a new task
                      final result = await apiService.createTask(task);
                      final success = result.$1;
                      final message = result.$2;
                      if (success) {
                        showToast(
                            '${localizations.create} ${localizations.task.toLowerCase()} ${localizations.success.toLowerCase()}');
                        Get.back(id: 2);
                      } else {
                        if (message != null) {
                          showToast(message);
                        } else {
                          showToast(
                              '${localizations.create} ${localizations.task.toLowerCase()} ${localizations.unsuccess.toLowerCase()}');
                        }
                      }
                    } else {
                      // Edit an existing task
                      task.id =
                          widget.task!.id; // Pass the task ID for updating

                      final result = await apiService.updateTask(task);
                      final success = result.$1;
                      final message = result.$2;
                      if (success) {
                        showToast(
                            '${localizations.edit} ${localizations.task.toLowerCase()} ${localizations.success.toLowerCase()}');
                        Get.back(id: 2);
                      } else {
                        if (message != null) {
                          showToast(message);
                        } else {
                          showToast(
                              '${localizations.edit} ${localizations.task.toLowerCase()} ${localizations.unsuccess.toLowerCase()}');
                        }
                      }
                    }
                    setState(() {
                      isApiCallProcess = false;
                    });
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.orange),
                ),
                child: Text(
                  widget.task == null
                      ? '${localizations.create} ${localizations.task.toLowerCase()}'
                      : '${localizations.edit} ${localizations.task.toLowerCase()}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void showUserDialog(BuildContext context) async {
    final groupMember = await showDialog<GroupMember>(
      context: context,
      builder: (BuildContext context) {
        return GroupMemberListDialog(
          groupId: widget.group.groupId,
        );
      },
    );
    if (groupMember != null) {
      task.userId = groupMember.userID;
      userController.text = groupMember.name;
    }
  }
}
