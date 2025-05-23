import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/widgets/profile_menu_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _themeController = ValueNotifier<bool>(false);
  final _systemController = ValueNotifier<bool>(false);
  final LocaleController localeController = Get.find<LocaleController>();

  @override
  Widget build(BuildContext context) {
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    double unitHeightValue = MediaQuery.of(context).size.height * 0.01;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          ProfileMenuWidget(
            icon: Icons.dark_mode,
            iconColor: isDark ? Colors.white : Colors.black,
            onTap: () {
              _showThemeBottomSheet(context);
            },
            title: AppLocalizations.of(context)!.darkMode,
            endIcon: false,
          ),
          ProfileMenuWidget(
            icon: Icons.language,
            iconColor: isDark ? Colors.white : Colors.black,
            onTap: () {
              _showLanguageBottomSheet(context);
            },
            title: AppLocalizations.of(context)!.language,
            endIcon: false,
          ),
        ],
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context) async {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final modalController = Get.find<ModalStateController>();
    modalController.openModal();
    try {
      await showModalBottomSheet(
        context: context,
        builder: (context) => Consumer<UIProvider>(
          builder: (context, UIProvider notifier, child) {
            bool isSystemMode = notifier.themeMode == ThemeMode.system;
            bool isDark = notifier.themeMode == ThemeMode.dark ||
                (isSystemMode &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark);

            _themeController.value = isDark;
            _systemController.value = isSystemMode;
            return Wrap(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    child: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  title: Text(AppLocalizations.of(context)!.darkMode),
                  trailing: AdvancedSwitch(
                    controller: _themeController,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.yellow,
                    activeChild: Text(
                      AppLocalizations.of(context)!.dark,
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                      ),
                    ),
                    inactiveChild: Text(
                      AppLocalizations.of(context)!.light,
                      style: TextStyle(
                          color: Colors.black, fontSize: screenHeight * 0.02),
                    ),
                    initialValue: isDark,
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    activeImage: const AssetImage('assets/images/dark.png'),
                    inactiveImage: const AssetImage('assets/images/light.png'),
                    width: 90.0,
                    height: 40.0,
                    enabled: !isSystemMode, // Disable when system mode is on
                    disabledOpacity: 0.5,
                    thumb: ValueListenableBuilder(
                      valueListenable: _themeController,
                      builder: (_, value, __) {
                        return CircleAvatar(
                          backgroundColor: value
                              ? Colors.blue.shade900
                              : Colors.yellowAccent,
                          child: Icon(
                              value ? Icons.dark_mode : Icons.light_mode,
                              color: value ? Colors.white : Colors.black),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (!isSystemMode) {
                        notifier.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    child: Icon(
                      Icons.settings,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  title: Text(AppLocalizations.of(context)!.systemMode),
                  trailing: AdvancedSwitch(
                    controller: _systemController,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                    activeChild: Text(AppLocalizations.of(context)!.on,
                        style: TextStyle(fontSize: screenHeight * 0.02)),
                    inactiveChild: Text(AppLocalizations.of(context)!.off,
                        style: TextStyle(fontSize: screenHeight * 0.02)),
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    width: 90.0,
                    height: 40.0,
                    initialValue: isSystemMode,
                    thumb: ValueListenableBuilder(
                      valueListenable: _systemController,
                      builder: (_, value, __) {
                        return CircleAvatar(
                          backgroundColor:
                              value ? Colors.blue.shade900 : Colors.grey,
                          child: Icon(value ? Icons.check : Icons.close,
                              color: Colors.white),
                        );
                      },
                    ),
                    onChanged: (value) {
                      setState(() {
                        isSystemMode = value; // Update isSystemMode state
                      });
                      if (value) {
                        // Switch to system mode
                        notifier.setThemeMode(ThemeMode.system);
                        bool isDarkSystem =
                            MediaQuery.of(context).platformBrightness ==
                                Brightness.dark;
                        _themeController.value =
                            isDarkSystem; // Sync theme switch with system
                      } else {
                        // Switch to user-controlled mode
                        notifier.setThemeMode(_themeController.value
                            ? ThemeMode.dark
                            : ThemeMode.light);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      modalController.closeModal();
    }
  }

  void _showLanguageBottomSheet(BuildContext context) async {
    final uiProvider = Provider.of<UIProvider>(context, listen: false);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final modalController = Get.find<ModalStateController>();
    modalController.openModal();
    try {
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    child: Icon(
                      Icons.language,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  trailing: localeController.currentLocale.languageCode == 'en'
                      ? Icon(Icons.done)
                      : null,
                  title: Text(AppLocalizations.of(context)!.english),
                  onTap: () {
                    localeController.changeLanguage('en');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    child: Icon(
                      Icons.language,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  trailing: localeController.currentLocale.languageCode == 'vi'
                      ? Icon(Icons.done)
                      : null,
                  title: Text(AppLocalizations.of(context)!.vietnamese),
                  onTap: () {
                    localeController.changeLanguage('vi');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      );
    } finally {
      modalController.closeModal();
    }
  }
}
