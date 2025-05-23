import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/models/ceremony.dart';
import 'package:shepherd_mo/models/event.dart';
import 'package:shepherd_mo/models/group.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/widgets/custom_checkbox.dart';
import 'package:shepherd_mo/widgets/datetime_picker.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/widgets/search_group_dialog.dart';
import 'package:shepherd_mo/widgets/search_ceremony_dialog.dart';

class CreateEditEventPage extends StatefulWidget {
  final Event? event; // If event is provided, the page is for editing

  const CreateEditEventPage({super.key, this.event});

  @override
  _CreateEditEventPageState createState() => _CreateEditEventPageState();
}

class _CreateEditEventPageState extends State<CreateEditEventPage> {
  final _formKey = GlobalKey<FormState>();
  var eventNameController = TextEditingController();
  var descriptionController = TextEditingController();
  var totalCostController = TextEditingController();
  var ceremonyController = TextEditingController();
  var groupController = TextEditingController();
  final FocusNode _eventNameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _ceremonyFocus = FocusNode();
  final FocusNode _groupFocus = FocusNode();
  final FocusNode _totalCostFocus = FocusNode();
  DateTime? fromDate;
  DateTime? toDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  bool isPublic = false;
  late Event event;
  bool isApiCallProcess = false;
  final CurrencyTextInputFormatter formatter =
      CurrencyTextInputFormatter.currency(
    locale: 'vi',
    decimalDigits: 0,
    symbol: ' VND',
  );

  @override
  void initState() {
    super.initState();
    event = Event();
  }

  @override
  void dispose() {
    eventNameController.dispose();
    descriptionController.dispose();
    totalCostController.dispose();
    ceremonyController.dispose();
    groupController.dispose();
    super.dispose();
  }

  void handleCheckboxChanged(bool value) {
    setState(() {
      event.isPublic = value;
    });
  }

  void _unfocus() {
    FocusScope.of(context).unfocus();
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
          widget.event == null
              ? '${localizations.create} ${localizations.event.toLowerCase()}'
              : '${localizations.edit} ${localizations.event.toLowerCase()}',
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
              Text(
                localizations.name,
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
                    focusNode: _eventNameFocus,
                    controller: eventNameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return localizations.required;
                      }
                      return null;
                    },
                    onSaved: (input) {
                      event.eventName = input!.trim();
                    },
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.event,
                      ),
                      border: InputBorder.none,
                      labelText: localizations.name,
                      hintText: localizations.eventNameHint,
                      suffixIcon: eventNameController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                eventNameController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                localizations.dateAndTime,
                style: TextStyle(fontSize: screenHeight * 0.016),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                children: [
                  DatePickerField(
                    label: localizations.startDate,
                    hintText:
                        '${localizations.enter} ${localizations.startDate.toLowerCase()}',
                    onDateSelected: (DateTime? date) {
                      fromDate = date;
                    },
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  TimePickerField(
                    label: localizations.startTime,
                    hintText:
                        '${localizations.enter} ${localizations.startTime.toLowerCase()}',
                    onTimeSelected: (TimeOfDay? time) {
                      fromTime = time;
                    },
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  DatePickerField(
                    label: localizations.endDate,
                    hintText:
                        '${localizations.enter} ${localizations.endDate.toLowerCase()}',
                    onDateSelected: (DateTime? date) {
                      toDate = date;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return localizations.required;
                      }
                      if (fromDate != null) {
                        DateTime endDate = DateTime.parse(value);
                        if (endDate.isBefore(fromDate!)) {
                          return 'End Date cannot be before Start Date!';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  TimePickerField(
                    label: localizations.endTime,
                    hintText:
                        '${localizations.enter} ${localizations.endTime.toLowerCase()}',
                    onTimeSelected: (TimeOfDay? time) {
                      toTime = time;
                    },
                    validator: (value) {
                      return null;
                    },
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
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
                      event.description = input!.trim();
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
              SizedBox(height: screenHeight * 0.01),
              CustomCheckboxField(
                enabledIcon: const Icon(Icons.public),
                disabledIcon: const Icon(Icons.public_off),
                enabledLabel: localizations.public,
                disabledLabel: localizations.private,
                onChanged: handleCheckboxChanged,
              ),
              SizedBox(height: screenHeight * 0.01),
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
                    focusNode: _totalCostFocus,
                    controller: totalCostController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter an amount";
                      } else if (value.startsWith('0')) {
                        return "Amount cannot start with zero";
                      }
                      return null;
                    },
                    inputFormatters: <TextInputFormatter>[formatter],
                    onChanged: (value) {
                      print(formatter.getUnformattedValue()); // 2000.00
                    },
                    onSaved: (input) {
                      event.totalCost = formatter.getUnformattedValue().toInt();
                    },
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.event,
                      ),
                      border: InputBorder.none,
                      labelText: localizations.totalCost,
                      hintText:
                          '${localizations.enter} ${localizations.totalCost.toLowerCase()}',
                      suffixIcon: totalCostController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                totalCostController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
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
                    focusNode: _ceremonyFocus,
                    controller: ceremonyController,
                    onTap: () {
                      showCeremonyDialog(context);
                    },
                    decoration: InputDecoration(
                      icon: const Icon(Icons.event_available),
                      border: InputBorder.none,
                      labelText: localizations.ceremony,
                      hintText:
                          '${localizations.enter} ${localizations.ceremony.toLowerCase()}',
                      // Conditionally add a clear icon at the end
                      suffixIcon: ceremonyController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                ceremonyController
                                    .clear(); // Clear the controller's text
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onTap: () {
                      showGroupDialog(context);
                    },
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.people,
                      ),
                      border: InputBorder.none,
                      labelText: localizations.group,
                      hintText:
                          '${localizations.enter} ${localizations.group.toLowerCase()}',
                      suffixIcon: groupController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                groupController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: () {
                  _unfocus();
                  print(event.toString());
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.orange),
                ),
                child: Text(
                  widget.event == null
                      ? '${localizations.create} ${localizations.event.toLowerCase()}'
                      : '${localizations.edit} ${localizations.event.toLowerCase()}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show the dialog
  void showCeremonyDialog(BuildContext context) async {
    final ceremony = await showDialog<Ceremony>(
      context: context,
      builder: (BuildContext context) {
        return const CeremonyListDialog();
      },
    );

    if (ceremony != null) {
      event.ceremonyId = ceremony.id;
      ceremonyController.text = ceremony.name;
    }
  }

  void showGroupDialog(BuildContext context) async {
    final groups = await showDialog<List<Group>>(
      context: context,
      builder: (BuildContext context) {
        return const GroupListDialog();
      },
    );
  }
}
