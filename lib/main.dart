import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/api/firebase_api.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/firebase_options.dart';
import 'package:shepherd_mo/pages/home_page.dart';
import 'package:shepherd_mo/pages/login_page.dart';
import 'package:shepherd_mo/providers/signalr_provider.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/route/route.dart';
import 'package:shepherd_mo/theme/dark_theme.dart';
import 'package:shepherd_mo/theme/light_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute<void>> routeObserver =
    RouteObserver<PageRoute<void>>();
// Optionally, you can perform any action here on route change

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = Get.put(LocaleController());
  Get.put(AuthorizationController());
  Get.put(RefreshController());
  Get.put(NotificationController());
  Get.put(ModalStateController());
  Get.put(RouteController());
  Get.put(BottomNavController());
  await localeController.loadPreferredLocale();
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  runApp(Shepherd(token: token));
}

class Shepherd extends StatefulWidget {
  final String? token;
  const Shepherd({super.key, required this.token});

  @override
  ShepherdState createState() => ShepherdState();
}

class ShepherdState extends State<Shepherd> {
  late Future<bool> _tokenCheckFuture;

  @override
  void initState() {
    super.initState();
    _tokenCheckFuture = _checkToken();
  }

  Future<bool> _checkToken() async {
    if (widget.token == null) {
      return false;
    }

    final isTokenExpired = JwtDecoder.isExpired(widget.token!);
    if (isTokenExpired) {
      // Handle logout logic here
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        // Global back button handling
        if (Get.currentRoute == '/home') {
          final localizations = AppLocalizations.of(context)!;
          // Show confirmation dialog before exiting the app
          if (didPop) {
            await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(localizations.exitApp),
                  content: Text(localizations.confirmExit),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(localizations.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(localizations.exit),
                    ),
                  ],
                );
              },
            );
          } else {
            Get.back();
          }
        }
        ;
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => UIProvider()..init(),
          ),
          ChangeNotifierProvider(
            create: (context) => SignalRService()..startConnection(),
          ),
        ],
        child: Consumer<UIProvider>(
          builder: (context, UIProvider notifier, child) {
            return GetMaterialApp(
              navigatorObservers: [routeObserver],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('vi', 'VN'),
              ],
              locale: Get.locale,
              fallbackLocale: const Locale('en', 'US'),
              title: 'Shepherd',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: notifier.themeMode,
              home: FutureBuilder<bool>(
                future: _tokenCheckFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !(snapshot.data ?? false)) {
                    return const LoginPage();
                  }

                  return const HomePage();
                },
              ),
              getPages: AppRoutes.routes,
              navigatorKey: navigatorKey,
            );
          },
        ),
      ),
    );
  }
}
